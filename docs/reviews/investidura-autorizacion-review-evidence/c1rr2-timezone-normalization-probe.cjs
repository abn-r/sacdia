// Review 31 probe (2026-10-07). No database. Run from sacdia-backend/:
//   node ../docs/reviews/investidura-autorizacion-review-evidence/c1rr2-timezone-normalization-probe.cjs
// Question: both paths call investitureRequestYearEnded, but they normalize local_fields.timezone differently:
//   pastor  (investiture-authorization-requests.service.ts:1543-1545): `timezone || FALLBACK` (no trim)
//   certificate (class-certificate-live-authorization.ts:317-320):      `timezone?.trim() || FALLBACK`
// With a padded stored zone, do they still agree?
const path = require('node:path');
require(path.join(process.cwd(), 'node_modules/ts-node')).register({ transpileOnly: true, skipProject: true, compilerOptions: { module: 'CommonJS', moduleResolution: 'Node', target: 'ES2022', ignoreDeprecations: '6.0' } });
const { investitureRequestYearEnded, INVESTITURE_REQUEST_TIME_ZONE_FALLBACK: F } = require(path.join(process.cwd(), 'src/investiture-requests/ecclesiastical-year-local-day.ts'));
const now = new Date('2026-01-01T07:30:00.000Z');
const out = [];
for (const stored of ['America/Tijuana', 'America/Tijuana ', ' America/Tijuana', '   ']) {
  const run = (zone) => { try { return investitureRequestYearEnded({ active: true, endDate: new Date('2025-12-31T00:00:00.000Z'), now, timeZone: zone }); } catch (e) { return `${e.constructor.name}: ${e.message}`; } };
  out.push({ stored: JSON.stringify(stored), pastor: run(stored || F), certificate: run(stored.trim() || F) });
}
console.log(JSON.stringify(out, null, 2));
