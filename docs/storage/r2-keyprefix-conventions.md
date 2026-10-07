# Cloudflare R2 key-prefix conventions

**Estado**: ACTIVE
**Actualizado**: 2026-10-04 (verificado contra `sacdia-backend/src/common/services/r2-file-storage.service.ts` y `.env.example` en `development`)

## Regla general

Cada `StorageBucketAlias` recibe una clave relativa al dominio. La
implementación `R2FileStorageService` agrega exactamente una vez el valor de
`R2_KEY_PREFIX_*` y devuelve la clave completa en `UploadedFileResult.key`.
Los callers no deben anteponer el prefijo configurado.

`R2_PUBLIC_URL_*` es un requisito de configuración de la abstracción existente.
En buckets privados representa la base operativa del endpoint R2, no una ACL ni
una URL pública que pueda persistirse o entregarse al cliente.

## Artefactos PDF de informes mensuales

El alias privado `MONTHLY_REPORTS` usa:

```text
R2_BUCKET_MONTHLY_REPORTS
R2_PUBLIC_URL_MONTHLY_REPORTS
R2_KEY_PREFIX_MONTHLY_REPORTS=monthly-reports
```

La aplicación entrega al servicio de storage la clave relativa:

```text
{year}/{month-padded}/{clubEnrollmentId}/{monthlyReportId}.pdf
```

El objeto efectivo queda en:

```text
monthly-reports/{year}/{month-padded}/{clubEnrollmentId}/{monthlyReportId}.pdf
```

- El bucket no tiene ACL pública.
- La subida usa `Content-Type: application/pdf` y `overwrite: true`.
- Regenerar reemplaza el mismo objeto; no se conservan versiones.
- La base de datos persiste únicamente la clave devuelta por storage y sus
  metadatos de integridad.
- Toda descarga requiere autorización backend y una URL GET firmada temporal;
  nunca se expone una URL permanente.

## Alias de storage

`R2FileStorageService.getBucketConfig()` define 18 alias (`StorageBucketAlias`). Cada uno lee tres variables: `R2_BUCKET_<ALIAS>` (nombre del bucket), `R2_PUBLIC_URL_<ALIAS>` (base de URL) y `R2_KEY_PREFIX_<ALIAS>` (prefijo; opcional). Las credenciales comunes son `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` y `R2_REGION=auto`.

| Alias | Bucket (`.env.example`) | Prefijo (`.env.example` / valor por defecto en código) | Acceso |
|---|---|---|---|
| `USER_PROFILES` | `sacdia-user-profiles` | `user-profiles` | Público |
| `HONORS_IMAGES` | `sacdia-honors` | `honors` | Público |
| `HONORS_PDF` | `sacdia-honors-pdf` | `honors_pdf` | Público |
| `ACHIEVEMENTS_BADGES` | `sacdia-achievements` | `achievements/badges` (defecto igual) | Público |
| `CLASSES_DOCUMENTS` | `sacdia-classes` | `classes` | Público |
| `ACTIVITIES_IMAGES` | `sacdia-activities` | `activities` | Privado |
| `USERS_HONORS` | `sacdia-users-honors` | `users_honors` | Privado |
| `USERS_HONORS_CERT` | `sacdia-users-honors-cert` | `users_honors_cert` | Privado |
| `EVIDENCE_FILES` | `sacdia-evidence` | vacío | Privado |
| `CLASS_EVIDENCE` | comparte `R2_BUCKET_EVIDENCE_FILES` y `R2_PUBLIC_URL_EVIDENCE_FILES` | `R2_KEY_PREFIX_CLASS_EVIDENCE` = `class-evidence` (defecto igual) | Privado |
| `INSURANCE_EVIDENCE` | `sacdia-insurance` | `public-files` | Privado |
| `RESOURCES_FILES` | `sacdia-resources` | `resources` (defecto igual) | Privado |
| `DATA_EXPORTS` | `sacdia-data-exports` | `data-exports` (defecto igual) | Privado |
| `MONTHLY_REPORTS` | `sacdia-monthly-reports` | `monthly-reports` (defecto igual) | Privado |
| `MATERIALES_COMPROBANTES` | `sacdia-materiales-comprobantes` | defecto `materiales/comprobantes` | Privado |
| `CAMPOREE_PAYMENT_VOUCHERS` | `sacdia-camporee-payment-vouchers` | `camporee-payments` (defecto igual) | Privado |
| `CERTIFICATION_EVIDENCE` | `sacdia-certification-evidence` | `certifications/evidence` (defecto igual) | Privado |
| `CERTIFICATE_IMPORTS` | sin valor en `.env.example` | defecto `certificate-imports` | Privado |

Notas:

- Los alias "Público" (`isPublic: true`) devuelven una URL directa construida con `R2_PUBLIC_URL_*`. Los privados solo se entregan como URL GET firmada (`R2_SIGNED_URL_EXPIRES_SECONDS`, 300 s por defecto).
- `CERTIFICATE_IMPORTS` no tiene entrada en `.env.example` (faltan `R2_BUCKET_CERTIFICATE_IMPORTS` y `R2_PUBLIC_URL_CERTIFICATE_IMPORTS`, que `env.validation.ts` sí declara como opcionales). Si el bucket no está configurado, la operación falla cerrada. En `MATERIALES_COMPROBANTES` el prefijo está comentado y se usa el valor por defecto.
- `env.validation.ts` exige al arrancar los alias `HONORS_PDF`, `EVIDENCE_FILES`, `INSURANCE_EVIDENCE`, `DATA_EXPORTS`, `MONTHLY_REPORTS` y `RESOURCES_FILES`; el resto se valida al usarlo (`getRequiredEnv`).
- El paso de `USER_PROFILES` a privado antes de producción está descrito en `docs/runbooks/r2-user-profiles-public-flip.md`; la caché CDN de los buckets públicos, en `docs/plans/2026-09-07-r2-public-cdn-cache.md` (pendiente).

## Base de `R2_PUBLIC_URL_*`

El estado objetivo es que `R2_PUBLIC_URL_*` sea el dominio sin ruta ni `/` final; el servicio añade el prefijo. `buildPublicUrl()` admite también bases que ya incluyen el prefijo como último segmento de ruta (por ejemplo `https://<host>/honors`) y en ese caso no lo duplica. Según `.env.example`, `USER_PROFILES` y `ACHIEVEMENTS_BADGES` ya usan dominio sin ruta; `HONORS_IMAGES`, `HONORS_PDF`, `CLASSES_DOCUMENTS`, `ACTIVITIES_IMAGES`, `USERS_HONORS` y `USERS_HONORS_CERT` todavía incrustan el prefijo.

Para migrar un alias a dominio sin ruta:

1. Cambiar `R2_PUBLIC_URL_<ALIAS>` a la base sin ruta en un entorno.
2. Desplegar y comprobar que las URLs generadas para objetos existentes siguen resolviendo (una imagen antigua y una nueva).
3. Repetir alias por alias; no cambiar `R2_KEY_PREFIX_*` en el mismo paso, porque las claves ya guardadas en la base incluyen el prefijo.
