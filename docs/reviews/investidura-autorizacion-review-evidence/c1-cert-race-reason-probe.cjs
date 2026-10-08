// C-1 independent review: prints why both approvals fail in the existing
// certificate-import-postgres "two approvals race" test. Run right after that
// suite on the throwaway loopback cluster (the failed test leaves its rows).
const assert = require('node:assert/strict');
const path = require('node:path');
const { createRequire } = require('node:module');
const root = path.resolve(__dirname, '../../../sacdia-backend');
const req = createRequire(root + '/package.json');
const { PrismaClient } = req('@prisma/client');
const { PrismaPg } = req('@prisma/adapter-pg');
const { Pool } = req('pg');
const { CertificateBulkImportApplicationService } = req(root + '/src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts');
const url = new URL(process.env.SACDIA_TEST_DATABASE_URL || 'invalid:');
assert.equal(url.hostname, '127.0.0.1'); assert.ok(url.pathname.endsWith('_test'));
(async () => {
  const pool = new Pool({ connectionString: url.toString(), max: 6 });
  const db = new PrismaClient({ adapter: new PrismaPg(pool) });
  try {
    const reviewer = await db.users.findFirstOrThrow({ where: { email: 'race-reviewer@certificate-import.test' } });
    const item = await db.certificate_bulk_import_items.findFirstOrThrow({ where: { completed_at: new Date('2004-06-01T00:00:00Z'), status: 'SUBMITTED' }, orderBy: { created_at: 'desc' } });
    const svc = new CertificateBulkImportApplicationService(db);
    const one = await Promise.allSettled([
      svc.approveItem(reviewer.user_id, item.batch_id, item.item_id, {}),
      svc.approveItem(reviewer.user_id, item.batch_id, item.item_id, {}),
    ]);
    console.log('concurrent:', JSON.stringify(one.map((r) => r.status === 'fulfilled' ? 'fulfilled' : String(r.reason?.code ?? '') + ' ' + String(r.reason?.message ?? r.reason).slice(0, 300))));
  } finally { await db.$disconnect(); await pool.end(); }
})().catch((e) => { console.error(e); process.exit(1); });
