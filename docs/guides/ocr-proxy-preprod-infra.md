# Proxy OCR keyless — runbook de infraestructura de preproducción

**Estado**: PROPUESTO. Nada de lo descrito aquí está ejecutado ni desplegado.
**Fecha**: 2026-10-07
**Alcance**: proyecto de desarrollo `sacdia-dev-489217` (organización `511999350388`), región `us-east4`, servicio de Render "API Sacdia" en el entorno Dev.

> Este documento es un procedimiento, no una autorización. Cada paso que escribe en Google Cloud o en Render exige la autorización humana indicada en el paso, por superficie y por sesión. Los pasos marcados como "Lectura" no modifican nada. Contexto de diseño: [diseño](../plans/2026-10-02-vision-keyless-design.md) · [plan](../plans/2026-10-02-vision-keyless-plan.md) · [ADR 11](../api/ARCHITECTURE-DECISIONS.md) · [runbook de uso y rotación](google-vision-certificate-ocr.md).

## Cómo leer los pasos

Cada paso declara dos cosas:

- **Autorización**: `Lectura` (solo consulta), `Humana explícita` (el usuario debe aprobar ese paso en el chat antes de ejecutarlo).
- **Reversible**: `Sí`, `Parcial` (se puede deshacer el efecto de configuración, no el gasto ni los datos ya escritos) o `No`.

Ningún comando de este documento lleva un secreto como argumento. La generación y la lectura del secreto HMAC siempre van por tubería (`|`), de modo que el valor no queda en el historial de la shell, en `ps` ni en la pantalla. No usar `set -x`, `echo "$SECRETO"` ni variables que contengan el secreto.

Variables de trabajo (sustituir al ejecutar; no se guardan en el repositorio):

```sh
PROJECT=sacdia-dev-489217
REGION=us-east4
SERVICE=sacdia-ocr-proxy-preprod
OCR_ENV=preprod                      # entorno lógico del proxy; igual a OCR_PROXY_ENV en Render
KID=k1-2026-10                       # identificador de llave, ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$
SECRET_NAME=ocr-hmac-preprod-k1      # un secreto de Secret Manager por kid
RUNTIME_SA=sacdia-vision-preprod@${PROJECT}.iam.gserviceaccount.com
DEPLOYER_SA=sacdia-ocr-deployer@${PROJECT}.iam.gserviceaccount.com
```

Decisiones que este runbook asume y que el usuario debe confirmar antes de ejecutar: (a) `OCR_ENV=preprod` es el entorno lógico que usará el Render Dev; (b) se reutiliza la cuenta de servicio existente `sacdia-vision-preprod` (sin claves) como identidad de runtime en lugar de crear otra; (c) la base Firestore es `(default)`, porque el proxy actual no recibe un `databaseId`.

## Pendientes de código que bloquean pasos de este runbook

Verificados leyendo `sacdia-ocr-proxy/` y `sacdia-backend/` el 2026-10-07. No se resuelven en este documento.

| # | Hallazgo | Paso afectado |
|---|---|---|
| 1 | `sacdia-ocr-proxy/package.json` no tiene script `start` y `listenOcr` solo escucha en `127.0.0.1`. El entrypoint de producción (`0.0.0.0:$PORT`, variables `OCR_*`) lo implementa otro trabajo en paralelo. | Despliegue (fase 5) |
| 2 | Decisión del usuario (opción a, 2026-10-07): el ledger agrega a **todos** sus documentos (operaciones, nonces y cuota diaria) el campo `expireAt` de tipo `Timestamp` de Firestore, con el mismo instante que su purga lógica. Las fechas `purgeEligibleAt`, `retainUntil` y `logicalExpiresAt` siguen siendo texto ISO y siguen decidiendo la lógica; `expireAt` solo sirve al borrado físico por TTL. El cambio de código lo implementa otro trabajo en paralelo y no está desplegado. | TTL (fase 2.3) |
| 3 | No existe una herramienta de humo que firme solicitudes `POST /v1/ocr` contra una URL real. El firmante del backend (`ocr-proxy-signer.ts`) puede reutilizarse desde un script fuera del repositorio. | Humo (fase 7) |
| 4 | `engines.node` del proxy es `>=24 <25`. La documentación de los buildpacks de Node desaconseja los operadores `>`; confirmar en el log de build que se resolvió Node 24. | Despliegue (fase 5) |
| 5 | `OCR_PROXY_URL` debe ser la URL **completa del endpoint** (`https://<host>/v1/ocr`): el proveedor del backend hace el POST a esa URL tal cual, y la ruta firmada es fija. | Render (fase 6) |
| 6 | Con `NODE_ENV=production`, el backend exige `OCR_MODE` al arrancar. Desplegar este backend en Render sin definir `OCR_MODE` impide que arranque. | Render (fase 6) |
| 7 | El `.env.example` del backend no se pudo leer durante esta redacción (lectura denegada por regla de permisos). Verificar que liste `OCR_MODE`, `OCR_PROXY_URL`, `OCR_PROXY_ENV`, `OCR_PROXY_KID` y `OCR_PROXY_SECRET` (solo nombres, sin valores). | Documentación |

