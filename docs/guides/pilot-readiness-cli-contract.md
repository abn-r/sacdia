# Contrato companion — CLI de pilot readiness

**Estado del documento**: ACTIVE — companion de control.
**Estado de implementación**: planificado / stack-local.
**Artefacto de código de referencia**:
[`sacdia-backend@7262395e2cee1ac4d19017eb7f6b1dda24b7bea0`](https://github.com/abn-r/sacdia-backend/tree/7262395e2cee1ac4d19017eb7f6b1dda24b7bea0/src/pilot-readiness).

> [!NOTE]
> El hash anterior pertenece a **`sacdia-backend`**, no a este repositorio de
> documentación. Es trazabilidad de un artefacto stack-local no integrado, no
> una afirmación de PASS independiente, disponibilidad ni promoción.

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
- No ofrece asesoría legal ni declara PASS para `LEGAL-REVIEW/C-01` ni
  `LEGAL-REVIEW/C-02`. Esos controles siguen siendo evidencia externa y
  fail-closed.

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
`requirement`, `status` y, cuando corresponda, `code`. La definición normativa
de esos requisitos está en [Registro de gates](#registro-de-gates-normativo).
Los valores hostiles o desconocidos se reducen a allowlists seguras. `reasons`
también se allowlistea y no debe transportar el input, rutas, secretos, PII ni
excepciones crudas.

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

## Registro de gates normativo

Este registro define `REQ-PR-001..014` para **este companion planificado**.
La referencia de implementación es el artefacto repo-qualified
[`sacdia-backend@7262395`](https://github.com/abn-r/sacdia-backend/tree/7262395e2cee1ac4d19017eb7f6b1dda24b7bea0/src/pilot-readiness),
en particular `readiness-manifest.validator.ts`, `attestation-evaluator.ts`,
`legal-scope-policy.ts` y `readiness-verifier.ts`. Ninguno de esos enlaces
convierte el contrato en runtime vigente: para runtime prevalece la
[Live Reference](../api/ENDPOINTS-LIVE-REFERENCE.md).

| Gate | Predicado de `PASS` para un evaluador autoritativo | Evidencia mínima enlazada a ambiente y release |
|---|---|---|
| `REQ-PR-001` | El manifest v1 es un artefacto de datos seguro, con estructura y tipos permitidos. | Manifest validado, sin secretos ni valores inseguros. |
| `REQ-PR-002` | El ambiente declarado y ambos origins son identificables; los origins son HTTPS sin credenciales embebidas. | `environment.id`, `tier`, `origins.api` y `origins.admin` del manifest. |
| `REQ-PR-003` | El release es un SHA válido y el manifest identifica la migración esperada y su referencia aplicada. | `release.commit`, `migrations.expected` y `migrations.appliedReference`. |
| `REQ-PR-004` | Cada proveedor requerido está configurado y la lista cerrada de proveedores está completa. | Entradas de `database`, `redis`, `r2`, `fcm`, `resend` y `sentry`, más `evidenceRef` cuando corresponda. |
| `REQ-PR-005` | Existe política de backup con owner, edad máxima positiva y referencia de runbook de restore. | `backupPolicy.owner`, `maxAgeHours` y `restoreRunbookRef`. |
| `REQ-PR-006` | La ventana operacional es RFC3339, tiene inicio anterior al fin y owner identificado. | `operationWindow.startsAt`, `endsAt` y `owner`. |
| `REQ-PR-007` | El alcance declara streams no vacíos y conserva `sensitiveDataAllowed: false`; cualquier extensión de alcance exige re-evaluación. | `pilotScope` y la evidencia del alcance ejecutado. |
| `REQ-PR-008` | La atestación v1 es `READ_ONLY`, tiene forma permitida y contiene resultados de gates con estados permitidos. | Atestación con `attestationId`, tiempos, `gates`, `integrity` y referencias de evidencia. |
| `REQ-PR-009` | La atestación tiene integridad criptográfica `VALID` con clave confiable del evaluador autoritativo; un checksum `UNSIGNED` nunca pasa. | `integrity` y resolución de trust/key fuera del input local. |
| `REQ-PR-010` | El hash del manifest, ambiente declarado/observado y release atestado coinciden con el contexto observado. | `manifestSha256`, environment, release y contexto de evaluación. |
| `REQ-PR-011` | Cada referencia de evidencia exigida existe, es vigente, coincide en ambiente/release y su SHA-256 coincide con el artefacto sanitizado. | `EvidenceReference` y artefacto asociado por gate. |
| `REQ-PR-012` | Se satisface una rama de alcance aprobada: `LEGAL_APPROVED` con ambos controles legales, o `ADULT_NON_SENSITIVE` con exclusiones y aprobaciones técnicas/operacionales verificables. | Evidencia de scope, issuer/approver confiables y referencias a política, documento y runtime. |
| `REQ-PR-013` | La matriz entregada contiene una entrada verificable para cada requisito y ningún requisito faltante o no `PASS`. | Los 14 resultados normalizados y sus `code`/evidencias allowlisted. |
| `REQ-PR-014` | Un evaluador separado y autoritativo emite `GO`, sin razones pendientes, después de que los 13 gates previos y este gate estén en `PASS`. | Decisión del evaluador autoritativo; documentación, CI o manifest estático no bastan. |

`PASS` **no** puede depender solo de campos autodeclarados. En la composición
publicada del artefacto de referencia, los resolutores de trust y claves son
deny-all: por tanto, este companion stack-local permanece `NO_GO` aunque un
input enumere los 14 gates como `PASS`.

### Estados y códigos permitidos

Los únicos estados de gate son `PASS`, `FAIL`, `BLOCKED` y
`NOT_APPLICABLE_WITH_JUSTIFICATION`. `GO` exige que los 14 sean `PASS`; por
tanto, `NOT_APPLICABLE_WITH_JUSTIFICATION` conserva `NO_GO` hasta que el
contrato autoritativo lo reemplace explícitamente.

`reasons` y `gates[].code` no pueden contener texto libre. El conjunto
allowlisted es: `READINESS_CLI_USAGE_INVALID`, `READINESS_CLI_INPUT_INVALID`,
`READINESS_CLI_INTERNAL_ERROR`, `READINESS_MANIFEST_INVALID`,
`READINESS_MANIFEST_SECRET_EXPOSURE`, `READINESS_EVIDENCE_MISSING`,
`READINESS_RUNTIME_MISMATCH`, `READINESS_ATTESTATION_INVALID`,
`READINESS_DEPENDENCY_UNVERIFIED`, `READINESS_OBSERVABILITY_INCOMPLETE`,
`READINESS_RUNBOOK_OR_OWNER_MISSING`, `READINESS_PROVIDER_EVIDENCE_MISSING`,
`READINESS_ARTIFACT_UNSAFE` y `PILOT_GO_EVIDENCE_INCOMPLETE`.

### Controles legales sin colisión de IDs

Para este contrato, los controles del gate `REQ-PR-012` se denominan
**`LEGAL-REVIEW/C-01`** (consentimiento granular de datos sensibles) y
**`LEGAL-REVIEW/C-02`** (verificación de consentimiento parental). Su fuente
es [Auditoría Legal — SACDIA T&C y Aviso de Privacidad](../legal/REVIEW-REPORT.md#hallazgos-por-severidad),
donde ambos siguen siendo críticos y bloquean publicación. Dentro de un
artefacto de evidencia, los valores wire `C-01` y `C-02` solo son admisibles
junto con `branch: LEGAL_APPROVED`; no se interpretan por el ID aislado.

Estos controles **no son** `REALITY-MATRIX/C-01` ni `REALITY-MATRIX/C-02`,
hallazgos técnicos resueltos de folders/evidence-folder en la
[Reality Matrix](../audit/REALITY-MATRIX.md#tabla-de-hallazgos). Esta
separación de namespace evita que un hallazgo técnico resuelto se lea como una
aprobación legal. Mientras la revisión legal los mantenga bloqueantes, el
dictamen operativo permanece `NO_GO`.

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
| Escalamiento legal o de alcance | `LEGAL-REVIEW/C-01` y `LEGAL-REVIEW/C-02` no se infieren; menores, salud, seguros y datos sensibles permanecen fuera de este CLI. |

Antes de que pueda publicarse, el trabajo debe cumplir issue-first y quedar
integrado en una referencia común; después se revalidan contrato, trust,
evidencia y documentación. Hasta entonces, este companion registra límites, no
un comando operativo disponible.
