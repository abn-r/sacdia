-- SACDIA Neon DB drift remediation
-- Date: 2026-05-27
-- Scope: reconcile material_orders folio uniqueness after 20260514130000_materials_per_local_field.
--
-- Root cause:
-- - 20260513180000_materiales_init created the legacy global unique constraint
--   as material_orders_folio_key on material_orders(folio_referencia).
-- - 20260514130000_materials_per_local_field intended to replace global folio
--   uniqueness with local-field-scoped uniqueness, but only dropped
--   material_orders_folio_referencia_key, which was not the real constraint name.
--
-- Expected final state:
-- - Keep uq_material_orders_lf_folio_ref on (local_field_id, folio_referencia)
--   WHERE folio_referencia IS NOT NULL.
-- - Drop legacy material_orders_folio_key global uniqueness.
-- - No data deletion.

BEGIN;

SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

DO $$
BEGIN
  IF to_regclass('public.uq_material_orders_lf_folio_ref') IS NULL THEN
    RAISE EXCEPTION 'Cannot drop legacy material_orders_folio_key: scoped unique index uq_material_orders_lf_folio_ref is missing';
  END IF;
END $$;

ALTER TABLE public.material_orders
  DROP CONSTRAINT IF EXISTS material_orders_folio_key;

-- Harmless if the index was already removed by dropping the constraint.
DROP INDEX IF EXISTS public.material_orders_folio_key;

COMMIT;

-- Verification queries to run after COMMIT:
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'public.material_orders'::regclass
--   AND conname IN ('material_orders_folio_key', 'material_orders_folio_referencia_key');
--
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'public'
--   AND tablename = 'material_orders'
--   AND indexname IN ('material_orders_folio_key', 'material_orders_folio_referencia_key', 'uq_material_orders_lf_folio_ref');
