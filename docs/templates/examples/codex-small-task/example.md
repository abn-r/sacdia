# Codex Small Task

## Objetivo

- Corregir el mensaje de error del login admin para distinguir credenciales invalidas de errores de red.

## Alcance

- Ajustar el mapeo de errores en la UI de login admin.
- Mantener el contrato backend vigente.
- Sin cambios de schema ni autenticacion.

## Fuera de alcance

- Rehacer el flujo completo de auth.
- Cambiar copy global fuera del formulario de login.
- Introducir nuevas dependencias.

## Contexto leido

- `AGENTS.md`
- `README.md`
- `docs/README.md`
- `docs/00-STEERING/tech.md`
- `docs/00-STEERING/coding-standards.md`
- `docs/02-API/FRONTEND-INTEGRATION-GUIDE.md`

## Archivos impactados

- `sacdia-admin/src/features/auth/components/LoginForm.tsx`
- `sacdia-admin/src/features/auth/lib/mapAuthError.ts`
- `sacdia-admin/src/features/auth/components/LoginForm.test.tsx`

## Plan corto

1. Revisar como el frontend traduce 401, 429 y errores de red en el login.
2. Ajustar el mapper para mostrar mensajes distintos segun el tipo de error.
3. Cubrir el cambio con test del formulario y verificar que no cambie el contrato con backend.

## Verificacion

- Ejecutar tests del feature auth en admin.
- Probar manualmente un 401 y un fallo de red simulado.

## Docs a sincronizar

- Ninguna, salvo que se detecte desalineacion con `docs/02-API/FRONTEND-INTEGRATION-GUIDE.md`.

## Resultado final

- El usuario ve un mensaje claro cuando las credenciales son invalidas.
- El usuario ve un mensaje diferente cuando el problema es de conectividad o backend.
- El cambio queda cubierto por tests del formulario.
