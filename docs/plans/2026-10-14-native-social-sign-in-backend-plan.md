# Native Social Sign-In — Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `POST /api/v1/auth/oauth/:provider/token` verifies a Google or Apple `idToken`, creates or links the SACDIA user and returns the same payload the old OAuth callback returned; `DELETE /auth/me` accepts a fresh `idToken` as re-authentication and revokes Apple tokens; the browser-based Better Auth OAuth flow is removed.

**Architecture:** New `src/auth/social-sign-in/` module. Two `IdTokenVerifier` implementations (Google, Apple) built on `jose` with injectable JWKS; an `AppleTokenClient` that signs the Apple `client_secret` per call and talks to `appleid.apple.com`; a `SocialAccountResolver` that applies the create/link rules inside one Prisma transaction; a `SocialSignInService` that orchestrates and reuses `BetterAuthService.createSession` + `signJwt`. Better Auth no longer participates in OAuth.

**Tech Stack:** NestJS 11, Prisma 7.10, `jose` 6 (ESM-only; Node 24 `require(esm)` and the existing Jest ESM transform already cover it, same as `otplib`), Jest 30, supertest.

**Spec:** `docs/plans/2026-10-14-native-social-sign-in-design.md` (sections 3, 4, 6, 7, 8).

**Repo:** `sacdia-backend`, base `origin/development` at `2c5cc8a7` or later. Conventions: conventional commits, no attribution trailers, `pnpm` via `corepack`, never `git stash` (worktrees share the user's stash), chain shell commands with `&&`.

**Slices → PRs:** B1 = Tasks 1–5, B2 = Tasks 6–9, B3 = Task 10, B4 = Task 11, D1 = Task 12. Open one PR per slice from its own worktree under `/Users/abner/Documents/development/sacdia-worktrees/`. Each slice branches from `origin/development` after the previous slice merged.

---

## File map

| File | Responsibility |
|---|---|
| `src/auth/social-sign-in/social-sign-in.types.ts` | Provider union, `VerifiedIdentity`, `IdTokenVerifier`, DI tokens, `parseCsv` |
| `src/auth/social-sign-in/id-token-errors.ts` | Maps `jose` errors to `AppUnauthorizedException` / `AppServiceUnavailableException` |
| `src/auth/social-sign-in/google-id-token.verifier.ts` (+ `.spec.ts`) | Google `idToken` verification |
| `test/helpers/id-token-fixtures.ts` | Local RS256 JWKS + token signer for the verifier specs |
| `src/auth/social-sign-in/apple-id-token.verifier.ts` (+ `.spec.ts`) | Apple `idToken` verification (hashed nonce) |
| `src/auth/social-sign-in/apple-token.client.ts` (+ `.spec.ts`) | Apple `client_secret`, code exchange, revoke |
| `src/auth/social-sign-in/social-account.resolver.ts` (+ `.spec.ts`) | Find by `(provider, sub)` → link by email → create; SACDIA provisioning |
| `src/auth/social-sign-in/social-sign-in.service.ts` (+ `.spec.ts`) | Orchestration and response shape |
| `src/auth/social-sign-in/dto/social-token-sign-in.dto.ts` | Request DTO |
| `src/auth/social-sign-in/social-sign-in.controller.ts` (+ `.spec.ts`) | `POST /auth/oauth/:provider/token` |
| `src/auth/social-sign-in/social-sign-in.module.ts` | Wiring; exports verifiers and `AppleTokenClient` |
| `test/social-sign-in.e2e-spec.ts` | Endpoint contract |
| `src/auth/dto/delete-account.dto.ts`, `src/auth/account-deletion.service.ts`, `src/auth/auth.controller.ts` | Re-auth with `idToken`, Apple revoke |
| `src/common/errors/error-codes.ts`, `src/i18n/{en,es,fr,pt-BR}/errors.json` | `AUTH_OAUTH_EMAIL_UNVERIFIED`, `AUTH_OAUTH_PROVIDER_UNAVAILABLE` |
| `src/config/env.validation.ts` | `GOOGLE_OAUTH_AUDIENCES`, `APPLE_BUNDLE_ID` |
| `src/better-auth/better-auth.service.ts` | `createSession` made public; OAuth methods removed (B4) |
| `src/better-auth/better-auth.config.ts` | `socialProviders`, `twoFactor`, `trustedOrigins` removed (B4) |
| `src/auth/oauth.controller.ts`, `src/auth/oauth.service.ts`, `src/auth/dto/oauth-*.dto.ts`, `src/auth/oauth-redirect-allowlist.ts` | Old flow removed (B4) |

---

## Slice B1 — verifiers and Apple client

### Task 1: Worktree, dependency, shared types

**Files:**
- Create: `src/auth/social-sign-in/social-sign-in.types.ts`
- Modify: `package.json`, `pnpm-lock.yaml`

- [ ] **Step 1: Create the worktree and install**

```bash
git -C /Users/abner/Documents/development/sacdia/sacdia-backend fetch origin development && git -C /Users/abner/Documents/development/sacdia/sacdia-backend worktree add -b feat/social-sign-in-verifiers /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 origin/development && cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm install --frozen-lockfile && corepack pnpm exec prisma generate
```

- [ ] **Step 2: Add `jose` as a direct dependency**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm add jose@^6.2.12
```

Expected: `package.json` gains `"jose": "^6.2.12"` under `dependencies`; lockfile reuses the already-resolved `jose@6.2.12`.

- [ ] **Step 3: Write the shared types**

`src/auth/social-sign-in/social-sign-in.types.ts`:

```ts
/**
 * Native social sign-in (mobile app).
 *
 * The app obtains an OpenID `idToken` from the Google or Apple SDK and posts
 * it to `POST /auth/oauth/:provider/token`. The backend verifies the token
 * itself (jose + the provider JWKS) and owns the users/accounts rows.
 * Better Auth is not involved.
 */

export const SOCIAL_PROVIDERS = ['google', 'apple'] as const;
export type SocialProvider = (typeof SOCIAL_PROVIDERS)[number];

export function isSocialProvider(value: string): value is SocialProvider {
  return (SOCIAL_PROVIDERS as readonly string[]).includes(value);
}

/** Claims SACDIA keeps from a verified provider id token. */
export interface VerifiedIdentity {
  provider: SocialProvider;
  /** Provider subject. Stable per user; stored as `accounts.account_id`. */
  sub: string;
  email: string | null;
  emailVerified: boolean;
  givenName?: string;
  familyName?: string;
  picture?: string;
}

export interface IdTokenVerifier {
  readonly provider: SocialProvider;
  /**
   * Verifies signature, issuer, audience, expiry and nonce.
   * Throws AppUnauthorizedException(AUTH_INVALID_TOKEN) on any mismatch and
   * AppServiceUnavailableException(AUTH_OAUTH_PROVIDER_UNAVAILABLE) when the
   * provider JWKS cannot be fetched.
   */
  verify(idToken: string, nonce: string): Promise<VerifiedIdentity>;
}

/** Nest DI tokens. String tokens match the `'BETTER_AUTH_INSTANCE'` style. */
export const GOOGLE_ID_TOKEN_VERIFIER = 'GOOGLE_ID_TOKEN_VERIFIER';
export const APPLE_ID_TOKEN_VERIFIER = 'APPLE_ID_TOKEN_VERIFIER';

/** Splits a comma-separated env value, trimming and dropping empties. */
export function parseCsv(value: string | undefined): string[] {
  return (value ?? '')
    .split(',')
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}

/** First 8 chars of a subject — enough to correlate logs, never the full id. */
export function truncateSub(sub: unknown): string {
  return typeof sub === 'string' ? `${sub.slice(0, 8)}…` : 'unknown';
}
```

- [ ] **Step 4: Typecheck and commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm exec tsc --noEmit -p tsconfig.build.json && git add package.json pnpm-lock.yaml src/auth/social-sign-in/social-sign-in.types.ts && git commit -m "feat(auth): add jose and the social sign-in types"
```

---

### Task 2: Error codes, i18n and env validation

**Files:**
- Modify: `src/common/errors/error-codes.ts:43`
- Modify: `src/i18n/en/errors.json:203`, `src/i18n/es/errors.json:203`, `src/i18n/fr/errors.json:200`, `src/i18n/pt-BR/errors.json:200`
- Modify: `src/config/env.validation.ts:360-370`
- Create: `src/auth/social-sign-in/id-token-errors.ts` (+ spec)

- [ ] **Step 1: Add the two error codes**

In `src/common/errors/error-codes.ts`, after the line
`  AUTH_OAUTH_PROVIDER_NOT_CONNECTED = 'AUTH_OAUTH_PROVIDER_NOT_CONNECTED',` add:

```ts
  AUTH_OAUTH_EMAIL_UNVERIFIED = 'AUTH_OAUTH_EMAIL_UNVERIFIED',
  AUTH_OAUTH_PROVIDER_UNAVAILABLE = 'AUTH_OAUTH_PROVIDER_UNAVAILABLE',
```

- [ ] **Step 2: Add the messages in the four locales**

After the `"AUTH_OAUTH_PROVIDER_NOT_CONNECTED"` line of each file:

`src/i18n/en/errors.json`:
```json
  "AUTH_OAUTH_EMAIL_UNVERIFIED": "The provider did not return a verified email address",
  "AUTH_OAUTH_PROVIDER_UNAVAILABLE": "The sign-in provider is temporarily unavailable",
```

`src/i18n/es/errors.json`:
```json
  "AUTH_OAUTH_EMAIL_UNVERIFIED": "El proveedor no devolvió un correo verificado",
  "AUTH_OAUTH_PROVIDER_UNAVAILABLE": "El proveedor de inicio de sesión no está disponible por el momento",
```

`src/i18n/fr/errors.json`:
```json
  "AUTH_OAUTH_EMAIL_UNVERIFIED": "Le fournisseur n'a pas renvoyé d'adresse e-mail vérifiée",
  "AUTH_OAUTH_PROVIDER_UNAVAILABLE": "Le fournisseur de connexion est temporairement indisponible",
```

`src/i18n/pt-BR/errors.json`:
```json
  "AUTH_OAUTH_EMAIL_UNVERIFIED": "O provedor não retornou um e-mail verificado",
  "AUTH_OAUTH_PROVIDER_UNAVAILABLE": "O provedor de login está temporariamente indisponível",
```

Keep the trailing-comma rules of each file valid (`node -e "require('./src/i18n/es/errors.json')"` must not throw for each locale).

- [ ] **Step 3: Add the env variables**

In `src/config/env.validation.ts`, replace the block

```ts
  // OAuth providers
  GOOGLE_CLIENT_ID: Joi.string().allow('').optional(),
  GOOGLE_CLIENT_SECRET: Joi.string().allow('').optional(),
  APPLE_CLIENT_ID: Joi.string().allow('').optional(),
  APPLE_TEAM_ID: Joi.string().allow('').optional(),
  APPLE_KEY_ID: Joi.string().allow('').optional(),
  APPLE_PRIVATE_KEY: Joi.string().allow('').optional(),
```

with

```ts
  // OAuth providers (Better Auth browser flow — removed in B4)
  GOOGLE_CLIENT_ID: Joi.string().allow('').optional(),
  GOOGLE_CLIENT_SECRET: Joi.string().allow('').optional(),
  APPLE_CLIENT_ID: Joi.string().allow('').optional(),
  // Native social sign-in (POST /auth/oauth/:provider/token)
  // Comma-separated Google client IDs accepted as `aud`. Must include the
  // Web client ID the app passes as serverClientId.
  GOOGLE_OAUTH_AUDIENCES: Joi.string().allow('').optional(),
  // `aud` of Apple id tokens and client_id of the Apple token endpoint.
  APPLE_BUNDLE_ID: Joi.string().allow('').optional(),
  // Sign in with Apple key (.p8) used to sign the per-call client_secret.
  APPLE_TEAM_ID: Joi.string().allow('').optional(),
  APPLE_KEY_ID: Joi.string().allow('').optional(),
  APPLE_PRIVATE_KEY: Joi.string().allow('').optional(),
```

- [ ] **Step 4: Write the failing test for the jose error mapper**

`src/auth/social-sign-in/id-token-errors.spec.ts`:

```ts
import { Logger } from '@nestjs/common';
import { errors } from 'jose';
import {
  AppServiceUnavailableException,
  AppUnauthorizedException,
} from '../../common/errors/app.exception';
import { ErrorCode } from '../../common/errors/error-codes';
import { mapIdTokenError } from './id-token-errors';

describe('mapIdTokenError', () => {
  const logger = new Logger('test');
  let warn: jest.SpyInstance;
  let error: jest.SpyInstance;

  beforeEach(() => {
    warn = jest.spyOn(logger, 'warn').mockImplementation(() => undefined);
    error = jest.spyOn(logger, 'error').mockImplementation(() => undefined);
  });

  afterEach(() => jest.restoreAllMocks());

  it.each([
    ['expired', new errors.JWTExpired('exp', {}, 'exp', 'check_failed')],
    ['bad signature', new errors.JWSSignatureVerificationFailed()],
    ['no matching key', new errors.JWKSNoMatchingKey()],
    [
      'claim mismatch',
      new errors.JWTClaimValidationFailed('aud', {}, 'aud', 'check_failed'),
    ],
    ['malformed', new errors.JWTInvalid('bad')],
  ])('maps %s to 401 AUTH_INVALID_TOKEN', (_label, cause) => {
    const mapped = mapIdTokenError(cause, logger, 'google');
    expect(mapped).toBeInstanceOf(AppUnauthorizedException);
    expect((mapped as AppUnauthorizedException).code).toBe(
      ErrorCode.AUTH_INVALID_TOKEN,
    );
    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining('google id token rejected'),
    );
  });

  it('maps a JWKS timeout to 503 AUTH_OAUTH_PROVIDER_UNAVAILABLE', () => {
    const mapped = mapIdTokenError(new errors.JWKSTimeout(), logger, 'apple');
    expect(mapped).toBeInstanceOf(AppServiceUnavailableException);
    expect((mapped as AppServiceUnavailableException).code).toBe(
      ErrorCode.AUTH_OAUTH_PROVIDER_UNAVAILABLE,
    );
    expect(error).toHaveBeenCalledWith(
      expect.stringContaining('apple JWKS unavailable'),
    );
  });

  it('maps a network failure (non-jose error) to 503', () => {
    const mapped = mapIdTokenError(new TypeError('fetch failed'), logger, 'google');
    expect(mapped).toBeInstanceOf(AppServiceUnavailableException);
  });
});
```

- [ ] **Step 5: Run it to verify it fails**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm exec jest src/auth/social-sign-in/id-token-errors.spec.ts
```
Expected: FAIL — `Cannot find module './id-token-errors'`.

- [ ] **Step 6: Implement the mapper**

`src/auth/social-sign-in/id-token-errors.ts`:

```ts
import type { Logger } from '@nestjs/common';
import { errors } from 'jose';
import {
  AppServiceUnavailableException,
  AppUnauthorizedException,
} from '../../common/errors/app.exception';
import { ErrorCode } from '../../common/errors/error-codes';
import type { SocialProvider } from './social-sign-in.types';

/**
 * Turns a `jwtVerify` failure into the API error the client sees.
 *
 * Every verification failure (signature, iss, aud, exp, unknown kid, malformed
 * token) is a 401 — the token is not usable, whatever the reason. Only a JWKS
 * outage (timeout or network error while fetching the provider keys) is a 503,
 * because retrying later can succeed.
 *
 * The log line carries the jose error code, never the token.
 */
export function mapIdTokenError(
  cause: unknown,
  logger: Logger,
  provider: SocialProvider,
): AppUnauthorizedException | AppServiceUnavailableException {
  if (cause instanceof errors.JOSEError && !(cause instanceof errors.JWKSTimeout)) {
    logger.warn(`${provider} id token rejected — ${cause.code}: ${cause.message}`);
    return new AppUnauthorizedException(ErrorCode.AUTH_INVALID_TOKEN);
  }
  const message = cause instanceof Error ? cause.message : String(cause);
  logger.error(`${provider} JWKS unavailable — ${message}`);
  return new AppServiceUnavailableException(
    ErrorCode.AUTH_OAUTH_PROVIDER_UNAVAILABLE,
  );
}
```

- [ ] **Step 7: Run tests, typecheck, commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm exec jest src/auth/social-sign-in && corepack pnpm exec tsc --noEmit -p tsconfig.build.json && for l in en es fr pt-BR; do node -e "require('./src/i18n/$l/errors.json')"; done && git add src/common/errors/error-codes.ts src/i18n src/config/env.validation.ts src/auth/social-sign-in/id-token-errors.ts src/auth/social-sign-in/id-token-errors.spec.ts && git commit -m "feat(auth): add social sign-in error codes, env vars and jose error mapping"
```
Expected: 7 tests pass.

---

### Task 3: GoogleIdTokenVerifier

**Files:**
- Create: `src/auth/social-sign-in/google-id-token.verifier.ts`
- Test: `src/auth/social-sign-in/google-id-token.verifier.spec.ts`
- Create: `test/helpers/id-token-fixtures.ts` (shared by both verifier specs; `test/` is excluded from `tsconfig.build.json`, so it never ships in `dist`)

- [ ] **Step 1: Write the test fixture helper**

`test/helpers/id-token-fixtures.ts`:

```ts
import {
  SignJWT,
  createLocalJWKSet,
  exportJWK,
  generateKeyPair,
  type JWTPayload,
  type JWTVerifyGetKey,
} from 'jose';

/**
 * Local RS256 key pair + JWKS resolver, so verifier specs never touch the
 * network. `extractable: true` is required to export the public JWK.
 */
export interface IdTokenFixture {
  getKey: JWTVerifyGetKey;
  sign: (claims: JWTPayload & { kid?: string }) => Promise<string>;
  /** A second key the JWKS does not know — for "unknown kid" cases. */
  signWithUnknownKey: (claims: JWTPayload) => Promise<string>;
}

export async function createIdTokenFixture(): Promise<IdTokenFixture> {
  const known = await generateKeyPair('RS256', { extractable: true });
  const unknown = await generateKeyPair('RS256', { extractable: true });
  const jwk = await exportJWK(known.publicKey);
  const getKey = createLocalJWKSet({
    keys: [{ ...jwk, kid: 'known-kid', alg: 'RS256', use: 'sig' }],
  });

  // jose 6 returns CryptoKey (the KeyLike alias was removed in v6).
  const sign = (privateKey: CryptoKey, kid: string) =>
    async ({ kid: overrideKid, ...claims }: JWTPayload & { kid?: string }) =>
      new SignJWT(claims)
        .setProtectedHeader({ alg: 'RS256', kid: overrideKid ?? kid })
        .setIssuedAt()
        .sign(privateKey);

  return {
    getKey,
    sign: sign(known.privateKey, 'known-kid'),
    signWithUnknownKey: sign(unknown.privateKey, 'unknown-kid'),
  };
}

export const FUTURE = Math.floor(Date.now() / 1000) + 300;
export const PAST = Math.floor(Date.now() / 1000) - 300;
```

- [ ] **Step 2: Write the failing spec**

`src/auth/social-sign-in/google-id-token.verifier.spec.ts`:

```ts
import { AppUnauthorizedException } from '../../common/errors/app.exception';
import { ErrorCode } from '../../common/errors/error-codes';
import { GoogleIdTokenVerifier } from './google-id-token.verifier';
import {
  FUTURE,
  PAST,
  createIdTokenFixture,
  type IdTokenFixture,
} from '../../../test/helpers/id-token-fixtures';

describe('GoogleIdTokenVerifier', () => {
  let fixture: IdTokenFixture;
  let verifier: GoogleIdTokenVerifier;
  const audience = 'web-client-id.apps.googleusercontent.com';
  const nonce = 'raw-nonce-123';

  const validClaims = () => ({
    iss: 'https://accounts.google.com',
    aud: audience,
    sub: '1234567890',
    exp: FUTURE,
    nonce,
    email: 'ana@example.com',
    email_verified: true,
    given_name: 'Ana',
    family_name: 'Pérez',
    picture: 'https://lh3.googleusercontent.com/a/photo',
  });

  beforeAll(async () => {
    fixture = await createIdTokenFixture();
  });

  beforeEach(() => {
    verifier = new GoogleIdTokenVerifier({
      audiences: [audience, 'ios-client-id.apps.googleusercontent.com'],
      getKey: fixture.getKey,
    });
  });

  it('returns the identity for a valid token', async () => {
    const token = await fixture.sign(validClaims());
    await expect(verifier.verify(token, nonce)).resolves.toEqual({
      provider: 'google',
      sub: '1234567890',
      email: 'ana@example.com',
      emailVerified: true,
      givenName: 'Ana',
      familyName: 'Pérez',
      picture: 'https://lh3.googleusercontent.com/a/photo',
    });
  });

  it('accepts the legacy issuer without scheme', async () => {
    const token = await fixture.sign({ ...validClaims(), iss: 'accounts.google.com' });
    await expect(verifier.verify(token, nonce)).resolves.toMatchObject({ sub: '1234567890' });
  });

  it('reports an unverified email instead of rejecting', async () => {
    const token = await fixture.sign({ ...validClaims(), email_verified: false });
    await expect(verifier.verify(token, nonce)).resolves.toMatchObject({ emailVerified: false });
  });

  const rejects = async (token: string, usedNonce = nonce) => {
    const error = await verifier.verify(token, usedNonce).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(AppUnauthorizedException);
    expect((error as AppUnauthorizedException).code).toBe(ErrorCode.AUTH_INVALID_TOKEN);
  };

  it('rejects a token signed by an unknown key', async () => {
    await rejects(await fixture.signWithUnknownKey(validClaims()));
  });

  it('rejects a wrong issuer', async () => {
    await rejects(await fixture.sign({ ...validClaims(), iss: 'https://evil.example' }));
  });

  it('rejects an audience outside GOOGLE_OAUTH_AUDIENCES', async () => {
    await rejects(await fixture.sign({ ...validClaims(), aud: 'other-client' }));
  });

  it('rejects an expired token', async () => {
    await rejects(await fixture.sign({ ...validClaims(), exp: PAST }));
  });

  it('rejects a nonce mismatch', async () => {
    await rejects(await fixture.sign(validClaims()), 'different-nonce');
  });

  it('rejects a token without nonce', async () => {
    const { nonce: _omit, ...claims } = validClaims();
    await rejects(await fixture.sign(claims));
  });

  it('rejects everything when no audience is configured', async () => {
    verifier = new GoogleIdTokenVerifier({ audiences: [], getKey: fixture.getKey });
    await rejects(await fixture.sign(validClaims()));
  });
});
```

- [ ] **Step 3: Run it to verify it fails**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm exec jest src/auth/social-sign-in/google-id-token.verifier.spec.ts
```
Expected: FAIL — `Cannot find module './google-id-token.verifier'`.

- [ ] **Step 4: Implement the verifier**

`src/auth/social-sign-in/google-id-token.verifier.ts`:

```ts
import { Logger } from '@nestjs/common';
import { jwtVerify, type JWTPayload, type JWTVerifyGetKey } from 'jose';
import { AppUnauthorizedException } from '../../common/errors/app.exception';
import { ErrorCode } from '../../common/errors/error-codes';
import { mapIdTokenError } from './id-token-errors';
import {
  truncateSub,
  type IdTokenVerifier,
  type VerifiedIdentity,
} from './social-sign-in.types';

export const GOOGLE_JWKS_URL = 'https://www.googleapis.com/oauth2/v3/certs';
/** Google issues both forms depending on the SDK. */
export const GOOGLE_ISSUERS = ['accounts.google.com', 'https://accounts.google.com'];

export interface GoogleIdTokenVerifierOptions {
  /** Client IDs accepted as `aud` (GOOGLE_OAUTH_AUDIENCES). */
  audiences: string[];
  /** `createRemoteJWKSet(GOOGLE_JWKS_URL)` in production, a local set in tests. */
  getKey: JWTVerifyGetKey;
}

export class GoogleIdTokenVerifier implements IdTokenVerifier {
  readonly provider = 'google' as const;
  private readonly logger = new Logger(GoogleIdTokenVerifier.name);

  constructor(private readonly options: GoogleIdTokenVerifierOptions) {
    if (options.audiences.length === 0) {
      this.logger.error(
        'GOOGLE_OAUTH_AUDIENCES is empty — every Google id token will be rejected',
      );
    }
  }

  async verify(idToken: string, nonce: string): Promise<VerifiedIdentity> {
    if (this.options.audiences.length === 0) {
      throw new AppUnauthorizedException(ErrorCode.AUTH_INVALID_TOKEN);
    }

    let payload: JWTPayload;
    try {
      ({ payload } = await jwtVerify(idToken, this.options.getKey, {
        issuer: GOOGLE_ISSUERS,
        audience: this.options.audiences,
        algorithms: ['RS256'],
      }));
    } catch (error) {
      throw mapIdTokenError(error, this.logger, this.provider);
    }

    if (typeof payload.sub !== 'string' || payload.sub.length === 0) {
      this.logger.warn('google id token rejected — missing sub');
      throw new AppUnauthorizedException(ErrorCode.AUTH_INVALID_TOKEN);
    }
    // Google passes the nonce through untouched (Apple hashes it, see
    // AppleIdTokenVerifier). A missing nonce is a replayable token: reject.
    if (payload.nonce !== nonce) {
      this.logger.warn(
        `google id token rejected — nonce mismatch (sub ${truncateSub(payload.sub)})`,
      );
      throw new AppUnauthorizedException(ErrorCode.AUTH_INVALID_TOKEN);
    }

    return {
      provider: this.provider,
      sub: payload.sub,
      email: typeof payload.email === 'string' ? payload.email : null,
      emailVerified: payload.email_verified === true,
      givenName: optionalString(payload.given_name),
      familyName: optionalString(payload.family_name),
      picture: optionalString(payload.picture),
    };
  }
}

function optionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.length > 0 ? value : undefined;
}
```

- [ ] **Step 5: Run tests, lint, commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm exec jest src/auth/social-sign-in && corepack pnpm exec eslint src/auth/social-sign-in test/helpers/id-token-fixtures.ts && corepack pnpm exec prettier --check "src/auth/social-sign-in/**/*.ts" test/helpers/id-token-fixtures.ts && git add src/auth/social-sign-in test/helpers/id-token-fixtures.ts && git commit -m "feat(auth): verify Google id tokens with jose"
```
Expected: 10 new tests pass. If `prettier --check` fails, run `corepack pnpm exec prettier --write "src/auth/social-sign-in/**/*.ts"` and re-add.

