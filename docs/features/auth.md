# Auth
Estado: IMPLEMENTADO

## Que existe (verificado contra codigo)
- **Backend**: AuthModule — 22 endpoints (register, login, refresh, logout, password reset, me, context, sessions CRUD, OAuth Google/Apple, MFA enroll/verify/factors/unenroll/status). Controllers: AuthController, SessionsController, OAuthController, MfaController. Services: AuthService, OAuthService, MfaService, SessionManagementService, TokenBlacklistService.
- **Admin**: Login page funcional (POST /auth/login, GET /auth/me). Logout via POST /auth/logout. Proteccion per-page via requireAdminUser(). No hay registro ni MFA desde admin.
- **App**: 5 screens (SplashView, LoginView, RegisterView, ForgotPasswordView, AuthGate). Consume 9 endpoints incluyendo login, register, logout, password reset, pr-check, completion-status, context switch. OAuth Google/Apple declarado pero lanza excepcion "no disponible aun".
- **DB**: users, users_pr, users_roles, users_permissions, roles, permissions, role_permissions, user_fcm_tokens

## Que define el canon
- Canon auth/ define modelo de autorizacion completo: Supabase Auth como provider, JWT con refresh, OAuth con Google y Apple, MFA, sistema RBAC con roles globales + roles de club
- Canon runtime-auth.md define guards (JwtAuthGuard, PermissionsGuard, ClubRolesGuard, OwnerOrAdminGuard), decorators y politicas de autorizacion
- Decisiones clave: la pertenencia se interpreta mediante vinculacion contextual (Decision 4)

## Gap
- App declara OAuth Google/Apple pero no esta funcional (lanza excepcion)
- App consume POST /auth/update-password que es FANTASMA (no existe en backend) — pendiente de implementacion
- App consume POST /auth/pr-check que es FANTASMA (no aparece en backend audit)
- Admin no implementa MFA, OAuth ni gestion de sesiones
- PATCH /admin/users/:userId/approval para aprobacion de usuarios es FANTASMA — pendiente de implementacion en backend

## Prioridad
- Alta para update-password y user approval — funcionalidad core de auth pendiente de backend
