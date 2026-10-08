// BCR review (2026-10-07) probe for BCR-7. No database, no network.
// Run from sacdia-backend/:
//   node ../docs/reviews/investidura-autorizacion-review-evidence/bcr-rev-super-admin-change-dates-shape-probe.cjs
//
// Question: BCR-7 says super-admin gets the authorizer shape (no human rejection reason), which is
// enough to correct dates. readForAuthorizer() was changed. changeDates() (the date-correction
// write super-admin is allowed to call) returns readRequest(tx, requestId) with the default
// 'board' audience. Does its response leak another person's human rejection_reason?
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
const { InvestitureAuthorizationRequestService } = require(
  path.join(root, 'src/investiture-requests/investiture-authorization-requests.service.ts'),
);

const REQUEST = '11111111-1111-4111-8111-111111111111';
const PENDING_PERSON = '22222222-2222-4222-8222-222222222222';
const REJECTED_PERSON = '33333333-3333-4333-8333-333333333333';
const HUMAN_REASON = 'motivo-humano-privado';

(async () => {
  const people = [
    {
      person_id: PENDING_PERSON, user_id: 'u-pending', class_id: 1, enrollment_id: 1,
      investiture_date: new Date('2026-11-01T00:00:00Z'), status: 'PENDING',
    },
    {
      person_id: REJECTED_PERSON, user_id: 'u-rejected', class_id: 1, enrollment_id: 2,
      investiture_date: new Date('2026-11-01T00:00:00Z'), status: 'REJECTED',
      rejection_reason: HUMAN_REASON, resolved_by_id: 'pastor-1',
    },
  ];
  const tx = {
    investiture_authorization_people: {
      findMany: async () => [people[0]],
      updateMany: async () => ({ count: 1 }),
    },
    investiture_authorization_requests: {
      findUnique: async () => ({
        request_id: REQUEST, club_section_id: 5, ecclesiastical_year_id: 1, people,
      }),
    },
    club_sections: { findUnique: async () => ({ club_types: { name: 'Conquistadores' } }) },
  };
  const service = Object.create(InvestitureAuthorizationRequestService.prototype);
  service.prisma = { $transaction: async (fn) => fn(tx) };
  service.requireRequest = async () => ({ request_id: REQUEST, club_section_id: 5, ecclesiastical_year_id: 1 });
  service.loadContext = async () => ({});
  service.assertYearOpen = () => undefined;
  service.assertDateInside = () => undefined;
  service.lockUsers = async () => undefined;
  const superAdmin = { grants: { global_roles: [{ role_name: 'super-admin' }], club_assignments: [] } };
  const view = await service.changeDates(superAdmin, 'sa-1', REQUEST, '2026-11-02', [PENDING_PERSON], new Date('2026-10-15T18:00:00Z'));
  const rejected = view.people.find((p) => p.person_id === REJECTED_PERSON);
  console.log(JSON.stringify({
    isSuperAdmin: service.isSuperAdmin(superAdmin),
    changeDates_response_rejected_person_reason: rejected?.rejection_reason ?? null,
    leaks_human_reason: JSON.stringify(view).includes(HUMAN_REASON),
  }, null, 2));
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
