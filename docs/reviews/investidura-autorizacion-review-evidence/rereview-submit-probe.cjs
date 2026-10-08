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
      update: async () => ({}),
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
    $queryRawUnsafe: async () => [],
    $transaction: async (callback) => {
      // Otra operación confirma la corrección antes de comenzar esta transacción.
      birthday = new Date('2000-01-01T00:00:00Z');
      inside = true;
      try { return await callback(db); } finally { inside = false; }
    },
  };
  const result = await new InstitutionalCertificateRequestsService(db).submit(
    'member', { class_id: 9, file_id: 'file', completed_at: '2008-07-07' },
  );
  assert.equal(result.status, 'PENDING_REVIEW');
  assert.equal(saved.ecclesiastical_year_id, 2008);
  assert.equal(birthday.getUTCFullYear(), 2000);
  assert.equal(ageReadsInside, 0);
  assert.equal(ageReadsOutside, 1);
  assert.equal(events, 1);
  console.log('REPRODUCIDO: submit valida edad histórica 18 fuera de la transacción.');
  console.log('Nacimiento cambia antes de entrar: edad histórica 8, mínimo 16.');
  console.log('Se crea PENDING_REVIEW + evento; lecturas de edad dentro=0, fuera=1.');
  console.log('No demuestra acreditación ni investidura; approve vuelve a validar.');
  console.log('Servicio real con objetos sintéticos; NO es prueba PostgreSQL concurrente.');
})().catch((error) => { console.error(error); process.exit(1); });
