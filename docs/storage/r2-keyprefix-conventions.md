# Cloudflare R2 key-prefix conventions

**Estado**: ACTIVE

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
