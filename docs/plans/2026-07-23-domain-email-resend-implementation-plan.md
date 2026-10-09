# Domain Email with Resend Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Activar el correo automático de SACDIA con
`SACDIA <contacto@sacdia.com>`, proteger la cuota gratuita de Resend y
documentar la configuración manual de Cloudflare, Resend, Render y Gmail.

**Architecture:** Cloudflare Email Routing conserva la recepción y reenvía
`contacto@sacdia.com` a `sacdia.app@gmail.com`. El backend sigue publicando
trabajos en BullMQ y `EmailProcessor` los envía mediante la API de Resend; el
worker limita el procesamiento a 90 trabajos por cada 24 horas. Gmail usa una
segunda API key mediante SMTP de Resend para enviar manualmente como
`contacto@sacdia.com`.

**Tech Stack:** NestJS 11, `@nestjs/bullmq` 11, BullMQ 5, Joi, Jest, Resend,
Cloudflare Email Routing, Render y Gmail.

---

## Worktrees

- Documentación raíz:
  `/Users/abner/Documents/development/sacdia/.worktrees/domain-email-resend`
- Backend:
  `/Users/abner/Documents/development/sacdia/.worktrees/backend-domain-email-resend`

No modificar `.env` reales, no registrar API keys y no ejecutar `pnpm build`.

### Task 1: Validar la configuración de Resend al arrancar

**Files:**
- Create: `sacdia-backend/src/config/env.validation.spec.ts`
- Modify: `sacdia-backend/src/config/env.validation.ts`

**Step 1: Escribir pruebas que fallen**

Crear pruebas unitarias para `envValidationSchema` usando un entorno base
válido y los siguientes casos:

```typescript
it('allows email configuration to be omitted when disabled', () => {
  const { error } = envValidationSchema.validate({
    ...validBaseEnv,
    EMAIL_ENABLED: 'false',
  });

  expect(error).toBeUndefined();
});

it('requires the Resend API key when email is enabled', () => {
  const { error } = envValidationSchema.validate({
    ...validBaseEnv,
    EMAIL_ENABLED: 'true',
    RESEND_FROM_EMAIL: 'SACDIA <contacto@sacdia.com>',
    RESEND_REPLY_TO: 'contacto@sacdia.com',
  });

  expect(error?.message).toContain('RESEND_API_KEY');
});

it('rejects a placeholder Resend API key when email is enabled', () => {
  const { error } = envValidationSchema.validate({
    ...validBaseEnv,
    EMAIL_ENABLED: 'true',
    RESEND_API_KEY: 're_<api-key>',
    RESEND_FROM_EMAIL: 'SACDIA <contacto@sacdia.com>',
  });

  expect(error?.message).toContain('RESEND_API_KEY');
});

it('requires a valid mailbox in the From header when email is enabled', () => {
  const { error } = envValidationSchema.validate({
    ...validBaseEnv,
    EMAIL_ENABLED: 'true',
    RESEND_API_KEY: 're_test_backend_key',
    RESEND_FROM_EMAIL: 'not-an-email',
  });

  expect(error?.message).toContain('RESEND_FROM_EMAIL');
});
```

Completar el entorno base con todas las variables actualmente requeridas por
el schema, usando URLs y valores de prueba.

**Step 2: Ejecutar la prueba y confirmar que falla**

Run:

```bash
pnpm test -- --runInBand src/config/env.validation.spec.ts
```

Expected: FAIL porque las variables de Resend todavía son opcionales cuando
`EMAIL_ENABLED=true`.

**Step 3: Implementar la validación mínima**

En `env.validation.ts`:

- extraer un validador reutilizable para
  `Nombre opcional <mailbox@dominio>` o `mailbox@dominio`;
- exigir `RESEND_API_KEY` no vacía ni placeholder cuando
  `EMAIL_ENABLED='true'`;
- exigir `RESEND_FROM_EMAIL` válida cuando está habilitado;
- mantener `RESEND_REPLY_TO` opcional, pero validarla como email si aparece;
- preservar el comportamiento fail-safe cuando el feature flag está apagado;
- no incluir el valor del secreto en mensajes personalizados.

