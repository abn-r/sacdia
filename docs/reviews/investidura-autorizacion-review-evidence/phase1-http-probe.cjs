// Transporte HTTP local con controlador, servicio, guard de roles y pipes reales.
// JWT, contexto de autorización, Prisma, reloj y traducción son dobles sintéticos.
// No carga AppModule, .env, DB, Redis, correo ni servicios externos.
const assert = require('node:assert/strict');
const path = require('node:path');
const root = '/Users/abner/Documents/development/sacdia/sacdia-backend';
const dep = (name) => require(require.resolve(name, { paths: [root] }));
const src = (name) => require(path.join(root, 'src', name));
const { Test } = dep('@nestjs/testing');
const { UnauthorizedException } = dep('@nestjs/common');
const { I18nContext, I18nValidationPipe, I18nValidationExceptionFilter } = dep('nestjs-i18n');
const { FieldClassThresholdController } = src('classes/field-class-threshold.controller.ts');
const { FieldClassThresholdConfigService } = src('classes/field-class-threshold-config.service.ts');
const { PrismaService } = src('prisma/prisma.service.ts');
const { AuthorizationContextService } = src('common/services/authorization-context.service.ts');
const { LocalFieldTimezoneResolver } = src('common/authorization/local-field-timezone.resolver.ts');
const { GlobalRolesGuard } = src('common/guards/global-roles.guard.ts');
const { JwtAuthGuard } = src('common/guards/jwt-auth.guard.ts');
const { SanitizePipe } = src('common/pipes/sanitize.pipe.ts');
const { CLOCK } = src('common/clock/clock.ts');

let actor;
let now = new Date('2026-06-15T18:00:00Z');
let timeZone = 'America/Mexico_City';
let stored = null;
let reads = 0;
let writes = 0;
let requests = 0;
const setActor = (roles, field = 10) => {
  actor = {
    grants: { global_roles: roles.map(role_name => ({ role_name })), club_assignments: [] },
    effective: { scope: { global: { local_field: { id: field }, union: { id: 2 } } } },
  };
};
const roles = () => actor?.grants.global_roles.map(r => r.role_name) ?? [];
const authorization = {
  resolveUserAuthorization: async () => ({ authorization: actor }),
  isSuperAdmin: async () => roles().includes('super-admin'),
  hasAnyGlobalRole: async (_, accepted) => roles().some(r => accepted.includes(r)),
};
const db = {
  local_fields: { findUnique: async () => { reads++; return { timezone: timeZone }; } },
  ecclesiastical_years: { findUnique: async () => ({
    start_date: new Date('2025-09-01T00:00:00Z'), end_date: new Date('2026-08-31T00:00:00Z'),
  }) },
  local_field_class_thresholds: {
    findUnique: async () => { reads++; return stored; },
    upsert: async ({ create }) => { writes++; stored = { ...create }; return stored; },
  },
};

