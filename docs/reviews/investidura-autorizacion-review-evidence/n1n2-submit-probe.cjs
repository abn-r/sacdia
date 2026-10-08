// Simulación determinista, sin conexiones DB ni datos reales.
const assert = require('node:assert/strict');
const root = '/Users/abner/Documents/development/sacdia/sacdia-backend';
const { InstitutionalCertificateRequestsService } = require(
  root + '/src/certificate-bulk-imports/institutional-certificate-requests.service.ts',
);

(async () => {
  let birthday = new Date('1990-01-01T00:00:00Z');
  let inside = false;
  let ageReadsInside = 0;
  let ageReadsOutside = 0;
  let events = 0;
  let fileUpdates = 0;
  let locks = 0;
  let saved;
  const year = {
    year_id: 2008,
    start_date: new Date('2008-01-01T00:00:00Z'),
    end_date: new Date('2008-12-31T00:00:00Z'),
    active: false,
  };
  const db = {
    classes: { findUnique: async () => ({
      class_id: 9, asset_code: 'GM-02', name: 'Sintético',
      active: false, minimum_age: 16,
    }) },
    users: { findUnique: async () => {
      if (inside) ageReadsInside++; else ageReadsOutside++;
      return { birthday };
    } },
    ecclesiastical_years: { findMany: async () => [year] },
    certificate_bulk_import_files: {
      findFirst: async () => ({
        file_id: 'file', upload_status: 'CONFIRMED', object_key: 'synthetic',
        batch: { user_id: 'member', batch_id: 'batch' },
      }),
      update: async () => { fileUpdates++; return {}; },
    },
    institutional_certificate_requests: {
      findFirst: async () => null,
      create: async ({ data }) => {
        saved = {
          ...data, request_id: 'request', status: 'PENDING_REVIEW',
          revision: 0, decision_reason: null, reviewed_at: null,
          class: { asset_code: 'GM-02', name: 'Sintético' },
        };
        return saved;
      },
    },
    institutional_certificate_request_events: {
      create: async () => { events++; return {}; },
    },
    $queryRawUnsafe: async () => {
      assert.equal(inside, true, 'Los bloqueos deben usar la transacción');
      locks++;
      return [];
    },
    $transaction: async (callback) => {
      // Otra operación confirma la corrección antes de comenzar esta transacción.
      birthday = new Date('2000-01-01T00:00:00Z');
      inside = true;
      try { return await callback(db); } finally { inside = false; }
    },
  };
  await assert.rejects(
    () => new InstitutionalCertificateRequestsService(db).submit(
      'member', { class_id: 9, file_id: 'file', completed_at: '2008-07-07' },
    ),
    (error) => error.code === 'CERTIFICATE_IMPORT_AGE_BELOW_MINIMUM',
  );
  assert.equal(saved, undefined);
  assert.equal(birthday.getUTCFullYear(), 2000);
  assert.equal(ageReadsInside, 1);
  assert.equal(ageReadsOutside, 0);
  assert.equal(events, 0);
  assert.equal(fileUpdates, 0);
  assert.equal(locks, 3);
  console.log('CORREGIDO N2: nacimiento cambia de edad histórica 18 a 8 antes de entrar, mínimo 16.');
  console.log('Se rechaza con CERTIFICATE_IMPORT_AGE_BELOW_MINIMUM; no hay solicitud, evento ni actualización del archivo.');
  console.log('Lecturas de edad: dentro=1, fuera=0. Tres bloqueos ejecutados dentro de la transacción simulada.');
  console.log('Servicio real con objetos sintéticos; NO es prueba PostgreSQL concurrente.');
})().catch((error) => { console.error(error); process.exit(1); });
