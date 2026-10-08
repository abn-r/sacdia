// IA-61 / C1RR-2 independent review probe (2026-10-07). No database, no network.
// Run from sacdia-backend/:  node ../docs/reviews/investidura-autorizacion-review-evidence/ia61-scope-and-boundary-probe.cjs
//
// Part 1 (C1RR-2): with active=true and the local day at the edge of end_date, do the
//   certificate side (findEndedSameYearCertificatePeople / guardCertificateApprovalAuthorization)
//   and the pastor side (assertYearOpen) agree on "open" vs "ended" for America/Tijuana and
//   America/Bogota?
// Part 2 (IA-61 scope): what does assertEndedYearCertificateReviewer do for reviewer shapes
//   not covered by the unit tests (admin with another field, assistant-lf other field,
//   director-lf without field, reviewer without certificate role)?
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
const live = require(path.join(root, 'src/certificate-bulk-imports/class-certificate-live-authorization.ts'));
const { InvestitureAuthorizationRequestService } = require(path.join(root, 'src/investiture-requests/investiture-authorization-requests.service.ts'));
const { CertificateBulkImportApplicationService } = require(path.join(root, 'src/certificate-bulk-imports/certificate-bulk-imports-application.service.ts'));

function db(status, timeZone) {
  const updates = [];
  return {
    updates,
    investiture_authorization_people: {
      findMany: async () => [{
        person_id: 'p1', enrollment_id: 40, status,
        request: { ecclesiastical_year_id: 2025, club_section_id: 4 },
        enrollment: { ecclesiastical_year_id: 2025, record_kind: 'OPERATIONAL' },
      }],
      updateMany: async (args) => { updates.push(args.data); return { count: 1 }; },
    },
    enrollments: {
      findMany: async () => [{
        enrollment_id: 40, ecclesiastical_year_id: 2025, investiture_status: 'IN_PROGRESS',
        investiture_date: null, record_kind: 'OPERATIONAL', modified_at: new Date('2025-02-01T00:00:00Z'),
      }],
    },
    ecclesiastical_years: {
      findMany: async () => [{
        year_id: 2025, start_date: new Date('2025-01-01T00:00:00Z'),
        end_date: new Date('2025-12-31T00:00:00Z'), active: true,
      }],
    },
    club_sections: {
      findUnique: async () => ({ clubs: { local_field_id: 7, local_fields: { timezone: timeZone } } }),
    },
  };
}

function pastorSide(timeZone, now) {
  const context = { timeZone, yearActive: true, yearStart: '2025-01-01', yearEnd: '2025-12-31' };
  try {
    InvestitureAuthorizationRequestService.prototype.assertYearOpen.call({}, context, now);
    return 'open';
  } catch (error) {
    return `ended(${error.code ?? error.message})`;
  }
}

async function certificateSide(timeZone, now) {
  const closed = await live.findEndedSameYearCertificatePeople(db('CLOSED_YEAR', timeZone), {
    userId: 'u', classId: 4, certificateYearId: 2025, now,
  });
  const pendingDb = db('PENDING', timeZone);
  let guard;
  try {
    await live.guardCertificateApprovalAuthorization(pendingDb, {
      userId: 'u', classId: 4, certificateYearId: 2025, heldYearIds: new Set([2025]), now,
    });
    guard = `no-throw closes=${JSON.stringify(pendingDb.updates)}`;
  } catch (error) {
    guard = `throws ${error.code ?? error.response?.code ?? error.message}`;
  }
  return { endedSameYear: closed.length > 0 ? 'ended' : 'open', pendingGuard: guard };
}

async function partOne() {
  console.log('== Part 1: C1RR-2 boundary, active=true, end_date=2025-12-31');
  const cases = [
    ['America/Tijuana', '2026-01-01T07:30:00Z', 'Tijuana 23:30 Dec 31 (CDMX already Jan 1 01:30)'],
    ['America/Tijuana', '2026-01-01T08:30:00Z', 'Tijuana 00:30 Jan 1'],
    ['America/Bogota', '2026-01-01T04:30:00Z', 'Bogota 23:30 Dec 31'],
    ['America/Bogota', '2026-01-01T05:30:00Z', 'Bogota 00:30 Jan 1 (CDMX still Dec 31 23:30)'],
  ];
  for (const [zone, iso, label] of cases) {
    const now = new Date(iso);
    const pastor = pastorSide(zone, now);
    const cert = await certificateSide(zone, now);
    const agree = (pastor === 'open') === (cert.endedSameYear === 'open');
    console.log(`${zone} ${iso} [${label}] pastor=${pastor} certificate=${cert.endedSameYear} pendingGuard=${cert.pendingGuard} agree=${agree}`);
  }
}

async function partTwo() {
  console.log('== Part 2: IA-61 reviewer scope gate (request field = 7)');
  const shapes = [
    ['admin', 8], ['assistant-admin', 8], ['admin', 7], ['admin', null],
    ['assistant-lf', 8], ['director-lf', null], ['member-only', null], ['super-admin', 8],
  ];
  for (const [role, field] of shapes) {
    const tx = { users: { findUnique: async () => ({ local_field_id: field, users_roles: [{ roles: { role_name: role } }] }) } };
    let result;
    try {
      await CertificateBulkImportApplicationService.prototype.assertEndedYearCertificateReviewer.call({}, tx, 'r', [7]);
      result = 'allowed';
    } catch (error) {
      result = `rejected ${error.message}`;
    }
    console.log(`role=${role} reviewer.local_field_id=${field} -> ${result}`);
  }
}

partOne().then(partTwo).catch((error) => { console.error(error); process.exitCode = 1; });