(async () => {
  const module = await Test.createTestingModule({
    controllers: [FieldClassThresholdController],
    providers: [FieldClassThresholdConfigService, GlobalRolesGuard,
      { provide: PrismaService, useValue: db },
      { provide: CLOCK, useValue: { now: () => now } },
      { provide: LocalFieldTimezoneResolver, useValue: new LocalFieldTimezoneResolver(db) },
      { provide: AuthorizationContextService, useValue: authorization },
    ],
  }).overrideGuard(JwtAuthGuard).useValue({ canActivate(context) {
    if (!actor) throw new UnauthorizedException();
    context.switchToHttp().getRequest().user = { sub: 'synthetic-reviewer' };
    return true;
  } }).compile();
  const app = module.createNestApplication({ logger: false });
  app.setGlobalPrefix('api/v1');
  app.use((req, res, next) => I18nContext.create(
    new I18nContext('es', { translate: (message) => message }), next,
  ));
  app.useGlobalPipes(new SanitizePipe(), new I18nValidationPipe({
    whitelist: true, transform: true, forbidNonWhitelisted: true,
  }));
  app.useGlobalFilters(new I18nValidationExceptionFilter({ detailedErrors: false }));
  try {
    await app.listen(0, '127.0.0.1');
    const base = await app.getUrl();
    const request = async (method, body, field = 10) => {
      requests++;
      const response = await fetch(`${base}/api/v1/local-fields/${field}/class-thresholds/2026`, {
        method, headers: { 'Content-Type': 'application/json' },
        ...(body === undefined ? {} : { body: JSON.stringify(body) }),
      });
      return { status: response.status, body: await response.json() };
    };
    setActor(['director-lf']);
    let response = await request('GET');
    assert.equal(response.status, 200);
    assert.equal(response.body.data.minimum_percent, 80);
    assert.equal(response.body.data.configured, false);
    assert.equal(writes, 0);
    for (const percent of [0, 90, 100]) {
      response = await request('PATCH', { minimum_percent: percent });
      assert.equal(response.status, 200);
      assert.equal(response.body.data.minimum_percent, percent);
      response = await request('GET');
      assert.equal(response.body.data.minimum_percent, percent);
      assert.equal(response.body.data.configured, true);
    }
    for (const role of ['admin', 'director-union', 'assistant-union', 'director-dia', 'assistant-dia', 'director']) {
      setActor([role]);
      const before = reads;
      for (const method of ['GET', 'PATCH']) {
        response = await request(method, method === 'PATCH' ? { minimum_percent: 90 } : undefined);
        assert.equal(response.status, 403, role);
        assert.equal(response.body.code, 'GUARD_PERMISSION_DENIED', role);
      }
      assert.equal(reads, before, 'Sin lectura de datos para rol denegado');
    }
    setActor(['director-lf', 'director-union']);
    const beforeForeign = reads;
    response = await request('PATCH', { minimum_percent: 90 }, 99);
    assert.equal(response.status, 403);
    assert.equal(reads, beforeForeign);
    setActor(['assistant-lf']);
    now = new Date('2026-07-01T05:59:59.999Z');
    assert.equal((await request('PATCH', { minimum_percent: 90 })).status, 200);
    now = new Date('2026-07-01T06:00:00Z');
    response = await request('PATCH', { minimum_percent: 90 });
    assert.equal(response.status, 403);
    assert.equal(response.body.code, 'CLASS_THRESHOLD_EDIT_CLOSED');
    assert.equal((await request('GET')).body.data.can_edit, false);
    setActor(['super-admin']);
    assert.equal((await request('PATCH', { minimum_percent: 90 })).status, 200);
    now = new Date('2026-09-01T06:00:00Z');
    assert.equal((await request('PATCH', { minimum_percent: 90 })).status, 403);
    setActor(['director-lf']);
    timeZone = 'America/New_York';
    now = new Date('2026-07-01T03:59:59.999Z');
    assert.equal((await request('PATCH', { minimum_percent: 90 })).status, 200);
    now = new Date('2026-07-01T04:00:00Z');
    assert.equal((await request('PATCH', { minimum_percent: 90 })).status, 403);
    now = new Date('2026-06-15T18:00:00Z');
    for (const value of [101, -1, 90.5, '90', null]) {
      const before = writes;
      response = await request('PATCH', { minimum_percent: value });
      assert.equal(response.status, 400);
      assert.notEqual(response.body.code, 'CLASS_THRESHOLD_PERCENT_INVALID');
      assert.equal(writes, before);
      console.log('DTO_RESPONSE', JSON.stringify({ input: value, ...response }));
    }
    console.log(`HTTP_PROBE_PASS: ${requests} requests; default sin escritura, GET/PATCH, roles, Campo ajeno, corte en 2 zonas, año y DTO.`);
    console.log('JWT, autorización, DB, reloj y traducción simulados; no es e2e de AppModule ni PostgreSQL.');
  } finally {
    await app.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
