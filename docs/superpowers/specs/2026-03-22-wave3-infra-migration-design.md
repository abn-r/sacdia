# Wave 3: Infrastructure Migration (Supabase → Neon + Better Auth)

**Date**: 2026-03-22
**Status**: Approved — ready for implementation
**Version**: 4 (hard cutover + Option C: custom HS256 JWT)
**Driver**: Cost reduction from ~$55-75/mo to ~$19/mo (65-75% savings)
**Constraint**: All existing users are test users — hard cutover, no bridge period
**Spike Finding**: Better Auth emits opaque session tokens, NOT JWTs. SACDIA signs its own HS256 JWT.

---

## Table of Contents

1. [Intent](#intent)
2. [Scope](#scope)
3. [Architecture Decisions](#architecture-decisions)
4. [Schema Changes](#schema-changes)
5. [Behavioral Specification (22 Auth Endpoints)](#behavioral-specification)
6. [Data Flow Diagrams](#data-flow-diagrams)
7. [Flutter Migration](#flutter-migration)
8. [Cutover Sequence](#cutover-sequence)
9. [Task Breakdown (21 Tasks)](#task-breakdown)
10. [Environment Variables](#environment-variables)
11. [Risks](#risks)
12. [Success Criteria](#success-criteria)
13. [Cost Impact](#cost-impact)

---

## Intent

SACDIA runs three Supabase instances (dev, staging, prod) at ~$50-75/month. All current users are test users — the platform is pre-production. This migration replaces:

- **Supabase PostgreSQL** → **Neon** (serverless, auto-suspend, $19/mo prod, $0 dev/staging)
- **Supabase Auth** → **Better Auth** (MIT, self-hosted inside NestJS)

Because there are no real production users, this is a clean infrastructure swap — not a live migration. No compatibility bridges, no user communication plans, no data import scripts. Test users re-register on the new auth system.

Secondary drivers: full ownership of auth logic, alignment with NestJS+Prisma native patterns, elimination of Supabase SDK vendor lock-in from the mobile app.

---

## Scope

### In Scope

| Phase | Work | Duration |
|-------|------|----------|
| Spike | Verify Better Auth + Prisma `usePlural` + field mapping | 0.5 days |
| Phase 1 | Neon DB migration (env var swap, zero code changes) | 4-6 days |
| Phase 2a | Better Auth core + schema migration + service rewrites | 8-10 days |
| Phase 2b | OAuth console reconfiguration (Google/Apple) | 0.5 days |
| Phase 2c | Tests (unit + integration for 22 endpoints) | 3-4 days |
| Phase 2d | Flutter migration (remove supabase_flutter) | 4-5 days |
| Phase 3 | Cutover (deploy, decommission Supabase) | 2-3 days |
| Phase 4 | Cleanup + docs | 1-2 days |

### Out of Scope

- Dual-JWT bridge — not needed (no real sessions to preserve)
- Password migration — test users re-register
- MFA re-enrollment communication — test users re-enroll fresh
- UUID import script — unified table, no separate ba_user
- OAuth account backfill — test users re-link
- App Store/Play Store timing coordination — no production users
- RBAC changes — FK chain unbroken, zero migration needed
- Firebase FCM — already decoupled
- Cloudflare R2 storage — already decoupled

---

## Architecture Decisions

### Decision 1: Neon Connection Strategy — Pooled + Unpooled

Two connection strings per environment. Pooled (pgBouncer) for runtime; unpooled (direct) for migrations.

```prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")        // pooled — runtime
  directUrl = env("DATABASE_DIRECT_URL") // unpooled — migrations
}
```

### Decision 2: Unified Users Table (Option A)

Better Auth uses SACDIA's existing `users` table — NO separate `ba_user` table. Field mapping via Prisma adapter:

```typescript
export const auth = betterAuth({
  database: prismaAdapter(prisma, {
    provider: "postgresql",
    usePlural: true,
  }),
  user: {
    modelName: "users",
    fields: {
      id: "user_id",
      image: "user_image",
      createdAt: "created_at",
      updatedAt: "modified_at",
    },
  },
  plugins: [totp(), openAPI()],
  emailAndPassword: { enabled: true },
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    },
    apple: {
      clientId: process.env.APPLE_CLIENT_ID!,
      teamId: process.env.APPLE_TEAM_ID!,
      keyId: process.env.APPLE_KEY_ID!,
      privateKey: process.env.APPLE_PRIVATE_KEY!,
    },
  },
  session: {
    expiresIn: 60 * 60 * 24 * 7,   // 7 days
    updateAge: 60 * 60 * 24,        // 1 day slide
    cookieCache: { enabled: false }, // Bearer tokens only
  },
  secret: process.env.BETTER_AUTH_SECRET,
  baseURL: process.env.BETTER_AUTH_BASE_URL,
});
```

**Key benefit**: 25+ tables with FK to `users.user_id` remain COMPLETELY UNTOUCHED.

### Decision 3: JwtStrategy — Option C (Custom HS256 JWT)

Better Auth emits **opaque session tokens** (32-byte random strings), NOT JWTs. SACDIA signs its own HS256 JWT after BA authentication. The JwtStrategy validates these SACDIA-signed JWTs:

**Flow**: BA login → opaque session → SACDIA signs HS256 JWT → client receives JWT
**Refresh**: Client sends BA opaque token → BA validates session → SACDIA signs new JWT
**Logout**: Revoke BA session FIRST → then blacklist JWT via TokenBlacklistService

```typescript
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private readonly tokenBlacklistService: TokenBlacklistService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      passReqToCallback: true,
      secretOrKey: configService.getOrThrow<string>('BETTER_AUTH_SECRET'),
      algorithms: ['HS256'],
    });
  }

  async validate(req: Request, payload: JwtPayload) {
    const token = this.extractToken(req);
    if (token && await this.tokenBlacklistService.isBlacklisted(token)) {
      throw new UnauthorizedException('revoked');
    }
    return { sub: payload.sub, userId: payload.sub, user_id: payload.sub, email: payload.email };
  }
}
```

### Decision 4: Schema — Additive + Immediate Column Drop

One migration adds `email_verified` + 3 new tables. A second drops the obsolete OAuth flag columns. No backfill needed — test data.

### Decision 5: RBAC — Unchanged

`users_roles`, `users_permissions`, `club_role_assignments` kept as-is. FK target is `users.user_id`. Better Auth writes to `users.user_id` directly. Zero RBAC migration.

### Decision 6: MfaService — Remove Session Binding

Current MfaService requires `bindSession(accessToken, refreshToken)` because Supabase MFA is session-scoped. Better Auth TOTP plugin operates by `userId` only. No more `x-refresh-token` header.

### Decision 7: Flutter — Remove supabase_flutter

Replace with `flutter_appauth` for OAuth and `flutter_secure_storage` for token persistence. All auth calls go through backend API.

---

## Schema Changes

### New column on `users`

```prisma
email_verified Boolean @default(false)
```

### Columns removed from `users`

```prisma
// DELETED:
apple_connected  Boolean @default(false)
fb_connected     Boolean @default(false)
google_connected Boolean @default(false)
```

### New tables (Better Auth core — no prefix)

```prisma
model session {
  id        String   @id
  expiresAt DateTime @map("expires_at")
  token     String   @unique
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)
  ipAddress String?  @map("ip_address")
  userAgent String?  @map("user_agent")
  userId    String   @map("user_id") @db.Uuid
  users     users    @relation(fields: [userId], references: [user_id], onDelete: Cascade)
}

model account {
  id                    String    @id
  accountId             String    @map("account_id")
  providerId            String    @map("provider_id")
  userId                String    @map("user_id") @db.Uuid
  accessToken           String?   @map("access_token") @db.Text
  refreshToken          String?   @map("refresh_token") @db.Text
  idToken               String?   @map("id_token") @db.Text
  accessTokenExpiresAt  DateTime? @map("access_token_expires_at") @db.Timestamptz(6)
  refreshTokenExpiresAt DateTime? @map("refresh_token_expires_at") @db.Timestamptz(6)
  scope                 String?
  password              String?
  createdAt             DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt             DateTime  @updatedAt @map("updated_at") @db.Timestamptz(6)
  users                 users     @relation(fields: [userId], references: [user_id], onDelete: Cascade)
  @@unique([providerId, accountId])
}

model verification {
  id         String    @id
  identifier String
  value      String
  expiresAt  DateTime  @map("expires_at") @db.Timestamptz(6)
  createdAt  DateTime? @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt  DateTime? @updatedAt @map("updated_at") @db.Timestamptz(6)
}
```

---

## Behavioral Specification

### Token Architecture (Option C — Custom HS256 JWT)

Better Auth emits **opaque session tokens** (32-byte random strings stored in `session` table). SACDIA signs its own HS256 JWT for API consumers.

- **access_token**: HS256 JWT signed by SACDIA with `BETTER_AUTH_SECRET` (min 32 chars)
  - Claims: `sub` (user UUID), `iat`, `exp`, `email`
  - Expiry: **1 hour**
- **refresh_token**: BA opaque session token (used to get new JWT)
  - Expiry: **7 days** (BA session expiry)
- Old Supabase ES256 tokens: **rejected with 401** (no fallback)

### Endpoint Specs (22 endpoints)

| Endpoint | Method | Success | Key Behavior |
|----------|--------|---------|--------------|
| `/auth/register` | POST | 201 | BA creates user → SACDIA signs HS256 JWT → returns `{access_token: JWT, refresh_token: BA_opaque}`. |
| `/auth/login` | POST | 200 | BA validates credentials → creates `session` row → SACDIA signs JWT. |
| `/auth/refresh` | POST | 200 | Client sends BA opaque token → BA validates session → SACDIA signs new JWT. |
| `/auth/logout` | POST | 200 | Revokes BA session FIRST → then blacklists JWT via TokenBlacklistService. |
| `/auth/logout-all` | POST | 200 | Deletes ALL user sessions. Blacklists all tokens. |
| `/auth/password-reset` | POST | 200 | Enumeration-safe (same response for unknown email). |
| `/auth/password-reset/confirm` | POST | 200 | Validates token, updates password, invalidates all sessions. |
| `/auth/password` | PATCH | 200 | Requires current password. Invalidates OTHER sessions. |
| `/auth/me` | GET | 200 | Returns user profile from `users` table. |
| `/auth/sessions` | GET | 200 | Returns active sessions from `session` table. |
| `/auth/sessions/:id` | DELETE | 200 | Verifies session belongs to user. 403 if not. |
| `/auth/oauth/google` | POST | 200 | Returns Google authorization URL with PKCE. |
| `/auth/oauth/apple` | POST | 200 | Returns Apple authorization URL. |
| `/auth/oauth/callback` | GET | 302 | Exchanges code, creates/links user + `account` row. |
| `/auth/mfa/enroll` | POST | 200 | Returns QR code + secret. userId from JWT (no session binding). |
| `/auth/mfa/verify` | POST | 200 | Verifies TOTP code. Activates factor. |
| `/auth/mfa/challenge` | POST | 200 | Creates challenge for factor verification. |
| `/auth/mfa/unenroll` | DELETE | 200 | Removes TOTP factor. |
| `/auth/mfa/factors` | GET | 200 | Lists enrolled factors. |
| `/auth/mfa/aal` | GET | 200 | Returns current AAL level (aal1/aal2). |
| `/auth/pr-check` | GET | 200 | Post-registration status check. |
| `/auth/approve` | POST | 200 | Admin-only user approval. |

### OAuth Account Linking

Better Auth's `account` table replaces the old boolean flags:
- `google_connected` → row in `account` where `providerId = 'google'`
- `apple_connected` → row in `account` where `providerId = 'apple'`
- Account linking by email: if user exists with same email, BA links the OAuth identity to existing `users` row

---

## Data Flow Diagrams

### Login Flow (Option C)

```
Client ──POST /auth/login──► AuthController
                               │
                               ▼
                           AuthService.login()
                               │
                    ┌──────────┴──────────────┐
                    ▼                         ▼
            BetterAuthService           PrismaService
           .signInWithPassword()       .users.findUnique()
              │ returns:                      │
              │ { user, session }              │
              │ (session.token = opaque)       │
                    └──────────┬──────────────┘
                               ▼
                    BetterAuthService.signJwt(user)
                       signs HS256 JWT: { sub: user.id, email }
                               ▼
                    return { access_token: JWT, refresh_token: session.token }
```

### OAuth Flow

```
Flutter ──GET /auth/oauth/google──► OAuthController
                                     │
                            BetterAuthService.getOAuthUrl()
                                     │
                    ◄── { url: "https://accounts.google.com/..." }

Flutter opens URL via flutter_appauth
         │
Google callback → /auth/oauth/callback?code=xxx
         │
   Better Auth: exchange code → find/create user → write account row → create session (opaque)
         │
   SACDIA signs HS256 JWT with user data
         │
   Redirect → sacdia-app://auth/callback?access_token=JWT&refresh_token=BA_opaque
         │
Flutter stores token in FlutterSecureStorage
```

### MFA Flow (No Session Binding)

```
POST /auth/mfa/enroll
  JwtAuthGuard → userId from JWT payload
  MfaService.enrollMfa(userId)
  BetterAuthService.enrollTotp(userId)
  ← { factorId, qrCode, secret, uri }

POST /auth/mfa/verify
  MfaService.verifyAndActivateMfa(userId, factorId, code)
  ← { verified: true }
```

---

## Flutter Migration

### Files deleted
- `lib/core/auth/supabase_auth.dart`
- `lib/core/constants/supabase_constants.dart`
- `lib/providers/supabase_provider.dart`

### Files created
- `lib/core/auth/app_auth_service.dart` — wraps `flutter_appauth` for OAuth, `flutter_secure_storage` for tokens

### Files modified
- `pubspec.yaml` — remove `supabase_flutter`, add `flutter_appauth`, `app_links`
- `lib/main.dart` — remove `SupabaseAuth.initialize()`
- `lib/features/auth/data/datasources/auth_remote_data_source.dart` — HTTP calls to `/api/v1/auth/*`

---

## Cutover Sequence

### Phase 1 — Neon (Days 1-6)

1. Provision 3 Neon projects (dev, staging, prod)
2. Add `directUrl` to `schema.prisma`
3. `prisma migrate deploy` against each environment (dev → staging → prod)
4. 48h monitoring on prod

### Phase 2 — Better Auth (Days 7-20)

1. Prisma migration: add `email_verified` + 3 BA tables
2. Install `better-auth`, create BetterAuthModule with field mapping
3. Implement BetterAuthService (14 methods)
4. Rewrite AuthService + MfaService + OAuthService
5. Rewrite JwtStrategy (HS256 only)
6. Register OAuth callback URLs in Google/Apple consoles
7. Unit tests + integration tests (22 endpoints)
8. Flutter: remove supabase_flutter, create AppAuthService
9. Submit Flutter app to stores

### Phase 3 — Cutover Day

1. Drop OAuth flag columns migration
2. Deploy sacdia-backend with Better Auth
3. Verify: register → login → /auth/me → OAuth → MFA
4. Remove `SUPABASE_*` env vars from prod
5. Pause all 3 Supabase projects (keep 30 days, then delete)
6. Monitor 24h

---

## Task Breakdown (21 Tasks)

| Task | Phase | Title | Effort | Depends On |
|------|-------|-------|--------|------------|
| W3-000 | Spike | Better Auth token format spike | S | — |
| W3-001 | 1 | Provision Neon + update schema.prisma | S | — |
| W3-002 | 1 | Migrate dev to Neon | S | W3-001 |
| W3-003 | 1 | Migrate staging to Neon | M | W3-002 |
| W3-004 | 1 | Migrate prod to Neon (48h) | M | W3-003 |
| W3-005 | 2a | Prisma migration: BA schema | S | W3-004, W3-000 |
| W3-006 | 2a | Install better-auth + BetterAuthModule | M | W3-005 |
| W3-007 | 2a | Implement BetterAuthService (14 methods) | M | W3-006 |
| W3-008 | 2a | Rewrite AuthService + MfaService + OAuthService | L | W3-007 |
| W3-009 | 2a | Simple HS256 JwtStrategy | S | W3-008 |
| W3-010 | 2b | Register OAuth callback URLs | S | W3-009 |
| W3-011 | 2c | Unit tests: BetterAuthService + JwtStrategy | M | W3-007, W3-009 |
| W3-012 | 2c | Integration tests: 22 endpoints | L | W3-008, W3-010 |
| W3-013 | 2d | Flutter: update pubspec.yaml | S | W3-009 |
| W3-014 | 2d | Delete Supabase Flutter code + AppAuthService | L | W3-013 |
| W3-015 | 2d | App Store + Play Store submission | S+async | W3-014 |
| W3-016 | 3 | Drop OAuth flag columns migration | S | W3-009 |
| W3-017 | 3 | Staging cutover verification | S | W3-012, W3-015 |
| W3-018 | 3 | Prod cutover + 24h monitoring | S+M | W3-017 |
| W3-019 | 4 | Delete Supabase dead code | S | W3-018 |
| W3-020 | 4 | Update all docs + env examples | S | W3-019 |
| W3-021 | 4 | Delete Supabase projects (30-day hold) | S | W3-018+30d |

**Total**: 21 tasks, ~20-28 dev-days

### Critical Path

```
W3-000 → W3-001 → W3-002 → W3-003 → W3-004 → W3-005 → W3-006 → W3-007
→ W3-008 → W3-009 → W3-013 → W3-014 → W3-015 → W3-017 → W3-018 → W3-021
```

### Parallelization Opportunities

- W3-000 (spike) || W3-001 (Neon provision)
- W3-010 (OAuth console) || W3-011 (unit tests) || W3-012 (integration tests) || W3-013 (Flutter pubspec)
- W3-016 (drop columns) during W3-015 store review wait
- W3-019 (cleanup) || W3-020 (docs)

---

## Environment Variables

### Remove (at cutover)

```
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_JWT_SECRET
```

### Add

```
DATABASE_URL              # Neon pooled (runtime)
DATABASE_DIRECT_URL       # Neon unpooled (migrations)
BETTER_AUTH_SECRET        # Min 32-char random (HS256 signing)
BETTER_AUTH_BASE_URL      # Public backend URL
GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
APPLE_CLIENT_ID
APPLE_TEAM_ID
APPLE_KEY_ID
APPLE_PRIVATE_KEY
```

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| `usePlural: true` pluralizes ALL 4 tables | MEDIUM | Use explicit `modelName` per table or plural Prisma names with `@@map` (confirmed in spike) |
| NOT NULL columns without defaults | LOW | Schema already has defaults; BA ignores unknown columns (confirmed in spike) |
| Neon connection pool sizing | LOW | 1000 via pooler vs 300 peak concurrent |
| Better Auth TOTP plugin maturity | MEDIUM | Fallback to `otplib` if insufficient |
| JWT+BA session sync on logout | LOW | Enforce order: revoke BA session FIRST → then blacklist JWT. If blacklist fails, JWT expires in 1h naturally |
| `npm install` fails on node v24 | LOW | Use `pnpm add better-auth` instead (confirmed in spike) |

---

## Success Criteria

### Phase 1 — Neon DB
- [ ] `prisma migrate deploy` exits 0 against all 3 Neon environments
- [ ] 48h prod traffic with zero DB connection errors

### Phase 2 — Better Auth Core
- [ ] All 22 auth endpoints return correct responses (integration tests green)
- [ ] JWT issued with `alg: HS256`, correct `exp`
- [ ] `session` table populated on login, deleted on logout
- [ ] NO `ba_user` table in schema
- [ ] Supabase ES256 tokens rejected with 401

### Phase 2 — OAuth
- [ ] Google OAuth end-to-end in all environments
- [ ] Apple OAuth end-to-end in all environments
- [ ] `account` table contains OAuth provider rows

### Phase 2 — Flutter
- [ ] `supabase_flutter` absent from dependency tree
- [ ] Deep link OAuth callback works on iOS + Android
- [ ] `flutter analyze` zero errors

### Cutover
- [ ] Zero Supabase env vars in prod
- [ ] Monthly infra cost <= $20/month
- [ ] All 3 Supabase projects paused
- [ ] Test users re-registered successfully

---

## Cost Impact

| Item | Before | After |
|------|--------|-------|
| Supabase Pro (prod) | ~$25/mo | $0 |
| Supabase Pro (staging) | ~$25/mo | $0 |
| Supabase Free (dev) | $0 | $0 |
| Neon Launch (prod) | — | $19/mo |
| Neon Free (dev + staging) | — | $0 |
| Better Auth | — | $0 (self-hosted) |
| **Total** | **~$50-75/mo** | **~$19/mo** |
| **Annual savings** | | **~$370-670/year** |

---

## Affected Files (17 total)

### Backend (15 files)

| File | Action |
|------|--------|
| `prisma/schema.prisma` | Modify — add directUrl, email_verified, session/account/verification models, remove OAuth flags |
| `prisma/migrations/YYYYMMDD_add_better_auth_schema/` | Create |
| `prisma/migrations/YYYYMMDD_drop_oauth_flags/` | Create |
| `src/auth/strategies/jwt.strategy.ts` | Modify — HS256 only |
| `src/auth/auth.service.ts` | Modify — BetterAuthService |
| `src/auth/auth.module.ts` | Modify — BetterAuthModule |
| `src/auth/oauth.service.ts` | Modify — BA OAuth |
| `src/common/services/mfa.service.ts` | Modify — BA TOTP, remove session binding |
| `src/common/supabase.service.ts` | Delete |
| `src/better-auth/better-auth.config.ts` | Create |
| `src/better-auth/better-auth.service.ts` | Create |
| `src/better-auth/better-auth.module.ts` | Create |
| `.env.example` | Modify |
| `package.json` | Modify |

### Admin (3 files)

| File | Action |
|------|--------|
| `src/lib/supabase/client.ts` | Delete (dead code) |
| `src/lib/supabase/server.ts` | Delete (dead code) |
| `package.json` | Modify — remove @supabase/* |

### Flutter (6 files)

| File | Action |
|------|--------|
| `pubspec.yaml` | Modify |
| `lib/main.dart` | Modify — remove Supabase.initialize() |
| `lib/core/auth/supabase_auth.dart` | Delete → replaced by app_auth_service.dart |
| `lib/core/constants/supabase_constants.dart` | Delete |
| `lib/providers/supabase_provider.dart` | Delete |
| `lib/features/auth/data/datasources/auth_remote_data_source.dart` | Modify |

### SDD Artifacts (Engram)

| Artifact | Topic Key |
|----------|-----------|
| Exploration | `sdd/wave3-infra-migration/explore` |
| Proposal | `sdd/wave3-infra-migration/proposal` |
| Spec | `sdd/wave3-infra-migration/spec` |
| Design | `sdd/wave3-infra-migration/design` |
| Tasks | `sdd/wave3-infra-migration/tasks` |
