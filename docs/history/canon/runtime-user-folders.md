# Runtime Canon — Legacy User Folders

**Estado**: DEPRECATED — retirado antes de producción

`user_folders:read/manage` y las rutas `/folders/*` fueron retiradas del runtime para no mantener dos flujos de carpetas.

El flujo vigente es `annual-folders`:

- Evidencias/secciones: `evidence_folders:read/update`.
- Envío completo: `annual_folders:submit` por `director`, `secretary` o `secretary-treasurer`.
- Evaluación/supervisión: `annual_folders:evaluate` por roles institucionales.

Las filas de permisos legacy quedan inactivas en seeds por compatibilidad de FK/historial. No deben usarse para nuevas rutas, navegación ni decisiones de producto.