**Step 4: Ejecutar la prueba y confirmar que pasa**

Run:

```bash
pnpm test -- --runInBand src/config/env.validation.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/config/env.validation.ts src/config/env.validation.spec.ts
git commit -m "fix(email): validate Resend configuration"
```

### Task 2: Aplicar realmente el límite de 90 correos diarios

**Files:**
- Modify: `sacdia-backend/src/common/email/email.queue.ts`
- Modify: `sacdia-backend/src/common/email/email.processor.ts`
- Create: `sacdia-backend/src/common/email/email.queue.spec.ts`
- Modify: `sacdia-backend/src/common/email/email.module.ts`

**Step 1: Escribir la prueba que falle**

Exportar desde `email.queue.ts` una configuración de worker que la prueba pueda
inspeccionar y verificar:

```typescript
expect(EMAIL_WORKER_OPTIONS.limiter).toEqual({
  max: 90,
  duration: 24 * 60 * 60 * 1000,
});
```

La prueba debe dejar explícito que la cuota se aplica al worker, no a
`BullModule.registerQueue`.

**Step 2: Ejecutar la prueba y confirmar que falla**

Run:

```bash
pnpm test -- --runInBand src/common/email/email.queue.spec.ts
```

Expected: FAIL porque `EMAIL_WORKER_OPTIONS` no existe.

**Step 3: Implementar la configuración mínima**

Definir constantes tipadas:

```typescript
export const EMAIL_DAILY_LIMIT = 90;
export const EMAIL_DAILY_LIMIT_DURATION_MS = 24 * 60 * 60 * 1000;
export const EMAIL_WORKER_OPTIONS: NestWorkerOptions = {
  limiter: {
    max: EMAIL_DAILY_LIMIT,
    duration: EMAIL_DAILY_LIMIT_DURATION_MS,
  },
};
```

Aplicarlas en el decorador:

```typescript
@Processor(EMAIL_QUEUE, EMAIL_WORKER_OPTIONS)
```

Actualizar comentarios de `email.module.ts`, `email.queue.ts` y
`email.processor.ts` para describir el límite real en el worker. No moverlo a
la configuración de la cola: BullMQ define `limiter` en `WorkerOptions`.

**Step 4: Ejecutar la prueba y confirmar que pasa**

Run:

```bash
pnpm test -- --runInBand src/common/email/email.queue.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/common/email/email.queue.ts \
  src/common/email/email.queue.spec.ts \
  src/common/email/email.processor.ts \
  src/common/email/email.module.ts
git commit -m "fix(email): enforce daily Resend quota"
```

### Task 3: Usar el remitente canónico y verificar Reply-To

**Files:**
- Create: `sacdia-backend/src/common/email/providers/resend.provider.spec.ts`
- Modify: `sacdia-backend/src/common/email/providers/resend.provider.ts`
- Modify: `sacdia-backend/src/common/email/email.processor.ts`
- Modify: `sacdia-backend/.env.example`

**Step 1: Escribir pruebas que fallen**

Mockear el constructor de `Resend` y comprobar que `emails.send` recibe:

```typescript
expect(mockSend).toHaveBeenCalledWith(
  expect.objectContaining({
    from: 'SACDIA <contacto@sacdia.com>',
    reply_to: 'contacto@sacdia.com',
  }),
);
```

Agregar casos para:

- respetar `payload.from` y `payload.replyTo` cuando el caller los envía;
- propagar un error seguro si Resend devuelve `error`;
- no exponer API key ni destinatario en logs o mensajes de error.

**Step 2: Ejecutar la prueba y confirmar que falla**

Run:

```bash
pnpm test -- --runInBand \
  src/common/email/providers/resend.provider.spec.ts
```

Expected: FAIL porque el fallback actual usa `noreply@sacdia.app`.

**Step 3: Implementar la configuración mínima**

