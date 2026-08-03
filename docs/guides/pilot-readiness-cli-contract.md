# Contrato companion — CLI de pilot readiness

**Estado del documento**: ACTIVE — companion de control.
**Estado de implementación**: planificado / stack-local.
**Referencia local revisada**: `7262395e2cee1ac4d19017eb7f6b1dda24b7bea0` (PASS independiente).

> [!WARNING]
> Este documento describe un contrato local aún no integrado ni desplegado. No
> declara el CLI disponible en `development`, CI, staging o producción. El
> commit que respalda este contrato y cualquier PR de esta fase no están
> integrados ni desplegados; la regla **issue-first** bloquea la publicación,
> apertura de PR o promoción de este trabajo.

## Propósito y frontera

El adaptador previsto evalúa **un archivo local** y compone una decisión
read-only. Es un companion de las guías de [deployment](../deployment/DEPLOYMENT-GUIDE.md),
[testing API](../api/TESTING-GUIDE.md) y del dictamen de
[readiness operacional](../audit/PRODUCTION-ONBOARDING-OPERATIONS-READINESS-2026-07-17.md).
No sustituye evidencia de plataforma, una aprobación operativa o la certificación
del piloto.

- Alcance: validación local, determinista y sanitizada de un input con
  `manifest`, `attestation` opcional, `evidence` y `context` (`now`, ambiente y
  release observados).
- Sin red, DB, endpoints, variables de entorno, credenciales, remediación,
  clone, backup/restore, E2E, CI ni mutaciones.
- No debe usarse con PII, secretos, datos de salud, menores, seguros ni URL
  `PILOT_API_BASE_URL`; la salida y los logs no deben exponerlos.
- No ofrece asesoría legal ni declara PASS para C-01/C-02. Esos controles siguen
  siendo evidencia externa y fail-closed.

## Interfaz prevista (no publicada)

La única forma de entrada aceptada será exactamente `--input <archivo>`; una
forma de uso inválida no lee el archivo. El archivo es local: no se descarga,
no se resuelve una URL y no se consulta el runtime. El contenido local es un
input no confiable, aunque tenga JSON válido o simule evidencia.

La salida en `stdout` es **un único** JSON sanitizado con este envelope
allowlisted y sin campos adicionales:

```json
{
  "schemaVersion": "1",
  "mode": "READ_ONLY",
  "verdict": "NO_GO",
  "gates": [],
  "reasons": ["READINESS_CLI_INPUT_INVALID"],
  "exitCode": 2
}
```

El ejemplo es deliberadamente `NO_GO`: no es una prueba de plataforma ni una
autorización. Para una evaluación que alcanza los gates, `gates` contiene
exactamente los requisitos `REQ-PR-001` a `REQ-PR-014`, cada uno reducido a
`requirement`, `status` y, cuando corresponda, `code`; los valores hostiles o
desconocidos se reducen a allowlists seguras. `reasons` también se allowlistea
y no debe transportar el input, rutas, secretos, PII ni excepciones crudas.

| Código de salida | Significado seguro |
|---:|---|
| `0` | `GO` únicamente bajo la condición autoritativa indicada abajo. |
| `2` | `NO_GO`: input/evidencia inválida o incompleta, o gates no satisfactorios. |
| `64` | Uso inválido: distinto de `--input <archivo>`; no se lee el archivo. |
| `70` | Falla inesperada del adaptador; se devuelve una razón allowlisted, no el error original. |

`stderr` debe permanecer vacío en la composición actual; si una futura capa
operativa necesitara diagnóstico, debe ser breve, sanitizado y no parseable como
evidencia. Los consumidores deben decidir por `stdout` + código de salida, no
por texto diagnóstico.

## Autoridad y evaluación fail-closed

El bootstrap local de esta referencia usa resolutores de claves y trust
**deny-all**: no confía en issuer, approver ni clave alguna. Por eso un
JSON local, una atestación sintética, un checksum, una firma falsificada o un
resultado declarado `GO` **no** obtiene autoridad y termina en `NO_GO`/`2`.

Un `GO`/`0` solo puede salir de una composición separada con un evaluador
autoritativo inyectado y con los 14 gates `REQ-PR-001..014` en `PASS`, sin
razones pendientes. La composición local no incluye ese evaluador ni configura
su trust. Una documentación verde, CI verde o manifest estático tampoco cubren
la evidencia runtime, platform, stream integrado o aprobación exigida por
`REQ-PR-014`.

## Límites operativos y de amenaza

| Riesgo | Límite obligatorio |
|---|---|
| Input que se autodeclara confiable | Tratarlo como no confiable; trust y claves siguen deny-all. |
| Exfiltración por salida o error | Emitir solo el envelope/reasons allowlisted; nunca eco de input, rutas, excepciones, secretos o PII. |
| Confusión entre evaluación y operación | Mantener este adaptador separado de cualquier remediación o comando mutante. |
| Confusión entre preparación y piloto | Conservar `NO_GO` hasta evidencia externa fechada, referencia integrada y aprobaciones aplicables. |
| Escalamiento legal o de alcance | C-01/C-02 no se infieren; menores, salud, seguros y datos sensibles permanecen fuera de este CLI. |

Antes de que pueda publicarse, el trabajo debe cumplir issue-first y quedar
integrado en una referencia común; después se revalidan contrato, trust,
evidencia y documentación. Hasta entonces, este companion registra límites, no
un comando operativo disponible.