---

### Task 4: AppleIdTokenVerifier

**Files:**
- Create: `src/auth/social-sign-in/apple-id-token.verifier.ts`
- Test: `src/auth/social-sign-in/apple-id-token.verifier.spec.ts`

- [ ] **Step 1: Write the failing spec**

```ts
import { createHash } from 'crypto';
import { AppUnauthorizedException } from '../../common/errors/app.exception';
import { ErrorCode } from '../../common/errors/error-codes';
import { AppleIdTokenVerifier } from './apple-id-token.verifier';
import {
  FUTURE,
  PAST,
  createIdTokenFixture,
  type IdTokenFixture,
} from '../../../test/helpers/id-token-fixtures';

describe('AppleIdTokenVerifier', () => {
  let fixture: IdTokenFixture;
  let verifier: AppleIdTokenVerifier;
  const bundleId = 'app.sacdia.mobile';
  const nonce = 'raw-nonce-456';
  const hashedNonce = createHash('sha256').update(nonce).digest('hex');

  const validClaims = () => ({
    iss: 'https://appleid.apple.com',
    aud: bundleId,
    sub: '001234.abcdef.5678',
    exp: FUTURE,
    nonce: hashedNonce,
    nonce_supported: true,
    email: 'relay@privaterelay.appleid.com',
    email_verified: 'true',
    is_private_email: 'true',
  });

  beforeAll(async () => {
    fixture = await createIdTokenFixture();
  });

  beforeEach(() => {
    verifier = new AppleIdTokenVerifier({ bundleId, getKey: fixture.getKey });
  });

  it('returns the identity and parses the string email_verified', async () => {
    const token = await fixture.sign(validClaims());
    await expect(verifier.verify(token, nonce)).resolves.toEqual({
      provider: 'apple',
      sub: '001234.abcdef.5678',
      email: 'relay@privaterelay.appleid.com',
      emailVerified: true,
    });
  });

  it('accepts a boolean email_verified', async () => {
    const token = await fixture.sign({ ...validClaims(), email_verified: true });
    await expect(verifier.verify(token, nonce)).resolves.toMatchObject({ emailVerified: true });
  });

  it('reports email_verified "false" as unverified', async () => {
    const token = await fixture.sign({ ...validClaims(), email_verified: 'false' });
    await expect(verifier.verify(token, nonce)).resolves.toMatchObject({ emailVerified: false });
  });

  const rejects = async (token: string, usedNonce = nonce) => {
    const error = await verifier.verify(token, usedNonce).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(AppUnauthorizedException);
    expect((error as AppUnauthorizedException).code).toBe(ErrorCode.AUTH_INVALID_TOKEN);
  };

  it('rejects a raw (unhashed) nonce claim', async () => {
    await rejects(await fixture.sign({ ...validClaims(), nonce }));
  });

  it('rejects a nonce mismatch', async () => {
    await rejects(await fixture.sign(validClaims()), 'other-nonce');
  });

  it('rejects a wrong audience', async () => {
    await rejects(await fixture.sign({ ...validClaims(), aud: 'app.other' }));
  });

  it('rejects a wrong issuer', async () => {
    await rejects(await fixture.sign({ ...validClaims(), iss: 'https://accounts.google.com' }));
  });

  it('rejects an expired token', async () => {
    await rejects(await fixture.sign({ ...validClaims(), exp: PAST }));
  });

  it('rejects an unknown signing key', async () => {
    await rejects(await fixture.signWithUnknownKey(validClaims()));
  });

  it('rejects everything when APPLE_BUNDLE_ID is empty', async () => {
    verifier = new AppleIdTokenVerifier({ bundleId: '', getKey: fixture.getKey });
    await rejects(await fixture.sign(validClaims()));
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm exec jest src/auth/social-sign-in/apple-id-token.verifier.spec.ts
```
Expected: FAIL — module not found.