## Fase 0 — Prerrequisitos y verificaciones de solo lectura

**Autorización**: Lectura. **Reversible**: no aplica (no modifica nada).

Verificar quién ejecuta y en qué proyecto, y que no hay claves de cuenta de servicio:

```sh
gcloud config list
gcloud iam service-accounts list --project "$PROJECT"
gcloud iam service-accounts keys list --iam-account "$RUNTIME_SA" --managed-by=user   # debe salir vacío
```

Políticas de la organización (efectivas en el proyecto). Resultados verificados por lectura el 2026-10-07: sin restricción de dominio (DRS), `requireInvokerIam` no impuesta, ubicaciones libres, creación de claves de cuenta de servicio bloqueada. Repetir antes de ejecutar y **siempre repetir en el proyecto de producción**.

```sh
gcloud org-policies describe iam.allowedPolicyMemberDomains --project "$PROJECT" --effective
gcloud org-policies describe run.managed.requireInvokerIam   --project "$PROJECT" --effective
gcloud org-policies describe gcp.resourceLocations           --project "$PROJECT" --effective
gcloud org-policies describe iam.disableServiceAccountKeyCreation --project "$PROJECT" --effective
```

(Si `gcloud` pide el prefijo, usar `constraints/<nombre>`.) Si `run.managed.requireInvokerIam` estuviera impuesta, **detenerse**: la invocación pública sin `allUsers` no sería posible y no se debe resolver con una excepción silenciosa.

Estado actual de APIs, Firestore, Cloud Run y secretos:

```sh
gcloud services list --enabled --project "$PROJECT" \
  --filter="config.name:(run.googleapis.com OR cloudbuild.googleapis.com OR artifactregistry.googleapis.com OR firestore.googleapis.com OR secretmanager.googleapis.com OR vision.googleapis.com)"
gcloud firestore databases list --project "$PROJECT"
gcloud run services list --project "$PROJECT" --region "$REGION"
gcloud secrets list --project "$PROJECT"
gcloud projects get-iam-policy "$PROJECT" --flatten="bindings[].members" \
  --filter="bindings.members:$RUNTIME_SA" --format="table(bindings.role)"
```

Puntos de decisión según lo que se encuentre:

- **Existe una base Firestore `(default)` en otra ubicación**: la ubicación de una base no se puede cambiar (ver fase 2). No se puede reutilizar para `us-east4`. Detener y decidir con el usuario: una base con nombre exige que el proxy acepte un `databaseId` (hoy no lo hace).
- **Existe una base `(default)` en `us-east4`**: reutilizarla; revisar que no contenga datos ajenos (el ledger usa `ocrLedgers/{entorno}/...`).
- **No existe ninguna base**: crearla en la fase 2.

## Fase 1 — Habilitar APIs

**Autorización**: Humana explícita. **Reversible**: Parcial (se pueden deshabilitar, pero habilitarlas puede generar facturación).

```sh
gcloud services enable \
  run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com \
  firestore.googleapis.com secretmanager.googleapis.com \
  --project "$PROJECT"
# vision.googleapis.com ya está habilitada (verificar en la fase 0)
```

