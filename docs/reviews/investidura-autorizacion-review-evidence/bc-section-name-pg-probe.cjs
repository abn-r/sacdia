// BC review (2026-10-07) probe for BC-4 (IA-12). Real PostgreSQL (throwaway cluster), real PrismaClient.
// Run from sacdia-backend/:
//   BC_PROBE_DATABASE_URL=postgresql://postgres@127.0.0.1:55485/<db>_test \
//   node ../docs/reviews/investidura-autorizacion-review-evidence/bc-section-name-pg-probe.cjs
//
// Question: requestLabels() reads the section with `club_sections.findUnique({ where })` and no
// include, then uses `section?.club_types?.name ?? section?.name`. club_sections has no `name`
// column. With real Prisma, is section_name ever non-null?
const path = require('node:path');
const root = process.cwd();
require(path.join(root, 'node_modules/ts-node')).register({
  transpileOnly: true,
  skipProject: true,
  compilerOptions: {
    module: 'CommonJS', moduleResolution: 'Node', target: 'ES2022', jsx: 'react-jsx',
    experimentalDecorators: true, emitDecoratorMetadata: true, esModuleInterop: true,
    ignoreDeprecations: '6.0',
  },
});
require(path.join(root, 'node_modules/reflect-metadata'));
const { PrismaClient } = require(path.join(root, 'node_modules/@prisma/client'));
const { PrismaPg } = require(path.join(root, 'node_modules/@prisma/adapter-pg'));
const pg = require(path.join(root, 'node_modules/pg'));
const { InvestitureAuthorizationRequestService } = require(
  path.join(root, 'src/investiture-requests/investiture-authorization-requests.service.ts'),
);

const url = process.env.BC_PROBE_DATABASE_URL;
if (!url || !/_test(\?|$)/.test(url) || !/127\.0\.0\.1|localhost/.test(url)) {
  console.error('BC_PROBE_DATABASE_URL must be a loopback *_test database');
  process.exit(2);
}

(async () => {
  const pool = new pg.Pool({ connectionString: url });
  const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });
  const type = await prisma.club_types.create({ data: { name: `BC probe ${Date.now()}`, active: true } });
  const section = await prisma.club_sections.create({ data: { club_type_id: type.club_type_id, active: true } });
  const raw = await prisma.club_sections.findUnique({ where: { club_section_id: section.club_section_id } });
  const service = Object.create(InvestitureAuthorizationRequestService.prototype);
  const labels = await service.requestLabels(prisma, { club_section_id: section.club_section_id, people: [] });
  console.log(JSON.stringify({
    club_type_name: type.name,
    findUnique_keys_include_club_types: Object.prototype.hasOwnProperty.call(raw, 'club_types'),
    findUnique_keys_include_name: Object.prototype.hasOwnProperty.call(raw, 'name'),
    requestLabels_sectionName: labels.sectionName,
    expected: type.name,
    RESULT: labels.sectionName === type.name ? 'section_name resolved' : 'section_name is null with real Prisma (BC-4 gap)',
  }, null, 2));
  await prisma.club_sections.delete({ where: { club_section_id: section.club_section_id } });
  await prisma.club_types.delete({ where: { club_type_id: type.club_type_id } });
  await prisma.$disconnect();
  await pool.end();
})().catch((error) => { console.error(error); process.exit(3); });
