import { Firestore } from '@google-cloud/firestore';
import { FirestoreOcrLedger } from '../ledger/firestore-ocr-ledger.ts';
import { createVisionTextReader } from '../vision/vision-text-reader.ts';
import type { ProductionDeps } from './production.ts';

/**
 * Únicas fábricas que construyen clientes reales de Google. Ninguna pasa
 * credenciales: Firestore y Vision resuelven ADC por la service identity.
 * Vision es perezoso: el SDK no se carga hasta la primera lectura.
 */
export const googleDeps: ProductionDeps<Firestore> = {
  createFirestore: (projectId) =>
    new Firestore({ projectId, ignoreUndefinedProperties: true }),
  createLedger: (db) => new FirestoreOcrLedger(db),
  createReader: () => createVisionTextReader(),
};