Cloud Run necesita Cloud Run Admin y Cloud Build para el despliegue desde fuente; Artifact Registry guarda la imagen en el repositorio `cloud-run-source-deploy` de la región, que Cloud Run crea si falta. [Despliegue desde fuente](https://docs.cloud.google.com/run/docs/deploying-source-code).

## Fase 2 — Firestore Standard en us-east4

### 2.1 Crear la base (solo si la fase 0 no encontró una usable)

**Autorización**: Humana explícita. **Reversible**: **No para la ubicación**.

> **ADVERTENCIA — REGIÓN INMUTABLE.** Una vez creada la base, su ubicación no se puede cambiar. Equivocarse de región obliga a crear otra base y migrar. Confirmar `us-east4` (Northern Virginia, regional) con el usuario antes de ejecutar. Fuente: [ubicaciones de Firestore](https://docs.cloud.google.com/firestore/native/docs/locations).

```sh
gcloud firestore databases create \
  --project "$PROJECT" \
  --database="(default)" \
  --location=us-east4 \
  --edition=standard \
  --type=firestore-native \
  --delete-protection
```

`--delete-protection` evita el borrado accidental de la base mientras tenga ledger. [Referencia del comando](https://docs.cloud.google.com/sdk/gcloud/reference/firestore/databases/create).

### 2.2 Datos y reglas

El proxy accede con la identidad de servicio (IAM), no con reglas de seguridad de cliente. No se crean índices compuestos: las lecturas son por ruta de documento (`ocrLedgers/{entorno}/{operations|nonces|quota}/{id}`). El ledger guarda solo metadata, nunca texto OCR, archivos, nombres, correos, UUID de usuario, URLs ni claves R2.

### 2.3 Política TTL de las colecciones del ledger (decisión: opción a)

**Autorización**: Humana explícita. **Reversible**: Parcial (se puede desactivar la política con `--disable-ttl`; los documentos ya borrados no vuelven).

**Decisión (opción a)**: cada documento del ledger lleva `expireAt`, un campo de tipo `Timestamp` de Firestore con el mismo instante que su purga lógica (umbral de purga de 8 días para operaciones y cuota; `retainUntil` para nonces). La política TTL de Firestore se activa sobre `expireAt` en las tres colecciones. La lógica del proxy **no** lee `expireAt`: sigue usando los campos actuales (`logicalExpiresAt`, `purgeEligibleAt`, `retainUntil`) y `purgeIfEligible`. Se descartó la opción de no usar TTL.

**Cuándo aplicarla**: la política solo puede aplicarse cuando el código del proxy que escribe `expireAt` esté desplegado (fase 5). Ejecutar esta sección **después** de la fase 5 y de confirmar, con el humo de la fase 7 o con una lectura puntual de un documento, que los documentos nuevos tienen `expireAt`. **No hay migración de datos**: nada está desplegado, así que no existen documentos del ledger anteriores al campo. Si algún día hubiera documentos sin `expireAt`, no se borrarían por TTL y habría que tratarlos aparte (hoy no aplica).

**Colecciones reales** (verificadas en `sacdia-ocr-proxy/src/ledger/firestore-ocr-ledger.ts`, ruta `ocrLedgers/{entorno}/{colección}/{id}`): `operations`, `nonces` y `quota`. Una política TTL es por **grupo de colección**, así que cada una de estas tres cubre todos los entornos bajo `ocrLedgers/`. Solo se permite un campo TTL por grupo de colección.

Comandos de política TTL (uno por colección; la base es `(default)`, el valor por defecto de `--database`). Requieren el permiso `datastore.indexes.update`, que no tiene `roles/datastore.user` y sí `roles/datastore.indexAdmin`; la cuenta de runtime **no** lo necesita:

```sh
gcloud firestore fields ttls update expireAt --collection-group=operations --enable-ttl --project "$PROJECT" --async
gcloud firestore fields ttls update expireAt --collection-group=nonces     --enable-ttl --project "$PROJECT" --async
gcloud firestore fields ttls update expireAt --collection-group=quota      --enable-ttl --project "$PROJECT" --async
```

No usar `--expiration-offset`: el desfase es 0 por defecto y `expireAt` ya contiene el instante exacto de purga. `--async` devuelve de inmediato; el avance se consulta con la verificación de abajo. Sintaxis verificada contra la referencia vigente de [`gcloud firestore fields ttls update`](https://docs.cloud.google.com/sdk/gcloud/reference/firestore/fields/ttls/update) el 2026-10-07 (repetir `gcloud firestore fields ttls update --help` antes de ejecutar).

**Verificación de solo lectura (Autorización: Lectura)**. La política queda efectiva cuando su estado es `ACTIVE`. Mientras el estado sea `CREATING`, las escrituras nuevas ya reciben TTL pero los documentos existentes aún se están procesando; `NEEDS_REPAIR` significa que no se pudo habilitar para todos los documentos existentes y exige revisar la operación fallida. Estados definidos en la [referencia REST de `Field`](https://docs.cloud.google.com/firestore/docs/reference/rest/v1/projects.databases.collectionGroups.fields).

```sh
for G in operations nonces quota; do
  gcloud firestore fields ttls list --collection-group="$G" --project "$PROJECT" --format=json
done
gcloud firestore operations list --project "$PROJECT"   # progreso de las operaciones de larga duración
```

En cada salida, el campo `expireAt` debe aparecer con `ttlConfig.state` igual a `ACTIVE`. La página oficial de TTL no define un comando `describe` para estas políticas (la referencia de `gcloud firestore fields ttls` solo ofrece `list` y `update`); por eso la verificación usa `list`. Ver los permisos de lectura (`datastore.indexes.list`, `datastore.indexes.get`) en la [documentación de TTL](https://docs.cloud.google.com/firestore/native/docs/ttl).

**Qué es y qué no es el TTL (leer antes de activarlo)**:

- **No es autenticación ni expiración lógica.** El TTL solo borra documentos físicamente. Ni el replay, ni la idempotencia, ni el vencimiento de la operación o del nonce dependen de él: eso se evalúa en el código (nonce 240 s más 5 min de retención; operación 7 días; elegible para purga a los 8 días). Un documento vencido que todavía no se borró sigue existiendo y sigue contando para la lógica.
- **El borrado físico no es inmediato.** Firestore indica que los datos normalmente se borran dentro de las 24 horas posteriores al vencimiento (cifra de la documentación oficial vigente al 2026-10-07). Hasta entonces los documentos vencidos pueden seguir apareciendo en consultas y lecturas. Una política nueva tarda como mínimo diez minutos en activarse, y los documentos que ya estaban vencidos se borran dentro de las 24 horas posteriores a la activación.
- **Los documentos sin `expireAt` no se borran.** Un campo ausente, `null` o de otro tipo distinto de `Timestamp` deja ese documento fuera del TTL. Por eso el campo debe escribirse en operaciones, nonces y cuota por igual; una colección que lo omita acumula documentos para siempre (la purga lógica `purgeIfEligible` sigue disponible como respaldo manual).
- **El TTL tiene costo.** Las operaciones de borrado por TTL cuentan como borrados de documentos y se facturan como tales. No se estiman precios aquí; consultar la [página oficial de precios de Firestore](https://cloud.google.com/firestore/pricing) para la tarifa de la región elegida. El volumen del ledger es bajo (como máximo 400 páginas por día y entorno).
- **Es reversible solo en la política**: `gcloud firestore fields ttls update expireAt --collection-group=<grupo> --disable-ttl --project "$PROJECT"` detiene los borrados futuros, pero no restaura lo ya borrado. Ojo con el rollback: la sección de rollback prohíbe borrar documentos del ledger a mano; el TTL activo sí los borra al vencer, por lo que ante una investigación abierta conviene desactivar la política antes de que venza lo que se quiere conservar.

## Fase 3 — Cuentas de servicio y permisos mínimos (sin claves)

**Autorización**: Humana explícita. **Reversible**: Sí (los bindings se retiran).

Principios: ninguna clave JSON (la creación de claves está bloqueada por la organización y el diseño no la necesita), ninguna cuenta con Owner/Editor, y el deployer es una identidad distinta de la identidad de runtime. El operador humano no usa un rol amplio permanente: suplanta al deployer.

### 3.1 Identidad de runtime (`$RUNTIME_SA`)

| Rol | Alcance | Para qué |
|---|---|---|
| `roles/datastore.user` | Proyecto | Leer y escribir documentos del ledger. No incluye administrar índices ni TTL. |
| `roles/serviceusage.serviceUsageConsumer` | Proyecto | Permiso `serviceusage.services.use` para facturar las llamadas de Vision al proyecto de cuota (ya otorgado a `sacdia-vision-preprod`; verificar en la fase 0). |
| `roles/secretmanager.secretAccessor` | **Solo el secreto** `$SECRET_NAME` (y el secreto de la llave previa durante una rotación) | Leer la llave HMAC. |

Vision no exige un rol predefinido propio para `DOCUMENT_TEXT_DETECTION` con ADC; el permiso relevante es el de consumo de servicio. Firestore no permite conceder `datastore.user` por colección; el rol queda a nivel de proyecto. IAM admite condiciones por base de datos ([IAM de Firestore](https://docs.cloud.google.com/firestore/native/docs/security/iam)); evaluar si vale la pena cuando el proyecto aloje otros datos Firestore.

```sh
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:$RUNTIME_SA" --role=roles/datastore.user --condition=None
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:$RUNTIME_SA" --role=roles/serviceusage.serviceUsageConsumer --condition=None
# el binding de secretAccessor va por secreto, en la fase 4
```

### 3.2 Deployer (`$DEPLOYER_SA`)

Crear la cuenta y permitir que el operador la suplante (sin claves):

```sh
gcloud iam service-accounts create sacdia-ocr-deployer --project "$PROJECT" \
  --display-name="OCR proxy deployer (sin claves)"
gcloud iam service-accounts add-iam-policy-binding "$DEPLOYER_SA" \
  --member="user:<operador>" --role=roles/iam.serviceAccountTokenCreator
```

Roles del deployer ([despliegue desde fuente](https://docs.cloud.google.com/run/docs/deploying-source-code), [acceso público](https://docs.cloud.google.com/run/docs/authenticating/public)):

| Rol | Alcance | Nota |
|---|---|---|
| `roles/run.sourceDeveloper` | Proyecto | Despliegue desde fuente. |
| `roles/serviceusage.serviceUsageConsumer` | Proyecto | Requerido por el despliegue desde fuente. |
| `roles/iam.serviceAccountUser` | **Sobre `$RUNTIME_SA`** | Permite desplegar el servicio con esa identidad. |
| `roles/run.admin` | Proyecto | Necesario **solo** para `--no-invoker-iam-check` (permisos `run.services.setIamPolicy`, `create`, `update`). No puede acotarse a un servicio que aún no existe. Retirarlo tras el primer despliegue y dejarlo solo para cambios del flag. |

Cuenta de build: por defecto Cloud Build usa la cuenta de Compute Engine por defecto, que necesita `roles/run.builder`. Verificar (fase 0) si ya lo tiene; una política de la organización puede impedir los grants automáticos. No conceder Editor como atajo.

## Fase 4 — Secreto HMAC en Secret Manager

**Autorización**: Humana explícita. **Reversible**: Parcial (una versión se puede deshabilitar; destruirla es irreversible).

Secreto: base64 de al menos 32 bytes aleatorios. El mismo texto es `OCR_SECRET_CURRENT` en el proxy y `OCR_PROXY_SECRET` en Render. `tr -d '\n'` evita un salto de línea final que podría hacer difieran los dos lados.

```sh
openssl rand -base64 32 | tr -d '\n' | gcloud secrets create "$SECRET_NAME" \
  --project "$PROJECT" --replication-policy=user-managed --locations="$REGION" \
  --data-file=-

gcloud secrets add-iam-policy-binding "$SECRET_NAME" --project "$PROJECT" \
  --member="serviceAccount:$RUNTIME_SA" --role=roles/secretmanager.secretAccessor
```

El valor nace y se guarda por tubería: no pasa por el historial ni por la pantalla. Confirmar solo metadata (`gcloud secrets versions list "$SECRET_NAME"`), nunca el contenido. [`secrets create`](https://docs.cloud.google.com/sdk/gcloud/reference/secrets/create) · [`add-iam-policy-binding`](https://docs.cloud.google.com/sdk/gcloud/reference/secrets/add-iam-policy-binding).

Un secreto distinto por entorno (`preprod`, y después producción en su propio proyecto): nunca compartir una llave entre entornos.

## Fase 5 — Desplegar el proxy en Cloud Run

**Autorización**: Humana explícita (construye una imagen, crea el servicio y lo expone en Internet). **Reversible**: Sí (volver a la revisión anterior o cerrar el acceso; ver rollback).

Prerrequisito: el entrypoint de producción del proxy (pendiente 1) está aprobado en local y el árbol `sacdia-ocr-proxy/` es el que se quiere desplegar. El arranque es el script `start` de `package.json`. Si hay un `Dockerfile` en el directorio, Cloud Run lo usa; si no, usa buildpacks de Node.js (instala solo dependencias de producción y ejecuta `scripts.start`).

Perfil aprobado: 1 vCPU, 512 MiB, instancias mínimas 0, máximas 1, concurrencia 1. Cadena de plazos: Vision 25 s < proxy 35 s < Cloud Run 40 s y cliente de Render 40 s. El proxy responde por sí mismo a los 35 s; el plazo de Cloud Run es un respaldo. Un 504 de plataforma no cancela el trabajo ya iniciado ([timeout](https://docs.cloud.google.com/run/docs/configuring/request-timeout)), por eso el ledger decide, no el plazo.

```sh
gcloud run deploy "$SERVICE" \
  --source sacdia-ocr-proxy \
  --project "$PROJECT" --region "$REGION" \
  --impersonate-service-account="$DEPLOYER_SA" \
  --service-account="$RUNTIME_SA" \
  --no-invoker-iam-check \
  --cpu=1 --memory=512Mi \
  --min-instances=0 --max-instances=1 --concurrency=1 \
  --timeout=40 \
  --update-env-vars="OCR_ENV=$OCR_ENV,OCR_KID_CURRENT=$KID,GOOGLE_CLOUD_PROJECT=$PROJECT,OCR_MAX_PAGES_PER_ENV_PER_DAY=400,OCR_SHUTDOWN_GRACE_MS=8000" \
  --update-secrets="OCR_SECRET_CURRENT=${SECRET_NAME}:1"
```

Notas sobre cada decisión:

- **Invocación pública sin `allUsers`**: `--no-invoker-iam-check` (anotación `run.googleapis.com/invoker-iam-disabled: 'true'`) desactiva la comprobación de IAM de invocador. Es el método que la documentación oficial indica cuando el proyecto está sujeto a la restricción de dominios compartidos, y no crea un binding `allUsers`. La única barrera de aplicación pasa a ser la firma HMAC. Se puede reactivar con `gcloud run services update "$SERVICE" --invoker-iam-check`. Fuente: [acceso público a Cloud Run](https://docs.cloud.google.com/run/docs/authenticating/public) y [`gcloud run deploy`](https://docs.cloud.google.com/sdk/gcloud/reference/run/deploy). Verificar la vigencia del flag con `gcloud run deploy --help` antes de ejecutar.
- **`PORT`** lo inyecta Cloud Run; no se define a mano. El servicio debe escuchar en `0.0.0.0:$PORT` ([contrato del contenedor](https://docs.cloud.google.com/run/docs/container-contract)).
- **`OCR_SHUTDOWN_GRACE_MS=8000`**: Cloud Run envía `SIGTERM` y espera 10 s antes de `SIGKILL`; el valor debe ser menor que 10 000.
- **Secreto**: se fija a la **versión 1**, no a `latest`, como recomienda Google. Se resuelve al arrancar la instancia; si no puede leerse, la instancia no arranca. [Secretos en Cloud Run](https://docs.cloud.google.com/run/docs/configuring/services/secrets).
- **`--update-env-vars` y `--update-secrets`** conservan lo ya configurado; `--set-*` lo reemplaza todo.
- No definir `OCR_KID_PREVIOUS` ni `OCR_SECRET_PREVIOUS` hasta una rotación.

Obtener la URL del servicio (Lectura):

```sh
gcloud run services describe "$SERVICE" --project "$PROJECT" --region "$REGION" --format='value(status.url)'
```

Revisar el log de build: debe resolverse Node 24. Si el servicio no pasa el chequeo de arranque, Cloud Run da hasta 4 minutos antes de fallar.

## Fase 6 — Configurar Render (servicio "API Sacdia", entorno Dev)

**Autorización**: Humana explícita. **Reversible**: Sí (volver a `OCR_MODE=direct`, ver rollback). Guardar variables en Render puede disparar un despliegue.

Orden: primero Cloud Run (fase 5), después Render. Variables a definir en el panel de Render (solo nombres; el secreto no se escribe en ningún archivo ni se imprime):

| Variable | Valor |
|---|---|
| `OCR_MODE` | `remote` |
| `OCR_PROXY_URL` | `<status.url>/v1/ocr` (https, ruta completa) |
| `OCR_PROXY_ENV` | el mismo valor que `OCR_ENV` (`preprod`) |
| `OCR_PROXY_KID` | el mismo valor que `OCR_KID_CURRENT` |
| `OCR_PROXY_SECRET` | el mismo valor que el secreto de Secret Manager (marcar como secreto) |

Pasar el secreto sin que aparezca en pantalla ni en el historial: leerlo al portapapeles por tubería, pegarlo en el campo del panel y vaciar el portapapeles.

```sh
gcloud secrets versions access 1 --secret="$SECRET_NAME" --project "$PROJECT" | pbcopy
# pegar en Render > API Sacdia > Environment > OCR_PROXY_SECRET
pbcopy < /dev/null
```

Si el operador no tiene `secretmanager.versions.access` sobre ese secreto, conceder el rol temporalmente sobre ese solo secreto y retirarlo después.

Comportamiento del backend con esta configuración (verificado en el código): `remote` exige las cuatro variables restantes al arrancar; un secreto que no sea base64 estándar de al menos 32 bytes decodificados falla el arranque sin copiar el valor al mensaje; no hay fallback silencioso a ADC. Con `NODE_ENV=production`, `OCR_MODE` es obligatorio y la URL debe ser https.

Los servicios de Render están hoy en el plan Free (512 MB de RAM, 0,1 CPU) y `render.yaml` declara `starter`, que no refleja el panel. La contención PDF (TaskR) se dimensionó para Free; al pasar a un plan de pago, revisar topes y plazos del worker contra los recursos reales y sincronizar `render.yaml`.

## Fase 7 — Smoke sintético (sin datos personales)

**Autorización**: Humana explícita con volumen y costo acotados. **Reversible**: No (consume cuota y facturación; los registros del ledger quedan).

Documentos: un JPEG o PNG sintético, un PDF de 1 página y un PDF de 5 páginas generados para la prueba, sin certificados ni datos reales, y un PDF de 6 páginas. Presupuesto de páginas del smoke: 1 + 1 + 5 = **7 páginas** de Vision.

Para probar `QUOTA` sin gastar 400 páginas, desplegar antes del smoke una revisión con `OCR_MAX_PAGES_PER_ENV_PER_DAY=7` y, al terminar, volver a 400. Esto **no** reinicia el contador del día: las 7 páginas reservadas quedan descontadas. Hacerlo en un día UTC sin otro tráfico.

| # | Caso | Resultado esperado | Cómo comprobar que Vision no se llamó de más |
|---|---|---|---|
| 1 | Imagen sintética firmada | 200, `pageCount` 1 | Cuota del día = 1 |
| 2 | PDF de 1 página | 200, `pageCount` 1 | Cuota = 2 |
| 3 | PDF de 5 páginas | 200, 5 páginas en orden | Cuota = 7 |
| 4a | PDF de 6 páginas vía API Dev (`confirm`) | 400 `CERTIFICATE_IMPORT_PDF_TOO_MANY_PAGES`; no llega al proxy | Sin solicitud al proxy |
| 4b | Solicitud firmada a mano con `X-Ocr-Page-Count: 6` | 400 `INVALID_CONTRACT` | Sin reserva ni llamada |
| 5 | Una imagen más con el límite en 7 | 429 con sobre `{"version":"v1","code":"QUOTA",...}` | Cuota sigue en 7 |
| 6 | Mismo nonce reenviado | 401 `UNAUTHORIZED` (replay) | Sin llamada |
| 7 | Mismo `operationId` con otro contenido | 409 `CONFLICT` | Sin llamada |
| 8 | Pérdida de respuesta: el cliente corta la conexión tras enviar el cuerpo y reintenta con nonce nuevo y el mismo `operationId` | El reintento devuelve 409 `CONFLICT`; en Render equivale a `CERTIFICATE_IMPORT_OCR_FAILED` y revisión manual | El contador de solicitudes de la API Vision en Cloud Console no sube con el reintento; el documento del ledger no vuelve a `PLANNED` |
| 9 | Flujo completo con usuario de prueba en el entorno Dev (subir, confirmar, `process-ocr`) | Filas propuestas o revisión manual; sin `OCR_PROCESSED` ante fallo | Logs sin texto OCR |

Las herramientas para firmar solicitudes a mano (casos 1 a 3, 4b, 5 a 8) no existen todavía (pendiente 3). Pueden implementarse como script efímero que importe el firmante del backend, lea el secreto desde el entorno del proceso (`gcloud secrets versions access ... | script`, nunca como argumento) y no se confirme al repositorio.

Verificaciones transversales: los logs de Cloud Run y de Render no contienen texto OCR, secretos, firmas, nonces ni `operationId` completos; el ledger solo tiene metadata (estado, fechas, digest, MIME, longitud, páginas, reserva, lease/fence); los documentos `UNKNOWN`, si aparecen, se conservan y se tratan a mano.

## Rollback

**Autorización**: Humana explícita. **Reversible**: Sí.

Del más suave al más duro. En todos los casos se conservan el ledger, la evidencia y los comprobantes.

1. **Render a modo directo**: `OCR_MODE=direct`. En Render no hay ADC, así que la lectura automática falla con `CERTIFICATE_IMPORT_OCR_UNAVAILABLE` y el miembro completa a mano con la evidencia confirmada. Es el estado "OCR apagado". La Mac sigue usando ADC con `direct`.
2. **Cerrar Cloud Run sin tocar Render**: `gcloud run services update "$SERVICE" --invoker-iam-check --project "$PROJECT" --region "$REGION"`. La plataforma responde 403 sin sobre v1 y el backend lo trata como `UNAVAILABLE`.
3. **Volver a la revisión anterior** si el problema es del despliegue (`gcloud run services update-traffic`).
4. **Secreto expuesto**: rotar (ver el [runbook](google-vision-certificate-ocr.md#generar-y-rotar-el-secreto-hmac)) y, si hay duda, cerrar el servicio con el paso 2 mientras tanto.

Nunca, como parte de un rollback:

- borrar documentos `UNKNOWN` ni ningún otro documento del ledger;
- reiniciar o editar el contador de cuota del día;
- poner `OCR_MAX_PAGES_PER_ENV_PER_DAY` en `0` (es inválido y no significa "apagado" ni "ilimitado");
- regenerar el `operationId` para forzar una nueva lectura;
- duplicar aprobaciones de negocio.

## Costos orientativos

Cifras del [diseño](../plans/2026-10-02-vision-keyless-design.md): modelo de 400 a 600 documentos iniciales por mes y pico de 3000, de 1 a 2 páginas, 10 segundos activos por solicitud, 1 vCPU y 0,5 GiB. Subtotal referencial con free allowances: **US$0,05 a 0,35 inicial y US$3,05 a 7,55 en pico**; sin free allowances, pico de **US$5,69 a 10,19**. Reserva orientativa de US$5 inicial y US$20 en pico. La tarifa de Firestore se calculó con la publicada para Iowa, no para Virginia.

**Estas cifras no son un tope de factura.** Las instancias máximas, la cuota diaria de 400 páginas y las alertas no limitan el gasto de forma garantizada: invocaciones rechazadas, builds, logs, almacenamiento, borrados por TTL, red y otros servicios también facturan, y un 504 no cancela el trabajo ya iniciado. Configurar alertas de presupuesto en la cuenta de facturación y revisarlas durante el smoke.

Comparación que sustenta la decisión del [ADR 11](../api/ARCHITECTURE-DECISIONS.md): Vision solo tiene cuotas por minuto (1800 solicitudes por minuto por defecto), sin tope diario para estas llamadas. Una API key filtrada expondría del orden de US$19 000 por día (1800 solicitudes por minuto durante 24 horas con PDF de 5 páginas a US$1,50 por 1000 unidades); un HMAC filtrado queda acotado a 400 páginas por día y entorno, unos US$0,60.

## Fuentes oficiales consultadas (2026-10-07)

- Cloud Run, acceso público y `--no-invoker-iam-check`: https://docs.cloud.google.com/run/docs/authenticating/public
- `gcloud run deploy` (flags, `--update-secrets`): https://docs.cloud.google.com/sdk/gcloud/reference/run/deploy
- Cloud Run, despliegue desde fuente y roles: https://docs.cloud.google.com/run/docs/deploying-source-code
- Cloud Run, secretos como variables de entorno: https://docs.cloud.google.com/run/docs/configuring/services/secrets
- Cloud Run, contrato del contenedor (`0.0.0.0`, `PORT`, `SIGTERM` y 10 s): https://docs.cloud.google.com/run/docs/container-contract
- Cloud Run, timeout de solicitud: https://docs.cloud.google.com/run/docs/configuring/request-timeout
- Buildpacks de Node.js (`engines.node`, `scripts.start`): https://docs.cloud.google.com/docs/buildpacks/nodejs
- Firestore, ubicaciones e inmutabilidad: https://docs.cloud.google.com/firestore/native/docs/locations
- `gcloud firestore databases create`: https://docs.cloud.google.com/sdk/gcloud/reference/firestore/databases/create
- Firestore TTL: https://docs.cloud.google.com/firestore/native/docs/ttl
- `gcloud firestore fields ttls update` (flags `--collection-group`, `--enable-ttl`, `--disable-ttl`, `--expiration-offset`, `--async`): https://docs.cloud.google.com/sdk/gcloud/reference/firestore/fields/ttls/update
- `gcloud firestore fields ttls list` (sin `describe`): https://docs.cloud.google.com/sdk/gcloud/reference/firestore/fields/ttls/list
- Firestore REST, `Field.TtlConfig` y estados `CREATING`/`ACTIVE`/`NEEDS_REPAIR`: https://docs.cloud.google.com/firestore/docs/reference/rest/v1/projects.databases.collectionGroups.fields
- Precios de Firestore (el borrado por TTL se factura como borrado): https://cloud.google.com/firestore/pricing
- Roles de Firestore: https://docs.cloud.google.com/firestore/native/docs/security/iam
- Secret Manager (`secrets create`, `add-iam-policy-binding`): https://docs.cloud.google.com/sdk/gcloud/reference/secrets/create · https://docs.cloud.google.com/sdk/gcloud/reference/secrets/add-iam-policy-binding
- Cuotas de Vision (por minuto, 1800/min, 5 páginas por solicitud): https://docs.cloud.google.com/vision/quotas
- Vision, endpoint regional `us-vision.googleapis.com` y alcance de la residencia: https://docs.cloud.google.com/vision/docs/ocr