- [ ] **Step 3: Implement the verifier**

`src/auth/social-sign-in/apple-id-token.verifier.ts`:

```ts
import { Logger } from '@nestjs/common';
import { createHash } from 'crypto';
import { jwtVerify, type JWTPayload, type JWTVerifyGetKey } from 'jose';
import { AppUnauthorizedException } from '../../common/errors/app.exception';
import { ErrorCode } from '../../common/errors/error-codes';
import { mapIdTokenError } from './id-token-errors';
import {
  truncateSub,
  type IdTokenVerifier,
  type VerifiedIdentity,
} from './social-sign-in.types';

export const APPLE_JWKS_URL = 'https://appleid.apple.com/auth/keys';
export const APPLE_ISSUER = 'https://appleid.apple.com';

export interface AppleIdTokenVerifierOptions {
  /** iOS bundle identifier — the `aud` of native Sign in with Apple tokens. */
  bundleId: string;
  getKey: JWTVerifyGetKey;
}

/** Apple puts SHA-256(nonce) in the token; the app sends the raw nonce. */
export function hashAppleNonce(nonce: string): string {
  return createHash('sha256').update(nonce).digest('hex');
}

export class AppleIdTokenVerifier implements IdTokenVerifier {
  readonly provider = 'apple' as const;
  private readonly logger = new Logger(AppleIdTokenVerifier.name);

  constructor(private readonly options: AppleIdTokenVerifierOptions) {
    if (!options.bundleId) {
      this.logger.error(
        'APPLE_BUNDLE_ID is empty — every Apple id token will be rejected',
      );
    }
  }

  async verify(idToken: string, nonce: string): Promise<VerifiedIdentity> {
    if (!this.options.bundleId) {
      throw new AppUnauthorizedException(ErrorCode.AUTH_INVALID_TOKEN);
    }

    let payload: JWTPayload;
    try {
      ({ payload } = await jwtVerify(idToken, this.options.getKey, {
        issuer: APPLE_ISSUER,
        audience: this.options.bundleId,
        algorithms: ['RS256'],
      }));
    } catch (error) {
      throw mapIdTokenError(error, this.logger, this.provider);
    }

    if (typeof payload.sub !== 'string' || payload.sub.length === 0) {
      this.logger.warn('apple id token rejected — missing sub');
      throw new AppUnauthorizedException(ErrorCode.AUTH_INVALID_TOKEN);
    }
    if (payload.nonce !== hashAppleNonce(nonce)) {
      this.logger.warn(
        `apple id token rejected — nonce mismatch (sub ${truncateSub(payload.sub)})`,
      );
      throw new AppUnauthorizedException(ErrorCode.AUTH_INVALID_TOKEN);
    }

    // The app passes SHA-256(nonce) to the Apple SDK, so the token carries the
    // hash while we receive the raw nonce. Apple never includes the name in the
    // token: the app sends it on the first sign-in as `fullName`.
    return {
      provider: this.provider,
      sub: payload.sub,
      email: typeof payload.email === 'string' ? payload.email : null,
      emailVerified: isTrue(payload.email_verified),
    };
  }
}

/** Apple sends `email_verified` as the string "true" on some tokens. */
function isTrue(value: unknown): boolean {
  return value === true || value === 'true';
}
```

- [ ] **Step 4: Run tests, lint, commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm exec jest src/auth/social-sign-in && corepack pnpm exec eslint src/auth/social-sign-in && corepack pnpm exec prettier --check "src/auth/social-sign-in/**/*.ts" && git add src/auth/social-sign-in && git commit -m "feat(auth): verify Apple id tokens with jose"
```
Expected: 10 new tests pass.

---

### Task 5: AppleTokenClient and the module

**Files:**
- Create: `src/auth/social-sign-in/apple-token.client.ts`
- Test: `src/auth/social-sign-in/apple-token.client.spec.ts`
- Create: `src/auth/social-sign-in/social-sign-in.module.ts`
- Modify: `src/auth/auth.module.ts:16-36`

- [ ] **Step 1: Write the failing spec**

`src/auth/social-sign-in/apple-token.client.spec.ts`:

```ts
import { ConfigService } from '@nestjs/config';
import { exportPKCS8, generateKeyPair, jwtVerify } from 'jose';
import { AppleTokenClient, APPLE_TOKEN_URL, APPLE_REVOKE_URL } from './apple-token.client';

