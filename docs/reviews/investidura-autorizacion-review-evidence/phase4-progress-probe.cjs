// Exit 0 confirms defects with real writer methods and a simulated DB, NOT acceptance or PG concurrency.
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.resolve(__dirname, '../../../sacdia-backend');
const { ClassesService } = require(root + '/src/classes/classes.service.ts');
const { EvidenceReviewService } = require(root + '/src/evidence-review/evidence-review.service.ts');
const { assertNoPendingInvestitureAuthorization } = require(root + '/src/investiture-requests/investiture-request-lock.ts');
function deferred() { let resolve; const promise = new Promise(r => { resolve = r; }); return { promise, resolve }; }
(async () => {
  const output = [];
  const resolved = { enrollmentId: 901, ecclesiasticalYearId: 2026, recordKind: 'OPERATIONAL', investitureStatus: 'IN_PROGRESS', lockedForValidation: false };
  let pending = true, checks = 0, writes = 0;
  const progress = { section_progress_id: 1, section_id: 2, enrollment_id: 901, user_id: 'member', score: 100, status: 'PENDING', evidence_files: [{ active: true }] };
  const db = {
    investiture_authorization_people: { findFirst: async () => { checks++; return pending ? { person_id: 'pending-person' } : null; } },
    class_section_progress: {
      findFirst: async () => progress, findUnique: async () => progress,
      findMany: async () => [progress],
      update: async ({ data }) => { writes++; Object.assign(progress, data); return { ...progress }; },
    },
    class_module_progress: { findFirst: async () => ({ module_progress_id: 1 }), update: async () => ({}) },
    validation_logs: { create: async () => ({}) },
    class_sections: { findFirst: async () => ({ section_id: 2 }) },
  };
  db.$transaction = async fn => fn(db);
  const classes = new ClassesService(db, {}, {}, {}, { assertCanAccessProgress: async () => {} }, {}, {});
  // Existing enrollment resolver and annual authorization are seams, outside this writer-boundary probe.
  classes.resolveProgressEnrollment = async () => resolved;
  classes.assertOperationalProgressWrite = async () => {};
  await assert.rejects(assertNoPendingInvestitureAuthorization(db, 901), e => e.code === 'INVESTITURE_REQUEST_PROGRESS_LOCKED');
  checks = 0;
  await classes.submitSection('member', 'director', 7, 2, 901);
  assert.equal(progress.status, 'SUBMITTED'); assert.equal(checks, 0);
  const evidence = Object.create(EvidenceReviewService.prototype); evidence.prisma = db;
  await evidence.rejectClass(1, 'reviewer', 'Debe corregirse');
  assert.equal(progress.status, 'REJECTED'); assert.equal(checks, 0);
  output.push({ case: 'P4-3 writer bypass', pending, statusAfterSubmitAndReject: progress.status, pendingChecks: checks, writes });
  pending = false; checks = 0; writes = 0; progress.status = 'PENDING'; progress.score = 100;
  const paused = deferred(), release = deferred();
  db.class_sections.findFirst = async () => { paused.resolve(); await release.promise; return { section_id: 2 }; };
  const updating = classes.updateSectionProgress('member', 7, 1, 2, 0, {}, 901, 'director');
  await paused.promise;
  pending = true; // Simulates request commit after guard read, before writer transaction.
  release.resolve();
  await updating;
  assert.equal(checks, 1); assert.equal(progress.score, 0); assert.equal(pending, true); assert.equal(writes, 1);
  output.push({ case: 'P4-3 TOCTOU', pendingAtWrite: pending, scoreAfterWrite: progress.score, pendingChecks: checks, writes });
  console.log(JSON.stringify({ reproduced: output, limits: 'DB and request-commit event simulated; real writer methods; not a PostgreSQL concurrency proof.' }, null, 2));
})().catch(e => { console.error(e); process.exitCode = 1; });
