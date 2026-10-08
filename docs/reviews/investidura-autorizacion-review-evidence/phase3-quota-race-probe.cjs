// Reproduce P3-1 con servicio real e intercalación determinista de DB simulada.
// No es concurrencia PostgreSQL: no conecta a DB, HTTP ni servicios externos.
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.resolve(__dirname, '../../../sacdia-backend');
const { DistrictInvestiturePastorService } = require(root + '/src/classes/district-investiture-pastors.service.ts');

function deferred() {
  let resolve;
  const promise = new Promise(r => { resolve = r; });
  return { promise, resolve };
}

const director = {
  grants: { global_roles: [{ role_name: 'director-lf' }] },
  effective: { scope: { global: { local_field: { id: 10 } } } },
};
const rootActor = { grants: { global_roles: [{ role_name: 'super-admin' }] } };

async function scenario(existingQuota, mode) {
  let quota = existingQuota ? { slots: 2 } : null;
  const rows = mode === 'count_then_assign' ? [{ user_id: 'A', districlub_type_id: 5, active: true }] : [];
  const paused = deferred();
  const release = deferred();
  const events = [];
  const matches = where => rows.filter(row => {
    const key = where.districlub_type_id_user_id || where;
    return (key.districlub_type_id === undefined || key.districlub_type_id === row.districlub_type_id)
      && (key.user_id === undefined || key.user_id === row.user_id)
      && (where.active === undefined || where.active === row.active);
  });
  let firstQuotaRead = true;
  const db = {
    districts: { findUnique: async () => ({ local_field_id: 10 }) },
    users: { findUnique: async () => ({ active: true }) },
    users_roles: { findFirst: async () => ({ user_role_id: 'role' }) },
    investiture_pastor_quota: {
      findUnique: async () => {
        const snapshot = quota && { ...quota };
        events.push('quota.read=' + (snapshot?.slots ?? 'default2'));
        if (mode === 'quota_read_then_lower' && firstQuotaRead) {
          firstQuotaRead = false;
          paused.resolve();
          await release.promise;
        }
        return snapshot;
      },
      upsert: async ({ create, update }) => {
        quota = { ...(quota ? update : create) };
        events.push('quota.saved=' + quota.slots);
        return quota;
      },
    },
    district_investiture_pastors: {
      findUnique: async ({ where }) => matches(where)[0] ?? null,
      count: async ({ where }) => matches(where).length,
      create: async ({ data }) => { rows.push({ ...data }); events.push('pastor.created'); return data; },
      groupBy: async () => {
        const count = rows.filter(row => row.active).length;
        const snapshot = count ? [{ districlub_type_id: 5, _count: { user_id: count } }] : [];
        events.push('quota.change.count=' + count);
        if (mode === 'count_then_assign') {
          paused.resolve();
          await release.promise;
        }
        return snapshot;
      },
    },
    $queryRaw: async sql => {
      const text = sql.strings.join('?');
      assert.match(text, /FROM "districts"/);
      events.push('assign.lock=district5');
      return [{ districlub_type_id: 5 }];
    },
  };
  db.$transaction = async fn => fn(db);
  const service = new DistrictInvestiturePastorService(db);
  const targetSlots = mode === 'count_then_assign' ? 1 : 0;
  if (mode === 'count_then_assign') {
    const changing = service.updateQuota(rootActor, targetSlots, 'root');
    await paused.promise;
    await service.assign(director, 5, 'B', 'director');
    release.resolve();
    await changing;
  } else {
    const assigning = service.assign(director, 5, 'B', 'director');
    await paused.promise;
    await service.updateQuota(rootActor, targetSlots, 'root');
    release.resolve();
    await assigning;
  }
  const activeCount = rows.filter(row => row.active).length;
  assert.equal(quota.slots, targetSlots);
  assert.equal(activeCount, targetSlots + 1);
  return { existingQuota, mode, slots: quota.slots, activeCount, bothRequestsSucceeded: true, events };
}

(async () => {
  const results = [];
  for (const existingQuota of [false, true]) {
    for (const mode of ['count_then_assign', 'quota_read_then_lower']) {
      results.push(await scenario(existingQuota, mode));
    }
  }
  console.log(JSON.stringify({ result: 'P3-1 REPRODUCED: activeCount > slots', persistence: 'synthetic', results }, null, 2));
})().catch(error => { console.error(error); process.exitCode = 1; });
