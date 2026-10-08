// Servicio real; persistencia y reloj sintéticos. Sin conexiones DB ni HTTP.
const assert = require('node:assert/strict');
const root = '/Users/abner/Documents/development/sacdia/sacdia-backend';
const { FieldInvestitureWindowConfigService } = require(root + '/src/classes/field-investiture-window-config.service.ts');
const { LocalFieldTimezoneResolver } = require(root + '/src/common/authorization/local-field-timezone.resolver.ts');

(async () => {
  let end = '2026-12-31';
  let writes = 0;
  const db = {
    local_fields: { findUnique: async () => ({ timezone: 'America/Mexico_City' }) },
    ecclesiastical_years: { findUnique: async () => ({
      start_date: new Date('2026-01-01T00:00:00Z'),
      end_date: new Date(end + 'T00:00:00Z'), active: true,
    }) },
    local_field_investiture_windows: {
      findUnique: async () => null,
      upsert: async () => { writes++; throw new Error('Unexpected write'); },
    },
  };
  const actor = {
    grants: { global_roles: [{ role_name: 'super-admin' }] },
    effective: { scope: { global: {} } },
  };
  const service = new FieldInvestitureWindowConfigService(
    db, new LocalFieldTimezoneResolver(db),
    { now: () => new Date('2026-02-15T18:00:00Z') },
  );
  const normal = await service.get(actor, 10, 2026);
  const normalAllows = await service.allowsOperation(10, 2026);
  assert.equal(normal.start_date, '2026-10-01');
  assert.equal(normal.end_date, '2026-12-20');
  assert.equal(normalAllows, false);

  end = '2026-06-30';
  const noIntersection = await service.get(actor, 10, 2026);
  const noIntersectionAllows = await service.allowsOperation(10, 2026);
  assert.equal(noIntersection.start_date, '2026-01-01');
  assert.equal(noIntersection.end_date, '2026-06-30');
  assert.equal(noIntersection.configured, false);
  assert.equal(noIntersectionAllows, true);
  assert.equal(writes, 0);
  console.log(JSON.stringify({ date: '2026-02-15', normal, normalAllows, noIntersection, noIntersectionAllows, writes }, null, 2));
  console.log('W1 REPRODUCIDO: sin intersección ni configuración, el predicado abre febrero. No hay solicitudes ni rutas nuevas conectadas todavía.');
})().catch(error => { console.error(error); process.exitCode = 1; });
