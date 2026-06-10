# Reviewed surfaces

| Surface | Risk Area | Outcome | Notes |
|---|---|---|---|
| sacdia-backend users profile | RBAC territory / self-service profile | Reported | BACKEND-CAND-01 |
| sacdia-backend resources admin reads | Private resources / signed URLs | Reported | BACKEND-CAND-02 |
| sacdia-backend resources admin mutations | Resource integrity | Reported | BACKEND-CAND-03 |
| sacdia-backend annual folder reads | Evidence confidentiality | Reported | BACKEND-CAND-04 |
| sacdia-backend annual folder uploads | Evidence integrity | Reported | BACKEND-CAND-05 |
| sacdia-backend annual folder evaluations | Territorial review integrity | Reported | BACKEND-CAND-06 |
| sacdia-backend membership requests | Club assignment approval integrity | Reported | BACKEND-CAND-07 |
| sacdia-backend auth/session/MFA/JWT | Authn hardening | No issue found | JWT strategy, MFA guard, CORS, Helmet and Sentry redaction reviewed; no reportable issue promoted. |
| sacdia-backend raw SQL/SSRF/upload keys | Injection/file handling | No issue found | Reviewed Prisma raw usages, R2 key generation, file magic-byte validation, and outbound fetch callsites. |
| sacdia-admin token bridge | Browser token containment | Rejected | Same-origin `/api/auth/token` weakens httpOnly against XSS, but no standalone attacker path was proven. |
| sacdia-admin honors material URL | XSS/navigation/iframe | Rejected | Stored URL needs allowlist hardening, but author is privileged and CSP/default frame policy limits iframe impact; no proven token theft path. |
| sacdia-admin CSRF/redirects/secrets | Browser security | No issue found | SameSite strict cookies, safe relative redirects, Sentry redaction, and empty env example reviewed. |
| sacdia-app iOS OAuth custom scheme | OAuth callback interception | Needs follow-up | Code registers `io.sacdia.app`, but OAuth buttons are currently commented out, app calls GET while backend exposes POST, and backend default redirect is HTTPS. Re-check before re-enabling OAuth. |
| sacdia-app certificate import file_url | Client-supplied file references | Rejected | Current backend OCR provider does not dereference `file_url`; risk is provenance/hardening rather than proven SSRF. |
| sacdia-app annual folder legacy upload | Client/backend contract drift | Rejected | Mobile legacy JSON `file_url` endpoint no longer matches backend multipart route. |
| sacdia-app token storage/TLS/FCM | Mobile client security | No issue found | Secure storage, release HTTPS guard, debug-only logging, and FCM handling reviewed. |
| sacdia-docs dev credentials | Credential exposure | Reported | DOCS-CAND-01 |
| sacdia-docs generated MDX | Stored XSS in docs | Needs follow-up | Escaping is incomplete for MDX expression contexts, but source requires contributor/generator control and no runtime PoC was executed. |
| sacdia-docs sync workflow | CI token exposure | Reported | DOCS-CAND-03 |
| root RBAC workflow | CI secret handling | Needs follow-up | PR same-repo risk exists, but fork PRs do not receive secrets by default and token scopes were not verified. |