describe('AppleTokenClient', () => {
  let client: AppleTokenClient;
  let fetchMock: jest.Mock;
  let publicKey: CryptoKey;

  beforeAll(async () => {
    const pair = await generateKeyPair('ES256', { extractable: true });
    publicKey = pair.publicKey;
    const pem = await exportPKCS8(pair.privateKey);
    const config = new ConfigService({
      APPLE_TEAM_ID: 'TEAM123456',
      APPLE_KEY_ID: 'KEY1234567',
      APPLE_BUNDLE_ID: 'app.sacdia.mobile',
      // Render stores multi-line secrets with literal \n — the client must unescape.
      APPLE_PRIVATE_KEY: pem.replace(/\n/g, '\\n'),
    });
    fetchMock = jest.fn();
    client = new AppleTokenClient(config, fetchMock as unknown as typeof fetch);
  });

  beforeEach(() => fetchMock.mockReset());

  it('signs a client_secret with ES256 and the Apple claims', async () => {
    const secret = await client.clientSecret();
    const { payload, protectedHeader } = await jwtVerify(secret, publicKey, {
      issuer: 'TEAM123456',
      audience: 'https://appleid.apple.com',
      subject: 'app.sacdia.mobile',
    });
    expect(protectedHeader).toMatchObject({ alg: 'ES256', kid: 'KEY1234567' });
    // iat and exp are both "now"-based; allow a 1 s boundary crossing.
    expect(Math.abs(payload.exp! - payload.iat! - 300)).toBeLessThanOrEqual(1);
  });

  it('exchanges an authorization code for a refresh token', async () => {
    fetchMock.mockResolvedValue(
      new Response(JSON.stringify({ refresh_token: 'rt-1', id_token: 'x' }), { status: 200 }),
    );

    await expect(client.exchangeCode('auth-code')).resolves.toEqual({ refreshToken: 'rt-1' });

    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe(APPLE_TOKEN_URL);
    const body = new URLSearchParams(init.body as string);
    expect(body.get('grant_type')).toBe('authorization_code');
    expect(body.get('code')).toBe('auth-code');
    expect(body.get('client_id')).toBe('app.sacdia.mobile');
    expect(body.get('client_secret')).toEqual(expect.any(String));
  });

  it('throws when the token endpoint answers non-2xx', async () => {
    fetchMock.mockResolvedValue(
      new Response(JSON.stringify({ error: 'invalid_grant' }), { status: 400 }),
    );
    await expect(client.exchangeCode('bad')).rejects.toThrow('invalid_grant');
  });

  it('revokes a refresh token', async () => {
    fetchMock.mockResolvedValue(new Response(null, { status: 200 }));
    await expect(client.revoke('rt-1')).resolves.toBeUndefined();
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe(APPLE_REVOKE_URL);
    const body = new URLSearchParams(init.body as string);
    expect(body.get('token')).toBe('rt-1');
    expect(body.get('token_type_hint')).toBe('refresh_token');
  });

  it('throws when revoke answers non-2xx', async () => {
    fetchMock.mockResolvedValue(new Response('nope', { status: 400 }));
    await expect(client.revoke('rt-1')).rejects.toThrow('400');
  });

  it('throws a clear error when the Apple key config is missing', async () => {
    const bare = new AppleTokenClient(new ConfigService({}), fetchMock as unknown as typeof fetch);
    await expect(bare.clientSecret()).rejects.toThrow('APPLE_TEAM_ID');
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm exec jest src/auth/social-sign-in/apple-token.client.spec.ts
```
Expected: FAIL — module not found.

- [ ] **Step 3: Implement the client**

`src/auth/social-sign-in/apple-token.client.ts`:

```ts
import { Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SignJWT, importPKCS8 } from 'jose';

export const APPLE_TOKEN_URL = 'https://appleid.apple.com/auth/token';
export const APPLE_REVOKE_URL = 'https://appleid.apple.com/auth/revoke';
const APPLE_AUDIENCE = 'https://appleid.apple.com';
/** Apple allows up to 6 months; we sign per call, so 5 minutes is plenty. */
const CLIENT_SECRET_TTL = '5m';

export const FETCH_IMPL = 'SOCIAL_SIGN_IN_FETCH';

/**
 * Server-to-Apple calls for Sign in with Apple.
 *
 * `client_secret` is a JWT signed with the .p8 key (ES256). Signing it per
 * request avoids the 6-month rotation a cached secret would need.
 *
 * Used for: exchanging the native `authorizationCode` for a `refresh_token`
 * (stored in accounts.refresh_token) and revoking it when the user deletes
 * the account (App Store guideline 5.1.1(v)).
 */
@Injectable()
export class AppleTokenClient {
  private readonly logger = new Logger(AppleTokenClient.name);

  constructor(
    private readonly config: ConfigService,
    @Optional() @Inject(FETCH_IMPL) private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  async clientSecret(): Promise<string> {
    const teamId = this.required('APPLE_TEAM_ID');
    const keyId = this.required('APPLE_KEY_ID');
    const bundleId = this.required('APPLE_BUNDLE_ID');
    const pem = this.required('APPLE_PRIVATE_KEY').replace(/\\n/g, '\n');
    const key = await importPKCS8(pem, 'ES256');
    return new SignJWT({})
      .setProtectedHeader({ alg: 'ES256', kid: keyId })
      .setIssuer(teamId)
      .setSubject(bundleId)
      .setAudience(APPLE_AUDIENCE)
      .setIssuedAt()
      .setExpirationTime(CLIENT_SECRET_TTL)
      .sign(key);
  }

  /** Returns null when Apple did not include a refresh token. */
  async exchangeCode(code: string): Promise<{ refreshToken: string | null }> {
    const response = await this.post(APPLE_TOKEN_URL, {
      grant_type: 'authorization_code',
      code,
    });
    const body = (await response.json()) as { refresh_token?: unknown };
    return {
      refreshToken: typeof body.refresh_token === 'string' ? body.refresh_token : null,
    };
  }

  async revoke(refreshToken: string): Promise<void> {
    await this.post(APPLE_REVOKE_URL, {
      token: refreshToken,
      token_type_hint: 'refresh_token',
    });
  }

  private async post(url: string, fields: Record<string, string>): Promise<Response> {
    const body = new URLSearchParams({
      client_id: this.required('APPLE_BUNDLE_ID'),
      client_secret: await this.clientSecret(),
      ...fields,
    });
    const response = await this.fetchImpl(url, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: body.toString(),
    });
    if (!response.ok) {
      const text = await response.text().catch(() => '');
      // Apple's error body is {"error":"invalid_grant"}; keep it, drop the rest.
      const reason = text.slice(0, 200);
      this.logger.warn(`Apple ${url} answered ${response.status}: ${reason}`);
      throw new Error(`Apple token endpoint ${response.status}: ${reason}`);
    }
    return response;
  }

  private required(name: string): string {
    const value = this.config.get<string>(name);
    if (!value) throw new Error(`${name} is not configured`);
    return value;
  }
}
```

- [ ] **Step 4: Run the spec**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm exec jest src/auth/social-sign-in/apple-token.client.spec.ts
```
Expected: 6 tests pass.

- [ ] **Step 5: Create the module**

`src/auth/social-sign-in/social-sign-in.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createRemoteJWKSet } from 'jose';
import { AppleIdTokenVerifier, APPLE_JWKS_URL } from './apple-id-token.verifier';
import { AppleTokenClient } from './apple-token.client';
import { GoogleIdTokenVerifier, GOOGLE_JWKS_URL } from './google-id-token.verifier';
import {
  APPLE_ID_TOKEN_VERIFIER,
  GOOGLE_ID_TOKEN_VERIFIER,
  parseCsv,
} from './social-sign-in.types';

/** jose caches the JWKS; 5 s is the fetch timeout, not a cache TTL. */
const JWKS_OPTIONS = { timeoutDuration: 5_000 };

/**
 * Native social sign-in for the mobile app. See
 * docs/plans/2026-10-14-native-social-sign-in-design.md (workspace root).
 */
@Module({
  providers: [
    {
      provide: GOOGLE_ID_TOKEN_VERIFIER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        new GoogleIdTokenVerifier({
          audiences: parseCsv(config.get<string>('GOOGLE_OAUTH_AUDIENCES')),
          getKey: createRemoteJWKSet(new URL(GOOGLE_JWKS_URL), JWKS_OPTIONS),
        }),
    },
    {
      provide: APPLE_ID_TOKEN_VERIFIER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        new AppleIdTokenVerifier({
          bundleId: config.get<string>('APPLE_BUNDLE_ID') ?? '',
          getKey: createRemoteJWKSet(new URL(APPLE_JWKS_URL), JWKS_OPTIONS),
        }),
    },
    AppleTokenClient,
  ],
  exports: [GOOGLE_ID_TOKEN_VERIFIER, APPLE_ID_TOKEN_VERIFIER, AppleTokenClient],
})
export class SocialSignInModule {}
```

- [ ] **Step 6: Import it from AuthModule**

In `src/auth/auth.module.ts`, after `import { BetterAuthModule } from '../better-auth/better-auth.module';` add:

```ts
import { SocialSignInModule } from './social-sign-in/social-sign-in.module';
```

and in the `imports` array, after `BetterAuthModule,` add:

```ts
    // Native Google/Apple sign-in (verifiers + Apple token client)
    SocialSignInModule,
```

- [ ] **Step 7: Full check and commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && corepack pnpm exec tsc --noEmit -p tsconfig.build.json && corepack pnpm exec jest src/auth && corepack pnpm exec eslint src/auth/social-sign-in src/auth/auth.module.ts && corepack pnpm exec prettier --check "src/auth/**/*.ts" && git add src/auth && git commit -m "feat(auth): add the Apple token client and the social sign-in module"
```

- [ ] **Step 8: Push and open PR B1**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b1 && git push -u origin feat/social-sign-in-verifiers && gh pr create -R abn-r/sacdia-backend --base development --head feat/social-sign-in-verifiers --title "feat(auth): verify Google and Apple id tokens (social sign-in B1)" --label "type:feature" --body "## Summary
- Adds \`jose\` and \`src/auth/social-sign-in/\`: Google and Apple id-token verifiers, Apple token client (per-call client_secret, code exchange, revoke), error codes and env vars.
- No endpoint yet (B2). No behaviour change for clients.

Spec: workspace \`docs/plans/2026-10-14-native-social-sign-in-design.md\`.

## Test plan
- [x] \`jest src/auth\` — verifier specs use a local JWKS (no network)
- [x] \`tsc --noEmit -p tsconfig.build.json\`, eslint, prettier
- [ ] CI green"
```

---

## Slice B2 — resolver, service, endpoint

Start from a fresh worktree after B1 merged:

```bash
git -C /Users/abner/Documents/development/sacdia/sacdia-backend fetch origin development && git -C /Users/abner/Documents/development/sacdia/sacdia-backend worktree add -b feat/social-sign-in-endpoint /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 origin/development && cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 && corepack pnpm install --frozen-lockfile && corepack pnpm exec prisma generate
```

### Task 6: Make `createSession` public

**Files:**
- Modify: `src/better-auth/better-auth.service.ts:101-103` (interface) and `:240` (method)

- [ ] **Step 1: Expose the method**

In the `IBetterAuthService` interface, after `signInWithPassword(...)` add:

```ts
  /** Creates a 7-day opaque session for an already-authenticated user. */
  createSession(userId: string): Promise<BaSession>;
```

In the class, change `private async createSession(userId: string): Promise<BaSession> {` to `async createSession(userId: string): Promise<BaSession> {`. Leave the doc comment.

- [ ] **Step 2: Typecheck and commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 && corepack pnpm exec tsc --noEmit -p tsconfig.build.json && corepack pnpm exec jest src/better-auth && git add src/better-auth/better-auth.service.ts && git commit -m "refactor(auth): expose BetterAuthService.createSession for social sign-in"
```

---

### Task 7: SocialAccountResolver

**Files:**
- Create: `src/auth/social-sign-in/social-account.resolver.ts`
- Test: `src/auth/social-sign-in/social-account.resolver.spec.ts`

Rules (spec §3, D2, D3):
1. `accounts(provider_id, account_id = sub)` exists → that user. Sync `user_image` from `picture` when it changed.
2. Else `users.email` exists → link: create the `accounts` row. If `users.email_verified = false`, delete the `credential` account row (the password) and set `email_verified = true`.
3. Else create `users` + `accounts`.
4. Always ensure `users_pr` and the default `users_roles` row (moved from `OAuthService.ensureSacdiaUserProvisioned`).
All inside one `$transaction`.

- [ ] **Step 1: Write the failing spec**

```ts
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { SocialAccountResolver } from './social-account.resolver';
import type { VerifiedIdentity } from './social-sign-in.types';

describe('SocialAccountResolver', () => {
  let resolver: SocialAccountResolver;

  const tx = {
    account: { findUnique: jest.fn(), create: jest.fn(), deleteMany: jest.fn() },
    users: { findUnique: jest.fn(), create: jest.fn(), update: jest.fn() },
    users_pr: { findUnique: jest.fn(), create: jest.fn() },
    users_roles: { findFirst: jest.fn(), create: jest.fn() },
    roles: { findFirst: jest.fn() },
  };
  const prisma = { $transaction: jest.fn() };

  const identity: VerifiedIdentity = {
    provider: 'google',
    sub: 'google-sub-1',
    email: 'ana@example.com',
    emailVerified: true,
    givenName: 'Ana',
    familyName: 'Pérez',
    picture: 'https://lh3.googleusercontent.com/a/photo',
  };
  const existingUser = {
    user_id: 'user-1',
    email: 'ana@example.com',
    email_verified: true,
    user_image: null,
    active: true,
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    prisma.$transaction.mockImplementation(async (fn: (t: typeof tx) => Promise<unknown>) => fn(tx));
    tx.users_pr.findUnique.mockResolvedValue({ user_id: 'user-1' });
    tx.users_roles.findFirst.mockResolvedValue({ user_id: 'user-1' });

    const module = await Test.createTestingModule({
      providers: [SocialAccountResolver, { provide: PrismaService, useValue: prisma }],
    }).compile();
    resolver = module.get(SocialAccountResolver);
  });

  it('returns the linked user when (provider, sub) already exists', async () => {
    tx.account.findUnique.mockResolvedValue({ userId: 'user-1' });
    tx.users.findUnique.mockResolvedValue(existingUser);

    await expect(resolver.resolve(identity)).resolves.toEqual({
      userId: 'user-1',
      created: false,
      linked: false,
    });
    expect(tx.account.findUnique).toHaveBeenCalledWith({
      where: { providerId_accountId: { providerId: 'google', accountId: 'google-sub-1' } },
      select: { userId: true },
    });
    expect(tx.account.create).not.toHaveBeenCalled();
    expect(tx.users.update).toHaveBeenCalledWith({
      where: { user_id: 'user-1' },
      data: { user_image: identity.picture },
    });
  });

  it('links by email when the account is new and the email exists', async () => {
    tx.account.findUnique.mockResolvedValue(null);
    tx.users.findUnique.mockResolvedValue(existingUser);

    await expect(resolver.resolve(identity)).resolves.toEqual({
      userId: 'user-1',
      created: false,
      linked: true,
    });
    expect(tx.account.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        accountId: 'google-sub-1',
        providerId: 'google',
        userId: 'user-1',
      }),
    });
    expect(tx.account.deleteMany).not.toHaveBeenCalled();
  });

  it('drops the password when linking to an unverified local account', async () => {
    tx.account.findUnique.mockResolvedValue(null);
    tx.users.findUnique.mockResolvedValue({ ...existingUser, email_verified: false });

    await resolver.resolve(identity);

    expect(tx.account.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', providerId: 'credential' },
    });
    expect(tx.users.update).toHaveBeenCalledWith({
      where: { user_id: 'user-1' },
      data: expect.objectContaining({ email_verified: true }),
    });
  });

  it('creates the user, the account and the SACDIA rows when nothing matches', async () => {
    tx.account.findUnique.mockResolvedValue(null);
    tx.users.findUnique.mockResolvedValue(null);
    tx.users.create.mockImplementation(async ({ data }: { data: { user_id: string } }) => data);
    tx.users_pr.findUnique.mockResolvedValue(null);
    tx.users_roles.findFirst.mockResolvedValue(null);
    tx.roles.findFirst.mockResolvedValue({ role_id: 7 });

    const result = await resolver.resolve(identity);

    expect(result).toMatchObject({ created: true, linked: false });
    expect(tx.users.create).toHaveBeenCalledWith({
      data: {
        user_id: result.userId,
        email: 'ana@example.com',
        name: 'Ana',
        paternal_last_name: 'Pérez',
        email_verified: true,
        user_image: identity.picture,
      },
    });
    expect(tx.account.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ userId: result.userId, providerId: 'google' }),
    });
    expect(tx.users_pr.create).toHaveBeenCalledWith({
      data: {
        user_id: result.userId,
        complete: false,
        profile_picture_complete: false,
        personal_info_complete: false,
        club_selection_complete: false,
      },
    });
    expect(tx.users_roles.create).toHaveBeenCalledWith({
      data: { user_id: result.userId, role_id: 7 },
    });
  });

  it('falls back to the email local part when no name is available', async () => {
    tx.account.findUnique.mockResolvedValue(null);
    tx.users.findUnique.mockResolvedValue(null);
    tx.users.create.mockImplementation(async ({ data }: { data: { user_id: string } }) => data);

    await resolver.resolve({ provider: 'apple', sub: 'apple-sub', email: 'ana@example.com', emailVerified: true });

    expect(tx.users.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ name: 'ana', paternal_last_name: null }),
    });
  });

  it('truncates names to the 50-char columns', async () => {
    tx.account.findUnique.mockResolvedValue(null);
    tx.users.findUnique.mockResolvedValue(null);
    tx.users.create.mockImplementation(async ({ data }: { data: { user_id: string } }) => data);

    await resolver.resolve({ ...identity, givenName: 'x'.repeat(80) });

    expect(tx.users.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ name: 'x'.repeat(50) }),
    });
  });

  it('runs everything inside one transaction', async () => {
    tx.account.findUnique.mockResolvedValue({ userId: 'user-1' });
    tx.users.findUnique.mockResolvedValue(existingUser);
    await resolver.resolve(identity);
    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 && corepack pnpm exec jest src/auth/social-sign-in/social-account.resolver.spec.ts
```
Expected: FAIL — module not found.

- [ ] **Step 3: Implement the resolver**

`src/auth/social-sign-in/social-account.resolver.ts`:

```ts
import { Injectable, Logger } from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import type { VerifiedIdentity } from './social-sign-in.types';

export interface ResolvedSocialAccount {
  userId: string;
  /** A users row was created in this call. */
  created: boolean;
  /** The provider was attached to an existing email account in this call. */
  linked: boolean;
}

/** `users.name` and `users.paternal_last_name` are VarChar(50). */
const NAME_MAX = 50;

/**
 * Maps a verified provider identity to a SACDIA user.
 *
 * Identity is `(provider, sub)` in `accounts` — never the email. Email is only
 * used to attach a provider to an existing account the first time (D3). An
 * existing local account that never verified its email loses its password on
 * link: the provider proved the address, the password owner never did.
 *
 * Everything runs in one transaction so a failure leaves no half-linked user.
 */
@Injectable()
export class SocialAccountResolver {
  private readonly logger = new Logger(SocialAccountResolver.name);

  constructor(private readonly prisma: PrismaService) {}

  async resolve(identity: VerifiedIdentity): Promise<ResolvedSocialAccount> {
    return this.prisma.$transaction(async (tx) => {
      const result = await this.findOrCreate(tx, identity);
      await this.provisionSacdiaRows(tx, result.userId);
      return result;
    });
  }

  private async findOrCreate(
    tx: Prisma.TransactionClient,
    identity: VerifiedIdentity,
  ): Promise<ResolvedSocialAccount> {
    const { provider, sub } = identity;

    // 1. Returning user
    const account = await tx.account.findUnique({
      where: { providerId_accountId: { providerId: provider, accountId: sub } },
      select: { userId: true },
    });
    if (account) {
      await this.syncPicture(tx, account.userId, identity.picture);
      return { userId: account.userId, created: false, linked: false };
    }

    // 2. Same email already registered → link
    const email = identity.email!; // SocialSignInService rejects null before resolving
    const existing = await tx.users.findUnique({
      where: { email },
      select: { user_id: true, email_verified: true, user_image: true },
    });
    if (existing) {
      await tx.account.create({
        data: { id: randomUUID(), accountId: sub, providerId: provider, userId: existing.user_id },
      });
      if (!existing.email_verified) {
        // D3: the unverified password holder never proved the address.
        await tx.account.deleteMany({
          where: { userId: existing.user_id, providerId: 'credential' },
        });
        await tx.users.update({
          where: { user_id: existing.user_id },
          data: { email_verified: true, ...(identity.picture ? { user_image: identity.picture } : {}) },
        });
        this.logger.warn(
          `Linked ${provider} to unverified account ${existing.user_id} — credential removed`,
        );
      } else {
        await this.syncPicture(tx, existing.user_id, identity.picture, existing.user_image);
      }
      this.logger.log(`Linked ${provider} to existing user ${existing.user_id}`);
      return { userId: existing.user_id, created: false, linked: true };
    }

    // 3. New user
    const userId = randomUUID();
    await tx.users.create({
      data: {
        user_id: userId,
        email,
        name: (identity.givenName ?? email.split('@')[0]).slice(0, NAME_MAX),
        paternal_last_name: identity.familyName?.slice(0, NAME_MAX) ?? null,
        email_verified: true,
        user_image: identity.picture ?? null,
      },
    });
    await tx.account.create({
      data: { id: randomUUID(), accountId: sub, providerId: provider, userId },
    });
    this.logger.log(`Created user ${userId} from ${provider}`);
    return { userId, created: true, linked: false };
  }

  /** Keeps `user_image` in step with the provider photo (Google changes it). */
  private async syncPicture(
    tx: Prisma.TransactionClient,
    userId: string,
    picture: string | undefined,
    current?: string | null,
  ): Promise<void> {
    if (!picture) return;
    if (current === undefined) {
      const user = await tx.users.findUnique({ where: { user_id: userId }, select: { user_image: true } });
      current = user?.user_image ?? null;
    }
    if (picture !== current) {
      await tx.users.update({ where: { user_id: userId }, data: { user_image: picture } });
    }
  }

  /**
   * SACDIA rows the auth tables know nothing about: post-registration state
   * and the default global role. Idempotent. (Moved from
   * OAuthService.ensureSacdiaUserProvisioned.)
   */
  private async provisionSacdiaRows(
    tx: Prisma.TransactionClient,
    userId: string,
  ): Promise<void> {
    const pr = await tx.users_pr.findUnique({ where: { user_id: userId } });
    if (!pr) {
      await tx.users_pr.create({
        data: {
          user_id: userId,
          complete: false,
          profile_picture_complete: false,
          personal_info_complete: false,
          club_selection_complete: false,
        },
      });
    }

    const role = await tx.users_roles.findFirst({ where: { user_id: userId } });
    if (role) return;
    const userRole = await tx.roles.findFirst({
      where: { role_name: 'user', role_category: 'GLOBAL' },
    });
    if (!userRole) {
      // Not fatal for login; the role seed is missing and must be fixed separately.
      this.logger.error('Default "user" role not found in DB');
      return;
    }
    await tx.users_roles.create({ data: { user_id: userId, role_id: userRole.role_id } });
  }
}
```

Note for the first test: the "returning user" branch calls `tx.users.findUnique` inside `syncPicture` with `select: { user_image: true }`; the spec's mock returns `existingUser` (image `null`) so the update is expected.

- [ ] **Step 4: Run tests, lint, commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 && corepack pnpm exec jest src/auth/social-sign-in/social-account.resolver.spec.ts && corepack pnpm exec eslint src/auth/social-sign-in && corepack pnpm exec prettier --check "src/auth/social-sign-in/**/*.ts" && git add src/auth/social-sign-in && git commit -m "feat(auth): resolve social identities to SACDIA users"
```
Expected: 7 tests pass.

---

### Task 8: SocialSignInService

**Files:**
- Create: `src/auth/social-sign-in/social-sign-in.service.ts`
- Create: `src/auth/social-sign-in/dto/social-token-sign-in.dto.ts`
- Test: `src/auth/social-sign-in/social-sign-in.service.spec.ts`

- [ ] **Step 1: Write the DTO**

`src/auth/social-sign-in/dto/social-token-sign-in.dto.ts`:

```ts
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

/** Apple only sends the name to the client, and only on the first sign-in. */
export class SocialFullNameDto {
  @ApiPropertyOptional({ example: 'Ana' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  givenName?: string;

  @ApiPropertyOptional({ example: 'Pérez' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  familyName?: string;
}

export class SocialTokenSignInDto {
  @ApiProperty({ description: 'OpenID id token issued by Google or Apple to the app' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  idToken!: string;

  @ApiProperty({
    description:
      'Raw nonce the app generated for this attempt. Google echoes it; Apple stores its SHA-256.',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(256)
  nonce!: string;

  @ApiPropertyOptional({
    description: 'Apple authorization code; exchanged server-side for the refresh token used on account deletion.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  authorizationCode?: string;

  @ApiPropertyOptional({ type: SocialFullNameDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => SocialFullNameDto)
  fullName?: SocialFullNameDto;
}
```

- [ ] **Step 2: Write the failing service spec**

```ts
import { Test } from '@nestjs/testing';
import { BetterAuthService } from '../../better-auth/better-auth.service';
import { AppUnauthorizedException } from '../../common/errors/app.exception';
import { ErrorCode } from '../../common/errors/error-codes';
import { FILE_STORAGE_SERVICE } from '../../common/services/file-storage.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AppleTokenClient } from './apple-token.client';
import { SocialAccountResolver } from './social-account.resolver';
import { SocialSignInService } from './social-sign-in.service';
import {
  APPLE_ID_TOKEN_VERIFIER,
  GOOGLE_ID_TOKEN_VERIFIER,
  type VerifiedIdentity,
} from './social-sign-in.types';

describe('SocialSignInService', () => {
  let service: SocialSignInService;

  const google = { provider: 'google', verify: jest.fn() };
  const apple = { provider: 'apple', verify: jest.fn() };
  const resolver = { resolve: jest.fn() };
  const appleTokens = { exchangeCode: jest.fn() };
  const betterAuth = {
    createSession: jest.fn().mockResolvedValue({
      id: 'sess-1',
      token: 'opaque-token',
      expiresAt: new Date(1_900_000_000_000),
    }),
    signJwt: jest.fn().mockReturnValue('sacdia-jwt'),
  };
  const prisma = {
    users: { findUnique: jest.fn() },
    users_pr: { findUnique: jest.fn() },
    account: { findMany: jest.fn(), update: jest.fn() },
  };
  const fileStorage = { getSignedDownloadUrl: jest.fn(async (_b: unknown, v: string) => `signed:${v}`) };

  const identity: VerifiedIdentity = {
    provider: 'google',
    sub: 'g-1',
    email: 'ana@example.com',
    emailVerified: true,
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    google.verify.mockResolvedValue(identity);
    apple.verify.mockResolvedValue({ ...identity, provider: 'apple', sub: 'a-1' });
    resolver.resolve.mockResolvedValue({ userId: 'user-1', created: false, linked: false });
    prisma.users.findUnique.mockResolvedValue({
      user_id: 'user-1', email: 'ana@example.com', name: 'Ana',
      paternal_last_name: 'Pérez', maternal_last_name: null, user_image: 'profiles/u1.jpg',
    });
    prisma.users_pr.findUnique.mockResolvedValue({ complete: true });
    prisma.account.findMany.mockResolvedValue([{ providerId: 'credential' }, { providerId: 'google' }]);

    const module = await Test.createTestingModule({
      providers: [
        SocialSignInService,
        { provide: GOOGLE_ID_TOKEN_VERIFIER, useValue: google },
        { provide: APPLE_ID_TOKEN_VERIFIER, useValue: apple },
        { provide: SocialAccountResolver, useValue: resolver },
        { provide: AppleTokenClient, useValue: appleTokens },
        { provide: BetterAuthService, useValue: betterAuth },
        { provide: PrismaService, useValue: prisma },
        { provide: FILE_STORAGE_SERVICE, useValue: fileStorage },
      ],
    }).compile();
    service = module.get(SocialSignInService);
  });

  it('returns the old OAuth callback payload plus the login token fields', async () => {
    await expect(
      service.signIn('google', { idToken: 't', nonce: 'n' }),
    ).resolves.toEqual({
      accessToken: 'sacdia-jwt',
      sessionToken: 'opaque-token',
      refreshToken: 'opaque-token',
      expiresAt: 1_900_000_000,
      tokenType: 'bearer',
      user: {
        id: 'user-1',
        email: 'ana@example.com',
        name: 'Ana',
        paternal_last_name: 'Pérez',
        maternal_last_name: null,
        avatar: 'signed:profiles/u1.jpg',
        connectedProviders: ['google'],
      },
      needsPostRegistration: false,
    });
    expect(google.verify).toHaveBeenCalledWith('t', 'n');
    expect(betterAuth.createSession).toHaveBeenCalledWith('user-1');
    expect(betterAuth.signJwt).toHaveBeenCalledWith(
      { id: 'user-1', email: 'ana@example.com' }, false, 'sess-1',
    );
  });

  it('flags post-registration for a new user', async () => {
    resolver.resolve.mockResolvedValue({ userId: 'user-1', created: true, linked: false });
    prisma.users_pr.findUnique.mockResolvedValue({ complete: false });
    await expect(service.signIn('google', { idToken: 't', nonce: 'n' })).resolves.toMatchObject({
      needsPostRegistration: true,
    });
  });

  it('rejects an identity without a verified email', async () => {
    google.verify.mockResolvedValue({ ...identity, emailVerified: false });
    const error = await service.signIn('google', { idToken: 't', nonce: 'n' }).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(AppUnauthorizedException);
    expect((error as AppUnauthorizedException).code).toBe(ErrorCode.AUTH_OAUTH_EMAIL_UNVERIFIED);
    expect(resolver.resolve).not.toHaveBeenCalled();
  });

  it('rejects an identity without email', async () => {
    google.verify.mockResolvedValue({ ...identity, email: null });
    await expect(service.signIn('google', { idToken: 't', nonce: 'n' })).rejects.toMatchObject({
      code: ErrorCode.AUTH_OAUTH_EMAIL_UNVERIFIED,
    });
  });

  it('uses the app-provided full name for Apple', async () => {
    await service.signIn('apple', {
      idToken: 't', nonce: 'n', fullName: { givenName: 'Ana', familyName: 'Pérez' },
    });
    expect(resolver.resolve).toHaveBeenCalledWith(
      expect.objectContaining({ provider: 'apple', givenName: 'Ana', familyName: 'Pérez' }),
    );
  });

  it('stores the Apple refresh token after exchanging the authorization code', async () => {
    appleTokens.exchangeCode.mockResolvedValue({ refreshToken: 'rt-1' });
    await service.signIn('apple', { idToken: 't', nonce: 'n', authorizationCode: 'code' });
    expect(appleTokens.exchangeCode).toHaveBeenCalledWith('code');
    expect(prisma.account.update).toHaveBeenCalledWith({
      where: { providerId_accountId: { providerId: 'apple', accountId: 'a-1' } },
      data: { refreshToken: 'rt-1' },
    });
  });

  it('still signs in when the Apple code exchange fails', async () => {
    appleTokens.exchangeCode.mockRejectedValue(new Error('invalid_grant'));
    await expect(
      service.signIn('apple', { idToken: 't', nonce: 'n', authorizationCode: 'code' }),
    ).resolves.toMatchObject({ accessToken: 'sacdia-jwt' });
    expect(prisma.account.update).not.toHaveBeenCalled();
  });

  it('does not call Apple when no authorization code is sent', async () => {
    await service.signIn('apple', { idToken: 't', nonce: 'n' });
    expect(appleTokens.exchangeCode).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 3: Run it to verify it fails**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 && corepack pnpm exec jest src/auth/social-sign-in/social-sign-in.service.spec.ts
```
Expected: FAIL — module not found.

- [ ] **Step 4: Implement the service**

`src/auth/social-sign-in/social-sign-in.service.ts`:

```ts
import { Inject, Injectable, Logger } from '@nestjs/common';
import { BetterAuthService } from '../../better-auth/better-auth.service';
import { AppUnauthorizedException } from '../../common/errors/app.exception';
import { ErrorCode } from '../../common/errors/error-codes';
import {
  FILE_STORAGE_SERVICE,
  StorageBucketAlias,
} from '../../common/services/file-storage.service';
import type { FileStorageService } from '../../common/services/file-storage.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AppleTokenClient } from './apple-token.client';
import type { SocialTokenSignInDto } from './dto/social-token-sign-in.dto';
import { SocialAccountResolver } from './social-account.resolver';
import {
  APPLE_ID_TOKEN_VERIFIER,
  GOOGLE_ID_TOKEN_VERIFIER,
  truncateSub,
  type IdTokenVerifier,
  type SocialProvider,
  type VerifiedIdentity,
} from './social-sign-in.types';

/**
 * Shape of the old `POST /auth/oauth/callback` plus the token fields
 * `POST /auth/login` returns (`refreshToken`, `expiresAt`, `tokenType`), so the
 * app parses both responses with the same code. `sessionToken` and
 * `refreshToken` carry the same opaque session token.
 */
export interface SocialSignInResult {
  accessToken: string;
  sessionToken: string;
  refreshToken: string;
  /** Unix seconds, like /auth/login. */
  expiresAt: number;
  tokenType: 'bearer';
  user: {
    id: string;
    email: string;
    name: string | null;
    paternal_last_name: string | null;
    maternal_last_name: string | null;
    avatar: string | null;
    connectedProviders: string[];
  };
  needsPostRegistration: boolean;
}

@Injectable()
export class SocialSignInService {
  private readonly logger = new Logger(SocialSignInService.name);
  private static readonly PRIVATE_ASSET_URL_TTL_SECONDS = 300;
  private readonly verifiers: Record<SocialProvider, IdTokenVerifier>;

  constructor(
    @Inject(GOOGLE_ID_TOKEN_VERIFIER) google: IdTokenVerifier,
    @Inject(APPLE_ID_TOKEN_VERIFIER) apple: IdTokenVerifier,
    private readonly resolver: SocialAccountResolver,
    private readonly appleTokens: AppleTokenClient,
    private readonly betterAuth: BetterAuthService,
    private readonly prisma: PrismaService,
    @Inject(FILE_STORAGE_SERVICE)
    private readonly fileStorage: FileStorageService,
  ) {
    this.verifiers = { google, apple };
  }

  async signIn(
    provider: SocialProvider,
    dto: SocialTokenSignInDto,
  ): Promise<SocialSignInResult> {
    const verified = await this.verifiers[provider].verify(dto.idToken, dto.nonce);
    if (!verified.email || !verified.emailVerified) {
      this.logger.warn(
        `${provider} sign-in rejected — unverified or missing email (sub ${truncateSub(verified.sub)})`,
      );
      throw new AppUnauthorizedException(ErrorCode.AUTH_OAUTH_EMAIL_UNVERIFIED);
    }

    const identity: VerifiedIdentity =
      provider === 'apple' && dto.fullName
        ? { ...verified, givenName: dto.fullName.givenName, familyName: dto.fullName.familyName }
        : verified;

    const { userId, created, linked } = await this.resolver.resolve(identity);

    if (provider === 'apple' && dto.authorizationCode) {
      await this.storeAppleRefreshToken(identity.sub, dto.authorizationCode);
    }

    const session = await this.betterAuth.createSession(userId);
    const [user, userPr, accounts] = await Promise.all([
      this.prisma.users.findUnique({ where: { user_id: userId } }),
      this.prisma.users_pr.findUnique({ where: { user_id: userId } }),
      this.prisma.account.findMany({ where: { userId }, select: { providerId: true } }),
    ]);
    const email = user?.email ?? identity.email!;
    const accessToken = this.betterAuth.signJwt({ id: userId, email }, false, session.id);

    this.logger.log(
      `${provider} sign-in for user ${userId} (created=${created} linked=${linked})`,
    );

    return {
      accessToken,
      sessionToken: session.token,
      refreshToken: session.token,
      expiresAt: Math.floor(session.expiresAt.getTime() / 1000),
      tokenType: 'bearer',
      user: {
        id: userId,
        email,
        name: user?.name ?? null,
        paternal_last_name: user?.paternal_last_name ?? null,
        maternal_last_name: user?.maternal_last_name ?? null,
        avatar: await this.signedAvatar(user?.user_image),
        connectedProviders: accounts
          .map((a) => a.providerId)
          .filter((p) => p !== 'credential'),
      },
      needsPostRegistration: !userPr?.complete,
    };
  }

  /**
   * Best effort: a failure here must not block sign-in. Without the refresh
   * token, account deletion skips the Apple revoke (logged there).
   */
  private async storeAppleRefreshToken(sub: string, code: string): Promise<void> {
    try {
      const { refreshToken } = await this.appleTokens.exchangeCode(code);
      if (!refreshToken) {
        this.logger.warn(`Apple code exchange returned no refresh token (sub ${truncateSub(sub)})`);
        return;
      }
      await this.prisma.account.update({
        where: { providerId_accountId: { providerId: 'apple', accountId: sub } },
        data: { refreshToken },
      });
    } catch (error) {
      this.logger.warn(
        `Apple code exchange failed (sub ${truncateSub(sub)}) — ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  private async signedAvatar(value: string | null | undefined): Promise<string | null> {
    if (!value) return null;
    try {
      return await this.fileStorage.getSignedDownloadUrl(
        StorageBucketAlias.USER_PROFILES,
        value,
        { expiresInSeconds: SocialSignInService.PRIVATE_ASSET_URL_TTL_SECONDS },
      );
    } catch (error) {
      this.logger.warn('Failed to sign the profile picture URL; returning the stored value', error);
      return value;
    }
  }
}
```

- [ ] **Step 5: Run tests, lint, commit**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 && corepack pnpm exec jest src/auth/social-sign-in && corepack pnpm exec eslint src/auth/social-sign-in && corepack pnpm exec prettier --check "src/auth/social-sign-in/**/*.ts" && git add src/auth/social-sign-in && git commit -m "feat(auth): orchestrate native social sign-in"
```
Expected: 8 new tests pass.

---

### Task 9: Controller, module wiring, e2e

**Files:**
- Create: `src/auth/social-sign-in/social-sign-in.controller.ts` (+ `.spec.ts`)
- Modify: `src/auth/social-sign-in/social-sign-in.module.ts`
- Create: `test/social-sign-in.e2e-spec.ts`

- [ ] **Step 1: Write the failing controller spec**

`src/auth/social-sign-in/social-sign-in.controller.spec.ts`:

```ts
import { Test } from '@nestjs/testing';
import { ErrorCode } from '../../common/errors/error-codes';
import { SocialSignInController } from './social-sign-in.controller';
import { SocialSignInService } from './social-sign-in.service';

describe('SocialSignInController', () => {
  let controller: SocialSignInController;
  const service = { signIn: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      controllers: [SocialSignInController],
      providers: [{ provide: SocialSignInService, useValue: service }],
    }).compile();
    controller = module.get(SocialSignInController);
  });

  it('applies the auth-grade 5/min throttle', () => {
    for (const name of ['short', 'medium', 'long']) {
      expect(Reflect.getMetadata(`THROTTLER:LIMIT${name}`, SocialSignInController)).toBe(5);
      expect(Reflect.getMetadata(`THROTTLER:TTL${name}`, SocialSignInController)).toBe(60000);
    }
  });

  it('delegates a known provider to the service', async () => {
    service.signIn.mockResolvedValue({ accessToken: 'jwt' });
    const dto = { idToken: 't', nonce: 'n' };
    await expect(controller.signIn('google', dto)).resolves.toEqual({ accessToken: 'jwt' });
    expect(service.signIn).toHaveBeenCalledWith('google', dto);
  });

  it('rejects an unknown provider with AUTH_OAUTH_PROVIDER_INVALID', async () => {
    await expect(controller.signIn('facebook', { idToken: 't', nonce: 'n' })).rejects.toMatchObject({
      code: ErrorCode.AUTH_OAUTH_PROVIDER_INVALID,
    });
    expect(service.signIn).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 && corepack pnpm exec jest src/auth/social-sign-in/social-sign-in.controller.spec.ts
```
Expected: FAIL — module not found.

- [ ] **Step 3: Implement the controller**

`src/auth/social-sign-in/social-sign-in.controller.ts`:

```ts
import { Body, Controller, Param, Post } from '@nestjs/common';
import { ApiOperation, ApiParam, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Public } from '../../common/decorators/public.decorator';
import { SkipPermissions } from '../../common/decorators/skip-permissions.decorator';
import { AppBadRequestException } from '../../common/errors/app.exception';
import { ErrorCode } from '../../common/errors/error-codes';
import { namedThrottle } from '../../config/throttler.helpers';
import { SocialTokenSignInDto } from './dto/social-token-sign-in.dto';
import { SocialSignInService } from './social-sign-in.service';
import { SOCIAL_PROVIDERS, isSocialProvider } from './social-sign-in.types';

/**
 * Native social sign-in for the mobile app.
 *
 * The app obtains an id token from the Google / Apple SDK and posts it here.
 * No browser redirect, no Better Auth callback.
 */
@ApiTags('OAuth')
@Controller('auth/oauth')
@SkipPermissions()
// Auth-grade: same 5/min budget as login, keyed by IP (public route).
@Throttle(namedThrottle({ ttl: 60000, limit: 5 }))
export class SocialSignInController {
  constructor(private readonly socialSignIn: SocialSignInService) {}

  @Public()
  @Post(':provider/token')
  @ApiOperation({
    summary: 'Iniciar sesión con un id token nativo de Google o Apple',
    description:
      'La app obtiene el idToken con el SDK nativo y lo envía junto con el nonce. ' +
      'El backend verifica firma, emisor, audiencia, expiración y nonce; crea o vincula ' +
      'el usuario; y devuelve el JWT de SACDIA. Misma respuesta que el antiguo /auth/oauth/callback.',
  })
  @ApiParam({ name: 'provider', enum: [...SOCIAL_PROVIDERS] })
  @ApiResponse({
    status: 201,
    description: 'Sesión creada',
    schema: {
      example: {
        accessToken: 'eyJhbGc...',
        sessionToken: 'opaque_session_token',
        refreshToken: 'opaque_session_token',
        expiresAt: 1900000000,
        tokenType: 'bearer',
        user: {
          id: 'uuid-123',
          email: 'user@gmail.com',
          name: 'Juan',
          paternal_last_name: 'Pérez',
          maternal_last_name: null,
          avatar: 'https://r2.sacdia.app/profiles/...',
          connectedProviders: ['google'],
        },
        needsPostRegistration: true,
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Proveedor inválido' })
  @ApiResponse({ status: 401, description: 'Token inválido o correo no verificado' })
  @ApiResponse({ status: 503, description: 'JWKS del proveedor no disponible' })
  async signIn(
    @Param('provider') provider: string,
    @Body() dto: SocialTokenSignInDto,
  ) {
    if (!isSocialProvider(provider)) {
      throw new AppBadRequestException(ErrorCode.AUTH_OAUTH_PROVIDER_INVALID, {
        provider,
        valid: SOCIAL_PROVIDERS.join(', '),
      });
    }
    return this.socialSignIn.signIn(provider, dto);
  }
}
```

- [ ] **Step 4: Wire resolver, service and controller into the module**

In `src/auth/social-sign-in/social-sign-in.module.ts`:

- add imports:
  ```ts
  import { BetterAuthModule } from '../../better-auth/better-auth.module';
  import { SocialAccountResolver } from './social-account.resolver';
  import { SocialSignInController } from './social-sign-in.controller';
  import { SocialSignInService } from './social-sign-in.service';
  ```
- change the decorator to:
  ```ts
  @Module({
    imports: [BetterAuthModule],
    controllers: [SocialSignInController],
    providers: [
      /* the two verifier factories stay as they are */
      AppleTokenClient,
      SocialAccountResolver,
      SocialSignInService,
    ],
    exports: [GOOGLE_ID_TOKEN_VERIFIER, APPLE_ID_TOKEN_VERIFIER, AppleTokenClient],
  })
  ```

- [ ] **Step 5: Run the unit suite for auth**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 && corepack pnpm exec jest src/auth src/better-auth && corepack pnpm exec tsc --noEmit -p tsconfig.build.json
```
Expected: all green, 3 new controller tests.

- [ ] **Step 6: Write the e2e spec**

`test/social-sign-in.e2e-spec.ts` (same bootstrap style as `test/auth.e2e-spec.ts`; verifiers and Apple client are replaced by fakes, Prisma is spied):

```ts
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AppleTokenClient } from '../src/auth/social-sign-in/apple-token.client';
import {
  APPLE_ID_TOKEN_VERIFIER,
  GOOGLE_ID_TOKEN_VERIFIER,
} from '../src/auth/social-sign-in/social-sign-in.types';
import { BetterAuthService } from '../src/better-auth/better-auth.service';
import { AppUnauthorizedException } from '../src/common/errors/app.exception';
import { ErrorCode } from '../src/common/errors/error-codes';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Social sign-in E2E', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const googleVerifier = { provider: 'google', verify: jest.fn() };
  const appleVerifier = { provider: 'apple', verify: jest.fn() };
  const appleTokens = { exchangeCode: jest.fn(), revoke: jest.fn() };
  const betterAuth = {
    createSession: jest.fn().mockResolvedValue({
      id: 'sess-1',
      token: 'opaque-token',
      expiresAt: new Date(1_900_000_000_000),
    }),
    signJwt: jest.fn().mockReturnValue('fake-jwt'),
  };

  const dbUser = {
    user_id: 'user-1',
    email: 'ana@example.com',
    name: 'Ana',
    paternal_last_name: null,
    maternal_last_name: null,
    user_image: null,
    email_verified: true,
    active: true,
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(BetterAuthService).useValue(betterAuth)
      .overrideProvider(GOOGLE_ID_TOKEN_VERIFIER).useValue(googleVerifier)
      .overrideProvider(APPLE_ID_TOKEN_VERIFIER).useValue(appleVerifier)
      .overrideProvider(AppleTokenClient).useValue(appleTokens)
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    app.setGlobalPrefix('api/v1');
    prisma = app.get(PrismaService);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    jest.clearAllMocks();
    jest
      .spyOn(prisma, '$transaction')
      .mockImplementation(((fn: (tx: PrismaService) => Promise<unknown>) =>
        fn(prisma)) as never);
    jest.spyOn(prisma.account, 'findUnique').mockResolvedValue(null);
    jest.spyOn(prisma.account, 'create').mockResolvedValue({} as never);
    jest.spyOn(prisma.account, 'findMany').mockResolvedValue([{ providerId: 'google' }] as never);
    jest.spyOn(prisma.users, 'findUnique').mockResolvedValue(dbUser as never);
    jest.spyOn(prisma.users, 'create').mockResolvedValue(dbUser as never);
    jest.spyOn(prisma.users, 'update').mockResolvedValue(dbUser as never);
    jest.spyOn(prisma.users_pr, 'findUnique').mockResolvedValue({ complete: false } as never);
    jest.spyOn(prisma.users_pr, 'create').mockResolvedValue({} as never);
    jest.spyOn(prisma.users_roles, 'findFirst').mockResolvedValue({} as never);
  });

  const post = (provider: string, body: object) =>
    request(app.getHttpServer()).post(`/api/v1/auth/oauth/${provider}/token`).send(body);

  it('returns 201 with the session payload for a valid Google token', async () => {
    googleVerifier.verify.mockResolvedValue({
      provider: 'google', sub: 'g-1', email: 'ana@example.com', emailVerified: true,
    });

    const res = await post('google', { idToken: 'id-token', nonce: 'nonce-1' });

    expect(res.status).toBe(201);
    // Success responses are wrapped by the global interceptor: { status, data }.
    expect(res.body.status).toBe('success');
    expect(res.body.data).toMatchObject({
      accessToken: 'fake-jwt',
      sessionToken: 'opaque-token',
      refreshToken: 'opaque-token',
      expiresAt: 1_900_000_000,
      tokenType: 'bearer',
      user: { id: 'user-1', email: 'ana@example.com', connectedProviders: ['google'] },
      needsPostRegistration: true,
    });
    expect(googleVerifier.verify).toHaveBeenCalledWith('id-token', 'nonce-1');
  });

  it('returns 401 AUTH_INVALID_TOKEN when the verifier rejects', async () => {
    googleVerifier.verify.mockRejectedValue(
      new AppUnauthorizedException(ErrorCode.AUTH_INVALID_TOKEN),
    );
    const res = await post('google', { idToken: 'bad', nonce: 'nonce-1' });
    expect(res.status).toBe(401);
    expect(res.body.code).toBe(ErrorCode.AUTH_INVALID_TOKEN);
  });

  it('returns 401 AUTH_OAUTH_EMAIL_UNVERIFIED for an unverified email', async () => {
    appleVerifier.verify.mockResolvedValue({
      provider: 'apple', sub: 'a-1', email: 'x@privaterelay.appleid.com', emailVerified: false,
    });
    const res = await post('apple', { idToken: 'id-token', nonce: 'nonce-1' });
    expect(res.status).toBe(401);
    expect(res.body.code).toBe(ErrorCode.AUTH_OAUTH_EMAIL_UNVERIFIED);
  });

  it('returns 400 for an unknown provider', async () => {
    const res = await post('facebook', { idToken: 'id-token', nonce: 'nonce-1' });
    expect(res.status).toBe(400);
    expect(res.body.code).toBe(ErrorCode.AUTH_OAUTH_PROVIDER_INVALID);
  });

  it('returns 400 when idToken or nonce is missing', async () => {
    const res = await post('google', { idToken: 'id-token' });
    expect(res.status).toBe(400);
    expect(googleVerifier.verify).not.toHaveBeenCalled();
  });
});
```

The controller throttle is 5/min per IP; this file sends exactly 5 requests. Add a 6th only after raising the limit for tests or splitting the file.

- [ ] **Step 7: Run the e2e file**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 && corepack pnpm exec jest --config ./test/jest-e2e.json test/social-sign-in.e2e-spec.ts
```
Expected: 5 tests pass. (Needs the same env the other e2e files need — see `test/setup.ts` and CI's `backend_e2e_tests` job; locally export `DATABASE_URL` to any reachable Postgres, the spec never queries it.)

- [ ] **Step 8: Lint, commit, push, open PR B2**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b2 && corepack pnpm exec eslint src/auth/social-sign-in test/social-sign-in.e2e-spec.ts && corepack pnpm exec prettier --check "src/auth/social-sign-in/**/*.ts" test/social-sign-in.e2e-spec.ts && git add src/auth/social-sign-in test/social-sign-in.e2e-spec.ts && git commit -m "feat(auth): add POST /auth/oauth/:provider/token for native social sign-in" && git push -u origin feat/social-sign-in-endpoint && gh pr create -R abn-r/sacdia-backend --base development --head feat/social-sign-in-endpoint --title "feat(auth): native Google/Apple sign-in endpoint (social sign-in B2)" --label "type:feature" --body "## Summary
- \`POST /api/v1/auth/oauth/:provider/token\` — verifies a native \`idToken\` + nonce, creates or links the user (spec D2/D3), stores the Apple refresh token, returns the same payload as the old \`/auth/oauth/callback\`.
- \`SocialAccountResolver\` owns the users/accounts writes in one transaction; Better Auth is not involved.
- \`BetterAuthService.createSession\` is now public.

Depends on B1. Old endpoints untouched (removed in B4).

## Test plan
- [x] \`jest src/auth src/better-auth\`
- [x] \`jest --config ./test/jest-e2e.json test/social-sign-in.e2e-spec.ts\`
- [x] tsc, eslint, prettier
- [ ] CI green
- [ ] After deploy with \`GOOGLE_OAUTH_AUDIENCES\` and \`APPLE_BUNDLE_ID\` set on Render: a real token from the app (A1) returns 201"
```

---

## Slice B3 — account deletion

Fresh worktree from `origin/development` after B2 merged: branch `feat/social-sign-in-account-deletion`, dir `backend-social-b3`.

### Task 10: `DELETE /auth/me` with id-token re-auth and Apple revoke

**Files:**
- Modify: `src/auth/dto/delete-account.dto.ts`
- Modify: `src/auth/account-deletion.service.ts:46-111`
- Modify: `src/auth/auth.controller.ts:430-450`
- Test: `src/auth/account-deletion.service.spec.ts`

- [ ] **Step 1: Replace the DTO**

`src/auth/dto/delete-account.dto.ts`:

```ts
import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsIn,
  IsNotEmpty,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { SOCIAL_PROVIDERS } from '../social-sign-in/social-sign-in.types';

/**
 * Re-authentication before the destructive action: either the current
 * password, or a fresh id token from a provider linked to the account
 * (users who signed up with Google/Apple have no password).
 */
export class DeleteAccountDto {
  @ApiPropertyOptional({
    description: 'Contraseña actual. Requerida cuando no se envía provider/idToken.',
    example: 'MyPassword123!',
  })
  @ValidateIf((o: DeleteAccountDto) => !o.provider)
  @IsString()
  @IsNotEmpty({ message: 'La contraseña es requerida para confirmar la eliminación' })
  password?: string;

  @ApiPropertyOptional({ enum: [...SOCIAL_PROVIDERS] })
  @ValidateIf((o: DeleteAccountDto) => !o.password)
  @IsIn([...SOCIAL_PROVIDERS])
  provider?: (typeof SOCIAL_PROVIDERS)[number];

  @ApiPropertyOptional({ description: 'Id token recién emitido por el proveedor' })
  @ValidateIf((o: DeleteAccountDto) => !o.password)
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  idToken?: string;

  @ApiPropertyOptional({ description: 'Nonce en claro usado para ese id token' })
  @ValidateIf((o: DeleteAccountDto) => !o.password)
  @IsString()
  @IsNotEmpty()
  @MaxLength(256)
  nonce?: string;
}
```

- [ ] **Step 2: Add the failing tests**

Append to `src/auth/account-deletion.service.spec.ts`. The module setup must now also provide the two verifiers and `AppleTokenClient`; update the existing `beforeEach` providers array to:

```ts
      providers: [
        AccountDeletionService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: FILE_STORAGE_SERVICE, useValue: mockFileStorage },
        { provide: EmailService, useValue: mockEmailService },
        { provide: GOOGLE_ID_TOKEN_VERIFIER, useValue: mockGoogleVerifier },
        { provide: APPLE_ID_TOKEN_VERIFIER, useValue: mockAppleVerifier },
        { provide: AppleTokenClient, useValue: mockAppleTokens },
      ],
```

with these additions near the other mocks:

```ts
import { AppleTokenClient } from './social-sign-in/apple-token.client';
import {
  APPLE_ID_TOKEN_VERIFIER,
  GOOGLE_ID_TOKEN_VERIFIER,
} from './social-sign-in/social-sign-in.types';

const mockGoogleVerifier = { provider: 'google', verify: jest.fn() };
const mockAppleVerifier = { provider: 'apple', verify: jest.fn() };
const mockAppleTokens = { revoke: jest.fn() };
```

`mockPrisma.account` needs `findMany: jest.fn()` next to `findFirst`. Existing tests that call `service.deleteAccount(USER_ID, PASSWORD, ...)` change to `service.deleteAccount(USER_ID, { password: PASSWORD }, ...)`, and their `mockPrisma.account.findFirst` setups become `mockPrisma.account.findMany.mockResolvedValue([{ providerId: 'credential', accountId: USER_ID, password: HASHED, refreshToken: null }])`. The existing "OAuth-only user skips password re-auth" test is deleted (that path no longer exists).

New tests:

```ts
  describe('re-authentication with a provider id token', () => {
    const activeUser = { user_id: USER_ID, email: 'ana@example.com', active: true, user_image: null };

    it('deletes when the id token belongs to a linked account', async () => {
      mockPrisma.users.findUnique.mockResolvedValue(activeUser);
      mockPrisma.account.findMany.mockResolvedValue([
        { providerId: 'google', accountId: 'g-1', password: null, refreshToken: null },
      ]);
      mockGoogleVerifier.verify.mockResolvedValue({ provider: 'google', sub: 'g-1', email: 'ana@example.com', emailVerified: true });

      await expect(
        service.deleteAccount(USER_ID, { provider: 'google', idToken: 't', nonce: 'n' }, '1.1.1.1'),
      ).resolves.toBeUndefined();

      expect(mockGoogleVerifier.verify).toHaveBeenCalledWith('t', 'n');
      expect(mockPrisma.users.update).toHaveBeenCalled();
    });

    it('rejects an id token for a different subject', async () => {
      mockPrisma.users.findUnique.mockResolvedValue(activeUser);
      mockPrisma.account.findMany.mockResolvedValue([
        { providerId: 'google', accountId: 'g-1', password: null, refreshToken: null },
      ]);
      mockGoogleVerifier.verify.mockResolvedValue({ provider: 'google', sub: 'someone-else', email: 'x@example.com', emailVerified: true });

      await expect(
        service.deleteAccount(USER_ID, { provider: 'google', idToken: 't', nonce: 'n' }),
      ).rejects.toMatchObject({ code: ErrorCode.AUTH_INVALID_TOKEN });
      expect(mockPrisma.users.update).not.toHaveBeenCalled();
    });

    it('rejects a provider that is not linked to the account', async () => {
      mockPrisma.users.findUnique.mockResolvedValue(activeUser);
      mockPrisma.account.findMany.mockResolvedValue([
        { providerId: 'credential', accountId: USER_ID, password: HASHED, refreshToken: null },
      ]);
      mockAppleVerifier.verify.mockResolvedValue({ provider: 'apple', sub: 'a-1', email: 'ana@example.com', emailVerified: true });

      await expect(
        service.deleteAccount(USER_ID, { provider: 'apple', idToken: 't', nonce: 'n' }),
      ).rejects.toMatchObject({ code: ErrorCode.AUTH_INVALID_TOKEN });
    });

    it('rejects a password re-auth when the account has no password', async () => {
      mockPrisma.users.findUnique.mockResolvedValue(activeUser);
      mockPrisma.account.findMany.mockResolvedValue([
        { providerId: 'google', accountId: 'g-1', password: null, refreshToken: null },
      ]);

      await expect(
        service.deleteAccount(USER_ID, { password: PASSWORD }),
      ).rejects.toMatchObject({ code: ErrorCode.AUTH_INVALID_PASSWORD });
    });
  });

  describe('Apple token revocation', () => {
    const activeUser = { user_id: USER_ID, email: 'ana@example.com', active: true, user_image: null };

    beforeEach(() => {
      mockPrisma.users.findUnique.mockResolvedValue(activeUser);
      mockPrisma.account.findMany.mockResolvedValue([
        { providerId: 'apple', accountId: 'a-1', password: null, refreshToken: 'rt-1' },
      ]);
      mockAppleVerifier.verify.mockResolvedValue({ provider: 'apple', sub: 'a-1', email: 'ana@example.com', emailVerified: true });
    });

    it('revokes the Apple refresh token before deleting', async () => {
      mockAppleTokens.revoke.mockResolvedValue(undefined);
      await service.deleteAccount(USER_ID, { provider: 'apple', idToken: 't', nonce: 'n' });
      expect(mockAppleTokens.revoke).toHaveBeenCalledWith('rt-1');
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('still deletes when the revoke fails', async () => {
      mockAppleTokens.revoke.mockRejectedValue(new Error('Apple token endpoint 400'));
      await expect(
        service.deleteAccount(USER_ID, { provider: 'apple', idToken: 't', nonce: 'n' }),
      ).resolves.toBeUndefined();
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });
  });
```

- [ ] **Step 3: Run to verify they fail**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b3 && corepack pnpm exec jest src/auth/account-deletion.service.spec.ts
```
Expected: FAIL (type errors on the new signature / missing providers).

- [ ] **Step 4: Implement in the service**

In `src/auth/account-deletion.service.ts`:

Add imports after the `ErrorCode` import:

```ts
import { AppleTokenClient } from './social-sign-in/apple-token.client';
import {
  APPLE_ID_TOKEN_VERIFIER,
  GOOGLE_ID_TOKEN_VERIFIER,
  type IdTokenVerifier,
  type SocialProvider,
} from './social-sign-in/social-sign-in.types';

export type DeleteAccountReauth =
  | { password: string }
  | { provider: SocialProvider; idToken: string; nonce: string };
```

Replace the constructor with:

```ts
  private readonly verifiers: Record<SocialProvider, IdTokenVerifier>;

  constructor(
    private readonly prisma: PrismaService,
    @Inject(FILE_STORAGE_SERVICE)
    private readonly fileStorage: FileStorageService,
    private readonly emailService: EmailService,
    @Inject(GOOGLE_ID_TOKEN_VERIFIER) google: IdTokenVerifier,
    @Inject(APPLE_ID_TOKEN_VERIFIER) apple: IdTokenVerifier,
    private readonly appleTokens: AppleTokenClient,
  ) {
    this.verifiers = { google, apple };
  }
```

Replace the signature and the whole "1. Load user and credential account" block (from `async deleteAccount(` through the closing `}` of the `else { ... bcrypt.compare ... }` branch) with:

```ts
  /**
   * Delete the account for the given userId after re-authenticating.
   *
   * @param userId - The user_id of the authenticated caller (from JWT sub)
   * @param reauth - Current password, or a fresh provider id token + nonce
   * @param ipAddress - Caller IP for audit log (optional)
   */
  async deleteAccount(
    userId: string,
    reauth: DeleteAccountReauth,
    ipAddress?: string,
  ): Promise<void> {
    // -------------------------------------------------------------------------
    // 1. Load user and linked accounts, re-authenticate
    // -------------------------------------------------------------------------
    const user = await this.prisma.users.findUnique({
      where: { user_id: userId },
      select: {
        user_id: true,
        email: true,
        active: true,
        user_image: true,
      },
    });

    if (!user) {
      throw new AppNotFoundException(ErrorCode.AUTH_ACCOUNT_NOT_FOUND, {
        userId,
      });
    }

    if (!user.active) {
      throw new AppBadRequestException(ErrorCode.AUTH_ACCOUNT_ALREADY_DELETED, {
        userId,
      });
    }

    const accounts = await this.prisma.account.findMany({
      where: { userId },
      select: {
        providerId: true,
        accountId: true,
        password: true,
        refreshToken: true,
      },
    });

    if ('password' in reauth) {
      const credential = accounts.find((a) => a.providerId === 'credential');
      if (!credential?.password) {
        // Social-only account: the client must re-auth with the provider.
        throw new AppUnauthorizedException(ErrorCode.AUTH_INVALID_PASSWORD);
      }
      const isPasswordValid = await bcrypt.compare(
        reauth.password,
        credential.password,
      );
      if (!isPasswordValid) {
        throw new AppUnauthorizedException(ErrorCode.AUTH_INVALID_PASSWORD);
      }
    } else {
      const identity = await this.verifiers[reauth.provider].verify(
        reauth.idToken,
        reauth.nonce,
      );
      const linked = accounts.some(
        (a) => a.providerId === reauth.provider && a.accountId === identity.sub,
      );
      if (!linked) {
        this.logger.warn(
          `Account deletion re-auth rejected for ${userId} — ${reauth.provider} token belongs to another subject`,
        );
        throw new AppUnauthorizedException(ErrorCode.AUTH_INVALID_TOKEN);
      }
    }

    // -------------------------------------------------------------------------
    // 1b. Revoke Sign in with Apple (App Store 5.1.1(v)). Best effort: a
    //     failure is logged and the deletion continues.
    // -------------------------------------------------------------------------
    const apple = accounts.find((a) => a.providerId === 'apple');
    if (apple?.refreshToken) {
      try {
        await this.appleTokens.revoke(apple.refreshToken);
      } catch (error) {
        this.logger.warn(
          `Apple token revoke failed for ${userId}: ${error instanceof Error ? error.message : String(error)}`,
        );
      }
    } else if (apple) {
      this.logger.warn(
        `Apple account for ${userId} has no refresh token — skipping revoke`,
      );
    }
```

Update the class doc comment line `1. Re-authenticate: verify current password against credential account` to `1. Re-authenticate: current password, or a fresh provider id token for a linked account; revoke the Apple refresh token when present`.

- [ ] **Step 5: Update the controller call**

In `src/auth/auth.controller.ts`, replace

```ts
    await this.accountDeletionService.deleteAccount(
      user.userId,
      dto.password,
      ip,
    );
```

with

```ts
    await this.accountDeletionService.deleteAccount(
      user.userId,
      dto.password !== undefined
        ? { password: dto.password }
        : { provider: dto.provider!, idToken: dto.idToken!, nonce: dto.nonce! },
      ip,
    );
```

and the `@ApiOperation` description `'Elimina de forma permanente la cuenta. Requiere contraseña actual para confirmación. '` with `'Elimina de forma permanente la cuenta. Requiere la contraseña actual o un id token reciente de Google/Apple vinculado a la cuenta. '`.

- [ ] **Step 6: Run tests, typecheck, lint, commit, PR B3**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b3 && corepack pnpm exec jest src/auth && corepack pnpm exec tsc --noEmit -p tsconfig.build.json && corepack pnpm exec eslint src/auth && corepack pnpm exec prettier --check "src/auth/**/*.ts" && git add src/auth && git commit -m "feat(auth): accept a provider id token to delete the account and revoke Apple tokens" && git push -u origin feat/social-sign-in-account-deletion && gh pr create -R abn-r/sacdia-backend --base development --head feat/social-sign-in-account-deletion --title "feat(auth): social re-auth and Apple revoke on account deletion (B3)" --label "type:feature" --body "## Summary
- \`DELETE /auth/me\` accepts \`{ password }\` or \`{ provider, idToken, nonce }\`. The token must belong to a provider linked to the caller.
- Social-only accounts can no longer skip re-auth; before this they were deleted on the JWT alone.
- Apple refresh token is revoked before deletion (best effort, logged).

## Test plan
- [x] \`jest src/auth\`, tsc, eslint, prettier
- [ ] CI green
- [ ] App A2 deletes a Google-only and an Apple-only test account on Render"
```

Also run `corepack pnpm exec jest --config ./test/jest-e2e.json test/auth.e2e-spec.ts` — if it has a `DELETE /auth/me` case sending `{ password }`, it must still pass unchanged.

---

## Slice B4 — retire the Better Auth OAuth flow

Fresh worktree from `origin/development` after B2 merged (B3 is independent): branch `refactor/remove-better-auth-oauth`, dir `backend-social-b4`.

### Task 11: Remove the browser flow

**Files:**
- Modify: `src/auth/oauth.controller.ts`, `src/auth/oauth.controller.spec.ts`
- Modify: `src/auth/oauth.service.ts`, `src/auth/oauth.service.spec.ts`
- Delete: `src/auth/dto/oauth-initiate.dto.ts`, `src/auth/dto/oauth-callback.dto.ts`, `src/auth/oauth-redirect-allowlist.ts`, `src/auth/oauth-redirect-allowlist.spec.ts`
- Modify: `src/better-auth/better-auth.service.ts`, `src/better-auth/better-auth.service.spec.ts`
- Modify: `src/better-auth/better-auth.config.ts`
- Modify: `src/config/env.validation.ts`, `test/helpers/annual-cycle-db.helper.ts:101-103`, `test/auth.e2e-spec.ts:43-52`

- [ ] **Step 1: Controller** — delete the methods `googleSignIn`, `appleSignIn` and `handleCallback` with their decorators, the imports of `OAuthInitiateDto`, `OAuthCallbackDto`, `Body` and `Post`, and the "## OAuth flow (browser-facing BA callback)" part of the class doc comment. Replace it with:

```ts
/**
 * OAuthController — connected providers.
 *
 * Sign-in lives in SocialSignInController (`POST /auth/oauth/:provider/token`).
 * This controller only lists and unlinks providers for the authenticated user.
 */
```

- [ ] **Step 2: Controller spec** — delete `mockOAuthService.initiateGoogleSignIn`, `initiateAppleSignIn`, `handleCallback` and the three `it('should delegate … sign-in …')` / `it('should delegate OAuth callback …')` tests.

- [ ] **Step 3: Service** — delete `validateRedirectUrl`, `initiateGoogleSignIn`, `initiateAppleSignIn`, `handleCallback`, `ensureSacdiaUserProvisioned`, `resolvePrivateProfilePicture`, the `PRIVATE_ASSET_URL_TTL_SECONDS` constant, the `BetterAuthService` and `FILE_STORAGE_SERVICE` constructor params and their imports, the `OAuthCallbackDto` and `oauth-redirect-allowlist` imports, and `AppBadRequestException` only if unused (it is still used by `disconnectProvider` — keep it). Replace the class doc comment with:

```ts
/**
 * Connected OAuth providers (`accounts` table).
 *
 * Sign-in is handled by SocialSignInService. This service only reads and
 * removes provider links for an authenticated user.
 */
```

- [ ] **Step 4: Service spec** — delete `mockTx`, `mockBetterAuthService`, `mockFileStorageService`, the `$transaction` setup, the providers for `BetterAuthService` and `FILE_STORAGE_SERVICE`, and the describes `initiateGoogleSignIn`, `initiateAppleSignIn`, `handleCallback`. Keep `getConnectedProviders` and `disconnectProvider`.

- [ ] **Step 5: BetterAuthService** — delete `getOAuthUrl`, `handleOAuthCallback`, `describeOAuthError`, `BaOAuthUrlResult`, the `// -- OAuth` block of `IBetterAuthService`, and the `@Inject('BETTER_AUTH_INSTANCE') private readonly ba` constructor parameter together with the `BetterAuthInstance` type import. In `better-auth.service.spec.ts` delete `mockBaInstance`, remove it from every `new BetterAuthService(...)` call (the constructor now takes `jwtService, prisma, emailService`), and delete the `describe('OAuth error logging', …)` block.

- [ ] **Step 6: Better Auth config** — in `better-auth.config.ts` delete the `twoFactor` import and the `plugins: [twoFactor()]`, `socialProviders: { … }` and `trustedOrigins: resolveBetterAuthTrustedOrigins(),` entries plus the `resolveBetterAuthTrustedOrigins` import. Keep `validateSchema: false` (the instance is still created and still used by nothing at runtime; removing Better Auth entirely is out of scope). Update the header comment: the instance is kept only until Better Auth is removed from the backend; OAuth and TOTP are SACDIA code. `better-auth.config.spec.ts` keeps passing.

- [ ] **Step 7: Module** — `BetterAuthModule` keeps the `'BETTER_AUTH_INSTANCE'` provider but it no longer needs to be injected into the service; leave the provider so the module shape is unchanged for other importers.

- [ ] **Step 8: Env** — in `env.validation.ts` delete `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `APPLE_CLIENT_ID`, `ALLOWED_OAUTH_REDIRECT_URLS` and the "(Better Auth browser flow — removed in B4)" comment. In `test/helpers/annual-cycle-db.helper.ts` replace the three `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` / `APPLE_CLIENT_ID` lines with:

```ts
  process.env.GOOGLE_OAUTH_AUDIENCES ??= 'test-google-client-id';
  process.env.APPLE_BUNDLE_ID ??= 'test.apple.client';
```

In `test/auth.e2e-spec.ts` delete the `getOAuthUrl` and `handleOAuthCallback` entries of `mockBetterAuthService`.

- [ ] **Step 9: Delete the files**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b4 && git rm src/auth/dto/oauth-initiate.dto.ts src/auth/dto/oauth-callback.dto.ts src/auth/oauth-redirect-allowlist.ts src/auth/oauth-redirect-allowlist.spec.ts
```

- [ ] **Step 10: Verify nothing references the removed symbols**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b4 && rg -n "getOAuthUrl|handleOAuthCallback|initiateGoogleSignIn|initiateAppleSignIn|handleCallback\(|OAuthInitiateDto|OAuthCallbackDto|oauth-redirect-allowlist|resolveBetterAuthTrustedOrigins|GOOGLE_CLIENT_SECRET|APPLE_CLIENT_ID|ALLOWED_OAUTH_REDIRECT_URLS|BaOAuthUrlResult" src test
```
Expected: no output.

- [ ] **Step 11: Full verification, commit, PR B4**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/backend-social-b4 && corepack pnpm exec tsc --noEmit -p tsconfig.build.json && corepack pnpm exec jest && corepack pnpm exec eslint "src/**/*.ts" "test/**/*.ts" && corepack pnpm exec prettier --check "src/**/*.ts" "test/**/*.ts" && git add -A src test && git commit -m "refactor(auth): remove the Better Auth browser OAuth flow" -m "Sign-in now goes through POST /auth/oauth/:provider/token with native id tokens. The old initiate/callback endpoints never worked after W3-008 (no handler mounted, localhost base URL), and the app's GET calls already returned 404, so no client loses a working path." && git push -u origin refactor/remove-better-auth-oauth && gh pr create -R abn-r/sacdia-backend --base development --head refactor/remove-better-auth-oauth --title "refactor(auth): remove the Better Auth browser OAuth flow (B4)" --label "type:refactor" --body "## Summary
- Removes \`POST /auth/oauth/google\`, \`/apple\`, \`/callback\`, the redirect allowlist, \`getOAuthUrl\`/\`handleOAuthCallback\`, and \`socialProviders\`/\`twoFactor\`/\`trustedOrigins\` from the Better Auth config.
- Drops \`GOOGLE_CLIENT_ID\`, \`GOOGLE_CLIENT_SECRET\`, \`APPLE_CLIENT_ID\`, \`ALLOWED_OAUTH_REDIRECT_URLS\` from env validation (safe to delete on Render after merge).
- \`GET /auth/oauth/providers\` and \`DELETE /auth/oauth/:provider\` unchanged.

## Test plan
- [x] full \`jest\`, tsc, eslint, prettier
- [ ] CI green
- [ ] After deploy: \`POST /api/v1/auth/oauth/google\` returns 404; \`POST /api/v1/auth/oauth/google/token\` with \`{}\` returns 400"
```

---

## Slice D1 — docs (workspace root `sacdia`)

Worktree: branch `docs/native-social-sign-in-api`, dir `/Users/abner/Documents/development/sacdia-worktrees/root-social-docs`, from `origin/development`. Do not touch the root checkout working tree (another session edits it).

### Task 12: Endpoint reference and console setup guide

**Files:**
- Modify: `docs/api/ENDPOINTS-LIVE-REFERENCE.md:662-666`
- Create: `docs/guides/SOCIAL-SIGN-IN-SETUP.md`
- Modify: `docs/guides/README.md` (add a link; this file is also modified in the root checkout — only add the row, in the worktree)

- [ ] **Step 1: Replace the three OAuth rows**

Replace the rows for `POST /api/v1/auth/oauth/google`, `/apple` and `/callback` with:

```markdown
| POST | `/api/v1/auth/oauth/:provider/token` | Public | - | Iniciar sesión con un id token nativo de Google o Apple | SocialSignInService.signIn() | `src/auth/social-sign-in/social-sign-in.controller.ts` |
```

Find the `DELETE /api/v1/auth/me` row and append to its description: ` (contraseña o `{ provider, idToken, nonce }`)`.

- [ ] **Step 2: Write the setup guide**

`docs/guides/SOCIAL-SIGN-IN-SETUP.md`:

```markdown
# Login con Google y Apple — configuración de consolas

Diseño: `docs/plans/2026-10-14-native-social-sign-in-design.md`. Este documento lista lo que se configura fuera del código (slice C1). Sin esto el endpoint responde 401 a todos los tokens.

## Google Cloud (APIs & Services → Credentials)

| Client ID | Para qué | Dónde va |
|---|---|---|
| iOS | SDK de Google en iPhone. Bundle ID de la app. | `GoogleService-Info.plist` / `Info.plist` (URL scheme invertida) |
| Android | SDK de Google en Android. Package name + SHA-1 de debug, release y Play App Signing. | Solo en la consola |
| Web | `serverClientId` de la app. Es la `aud` del `idToken`. | Render: `GOOGLE_OAUTH_AUDIENCES` (CSV; puede incluir también los client IDs iOS/Android) |

## Apple Developer

1. Identifiers → App ID de la app → capability **Sign in with Apple**.
2. Keys → nueva llave con **Sign in with Apple** habilitado → descargar el `.p8` (una sola vez) y anotar el Key ID.
3. Render:
   - `APPLE_BUNDLE_ID`: bundle ID de la app (es la `aud` del token y el `client_id` del endpoint de tokens).
   - `APPLE_TEAM_ID`, `APPLE_KEY_ID`.
   - `APPLE_PRIVATE_KEY`: contenido del `.p8`. Si Render guarda los saltos como `\n` literales, el backend los convierte.

## Xcode

- Signing & Capabilities → **Sign in with Apple** (actualiza `Runner.entitlements`).
- `Info.plist`: URL scheme del client ID iOS de Google (`com.googleusercontent.apps.…`).

## Verificación

1. `POST /api/v1/auth/oauth/google/token` con `{}` → 400 (DTO).
2. Desde la app en un iPhone: Google y Apple → 201 con `accessToken`.
3. Desde la app en Android: Google → 201.
4. Log de Render sin líneas `id token rejected`. Si aparece `aud` en una línea de rechazo, falta ese client ID en `GOOGLE_OAUTH_AUDIENCES`.
```

- [ ] **Step 3: Link it from the guides index**

In `docs/guides/README.md`, add a row/bullet (match the surrounding format) pointing to `SOCIAL-SIGN-IN-SETUP.md` with the text "Login con Google y Apple — configuración de consolas y variables".

- [ ] **Step 4: Commit and PR**

```bash
cd /Users/abner/Documents/development/sacdia-worktrees/root-social-docs && git add docs/api/ENDPOINTS-LIVE-REFERENCE.md docs/guides/SOCIAL-SIGN-IN-SETUP.md docs/guides/README.md && git commit -m "docs(auth): document the native social sign-in endpoint and console setup" && git push -u origin docs/native-social-sign-in-api && gh pr create -R abn-r/sacdia --base development --head docs/native-social-sign-in-api --title "docs(auth): native social sign-in endpoint and console setup" --label "type:docs" --body "Documents \`POST /auth/oauth/:provider/token\`, the \`DELETE /auth/me\` re-auth change, and the Google Cloud / Apple Developer / Xcode / Render setup (slice D1 of the native social sign-in design)."
```

---

## Risks and notes

- **`jose` in Jest.** Unit config transforms every `node_modules` ESM file (`transformIgnorePatterns: []`); the e2e config already allowlists `jose@`. If a spec fails with `Cannot use import statement outside a module`, the e2e allowlist regex in `test/jest-e2e.json` is the place to look.
- **Google nonce.** `GoogleIdTokenVerifier` requires the `nonce` claim. The app plan (A1) must pass the nonce to `google_sign_in` on both platforms; if a platform cannot, that is an app-side blocker to surface, not a reason to make the nonce optional.
- **Throttle in e2e.** `POST /auth/oauth/:provider/token` is 5/min per IP; `test/social-sign-in.e2e-spec.ts` sends exactly 5 requests.
- **Race on first sign-in.** Two concurrent first logins for the same email can hit the `users.email` unique index; the second request gets a 500 and succeeds on retry. Not handled (YAGNI).
- **Deleted users.** `AccountDeletionService` anonymises the email and deletes `accounts`, so a deleted user signing in again becomes a new user. Same as the password flow.
- **Render env.** B2 needs `GOOGLE_OAUTH_AUDIENCES` and `APPLE_BUNDLE_ID` set before A1 is tested; B4 lets `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `APPLE_CLIENT_ID`, `ALLOWED_OAUTH_REDIRECT_URLS` be deleted. The user changes Render settings in the dashboard.
- **Root `CLAUDE.md`** still says "OAuth: Google y Apple configurados vía Better Auth". It has uncommitted edits by the user; leave it and mention the stale line when D1 is reviewed.
