// Aceptación independiente W1. Servicio real; DB/reloj sintéticos, sin red.
// No reemplaza phase2-default-probe.cjs, que reproduce el defecto histórico.
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.resolve(__dirname, '../../../sacdia-backend');
const { FieldInvestitureWindowConfigService } = require(root + '/src/classes/field-investiture-window-config.service.ts');
const { LocalFieldTimezoneResolver } = require(root + '/src/common/authorization/local-field-timezone.resolver.ts');

(async () => {
  let start = '2026-01-01';
  let end = '2026-06-30';
  let active = true;
  let row = null;
  let writes = 0;
  let now = new Date('2026-02-15T18:00:00Z');
  const utc = day => new Date(day + 'T00:00:00Z');
  const db = {
    local_fields: { findUnique: async () => ({ local_field_id: 10, timezone: 'America/Mexico_City', union_id: 2, unions: { division_id: 1 } }) },
    ecclesiastical_years: { findUnique: async () => ({ start_date: utc(start), end_date: utc(end), active }) },
    local_field_investiture_windows: {
      findUnique: async () => row,
      upsert: async ({ create, update }) => {
        writes++;
        row = { ...(row ? update : create) };
        return row;
      },
    },
  };
  const actor = {
    grants: { global_roles: [{ role_name: 'director-lf' }] },
    effective: { scope: { global: { local_field: { id: 10 } } } },
  };
  const superAdmin = { grants: { global_roles: [{ role_name: 'super-admin' }] }, effective: { scope: { global: {} } } };
  const service = new FieldInvestitureWindowConfigService(db, new LocalFieldTimezoneResolver(db), { now: () => now });
  const empty = await service.get(actor, 10, 2026);
  assert.deepEqual(empty, {
    local_field_id: 10, ecclesiastical_year_id: 2026,
    start_date: null, end_date: null, configured: false, operational: false, can_edit: true,
  });
  assert.equal(await service.allowsOperation(10, 2026), false);
  assert.equal(writes, 0);

  for (const [from, to] of [['2026-08-01', '2026-08-20'], ['2026-02-20', '2026-02-01']]) {
    row = { start_date: utc(from), end_date: utc(to) };
    const invalid = await service.get(actor, 10, 2026);
    assert.equal(invalid.operational, false);
    assert.equal(invalid.configured, false);
    assert.equal(invalid.start_date, null);
    assert.equal(invalid.end_date, null);
    assert.equal(await service.allowsOperation(10, 2026), false);
    assert.equal(writes, 0);
    assert.equal(row.start_date.toISOString().slice(0, 10), from);
  }

  row = null;
  const saved = await service.update(actor, 10, 2026, { start_date: '2026-02-01', end_date: '2026-02-20' }, 'synthetic-user');
  assert.equal(saved.configured, true);
  assert.equal(saved.operational, true);
  assert.equal(writes, 1);
  const boundaries = [
    ['2026-02-01T05:59:59Z', false], ['2026-02-01T06:00:00Z', true],
    ['2026-02-15T18:00:00Z', true], ['2026-02-21T05:59:59Z', true],
    ['2026-02-21T06:00:00Z', false], ['2026-01-15T18:00:00Z', false],
  ];
  for (const [instant, expected] of boundaries) {
    assert.equal(await service.allowsOperation(10, 2026, new Date(instant)), expected, instant);
  }
  active = false;
  assert.equal(await service.allowsOperation(10, 2026), false);
  assert.equal((await service.get(superAdmin, 10, 2026)).can_edit, false);
  await assert.rejects(() => service.update(superAdmin, 10, 2026, { start_date: '2026-02-01', end_date: '2026-02-20' }, 'synthetic-user'));
  active = true;
  now = new Date('2026-07-01T18:00:00Z');
  assert.equal(await service.allowsOperation(10, 2026), false);
  await assert.rejects(() => service.update(superAdmin, 10, 2026, { start_date: '2026-02-01', end_date: '2026-02-20' }, 'synthetic-user'));
  assert.equal(writes, 1);

  row = null;
  now = new Date('2026-02-15T18:00:00Z');
  end = '2026-12-31';
  const normal = await service.get(actor, 10, 2026);
  assert.equal(normal.start_date, '2026-10-01');
  assert.equal(normal.end_date, '2026-12-20');
  assert.equal(normal.operational, true);
  assert.equal(await service.allowsOperation(10, 2026), false);
  start = '2026-11-01';
  assert.equal((await service.get(actor, 10, 2026)).start_date, '2026-11-01');
  start = '2026-01-01';
  end = '2026-11-15';
  assert.equal((await service.get(actor, 10, 2026)).end_date, '2026-11-15');
  assert.equal(writes, 1);
  console.log(JSON.stringify({ result: 'W1 PASS', empty, saved, normal, boundaries, writes, invalidStoredRangesTested: 2, database: 'synthetic', network: false }, null, 2));
})().catch(error => { console.error(error); process.exitCode = 1; });