- Cambiar el fallback defensivo del provider y del processor a
  `SACDIA <contacto@sacdia.com>`.
- Mantener `RESEND_REPLY_TO` como fuente del `reply_to` predeterminado.
- Actualizar `.env.example`:

```env
RESEND_FROM_EMAIL=SACDIA <contacto@sacdia.com>
RESEND_REPLY_TO=contacto@sacdia.com
```

- Documentar que se requieren keys distintas para backend y Gmail, sin incluir
  valores reales.

**Step 4: Ejecutar las pruebas dirigidas**

Run:

```bash
pnpm test -- --runInBand \
  src/common/email/providers/resend.provider.spec.ts \
  src/common/email/email.service.spec.ts
```

Expected: PASS.

**Step 5: Commit**

```bash
git add .env.example \
  src/common/email/providers/resend.provider.ts \
  src/common/email/providers/resend.provider.spec.ts \
  src/common/email/email.processor.ts
git commit -m "fix(email): use contacto domain sender"
```

### Task 4: Documentar la operación sin secretos

**Files:**
- Create: `docs/guides/domain-email-operations.md`
- Modify: `docs/README.md`

**Step 1: Crear el runbook**

Documentar en orden:

1. eliminar únicamente la DKIM obsoleta
   `QDblsCnOvCJB...ETO84kuQb78cTQIDAQAB`;
2. conservar la DKIM activa
   `QC7jEbKNVU3...q1uLJvVQIDAQAB`;
3. crear dos keys Resend con `Sending access` restringidas a `sacdia.com`;
4. cargar la key de backend como secreto de Render;
5. configurar Gmail `Enviar como` con `smtp.resend.com`, puerto `465`,
   usuario `resend` y SSL;
6. completar la verificación de Gmail recibida mediante Cloudflare;
7. activar `EMAIL_ENABLED=true` solamente después de los pasos anteriores;
8. validar SPF, DKIM y DMARC en un correo del backend y otro de Gmail;
9. rotar cada key por separado si una integración se compromete;
10. desactivar `EMAIL_ENABLED` como rollback del backend.

Incluir una advertencia clara: nunca pegar API keys en tickets, commits,
capturas o conversaciones.

**Step 2: Enlazar el runbook**

Agregar el documento al índice pertinente de `docs/README.md`, sin cambiar la
arquitectura canónica.

**Step 3: Revisar el contenido**

Run:

```bash
git diff --check
```

Expected: sin errores.

**Step 4: Commit**

```bash
git add docs/guides/domain-email-operations.md docs/README.md
git commit -m "docs(email): add domain email runbook"
```

### Task 5: Verificación final sin build

**Files:**
- Verify only: todos los archivos modificados

**Step 1: Ejecutar la suite dirigida del backend**

Run:

```bash
pnpm test -- --runInBand \
  src/config/env.validation.spec.ts \
  src/common/email/email.queue.spec.ts \
  src/common/email/providers/resend.provider.spec.ts \
  src/common/email/email.service.spec.ts
```

Expected: PASS.

**Step 2: Ejecutar lint solo sobre archivos TypeScript modificados**

Run:

```bash
pnpm exec eslint \
  src/config/env.validation.ts \
  src/config/env.validation.spec.ts \
  src/common/email/email.queue.ts \
  src/common/email/email.queue.spec.ts \
  src/common/email/email.processor.ts \
  src/common/email/email.module.ts \
  src/common/email/providers/resend.provider.ts \
  src/common/email/providers/resend.provider.spec.ts
```

Expected: exit code 0. No usar `--fix` durante la verificación final.

**Step 3: Verificar ambos diffs**

Run en cada worktree:

```bash
git diff --check
git status --short
```

Expected: sin whitespace errors y únicamente los archivos previstos.

**Step 4: No desplegar automáticamente**

La implementación queda lista para revisión. La creación de keys, secretos de
Render, DNS y configuración de Gmail requieren sesión autenticada del usuario
y nunca deben automatizarse compartiendo credenciales en el chat.
