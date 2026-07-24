CREATE TABLE "admin_auth_sessions" (
  "session_id" TEXT NOT NULL,
  "family_id" UUID NOT NULL,
  "surface" VARCHAR(20) NOT NULL DEFAULT 'admin',
  "client_type" VARCHAR(20) NOT NULL DEFAULT 'ios',
  "assurance_level" VARCHAR(10) NOT NULL,
  "active_assignment_id" UUID,
  "absolute_expires_at" TIMESTAMPTZ(6) NOT NULL,
  "revoked_at" TIMESTAMPTZ(6),
  "revoked_reason" VARCHAR(80),
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  "modified_at" TIMESTAMPTZ(6) NOT NULL DEFAULT now(),

  CONSTRAINT "admin_auth_sessions_pkey" PRIMARY KEY ("session_id"),
  CONSTRAINT "admin_auth_sessions_surface_chk" CHECK ("surface" = 'admin'),
  CONSTRAINT "admin_auth_sessions_client_type_chk" CHECK ("client_type" = 'ios'),
  CONSTRAINT "admin_auth_sessions_assurance_level_chk" CHECK ("assurance_level" IN ('aal1', 'aal2')),
  CONSTRAINT "admin_auth_sessions_absolute_expiry_chk" CHECK ("absolute_expires_at" > "created_at"),
  CONSTRAINT "admin_auth_sessions_session_id_fkey"
    FOREIGN KEY ("session_id") REFERENCES "sessions"("id")
    ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT "admin_auth_sessions_active_assignment_id_fkey"
    FOREIGN KEY ("active_assignment_id") REFERENCES "club_role_assignments"("assignment_id")
    ON DELETE SET NULL ON UPDATE NO ACTION
);

CREATE INDEX "idx_admin_auth_sessions_family_id"
  ON "admin_auth_sessions"("family_id");
CREATE INDEX "idx_admin_auth_sessions_revoked_at"
  ON "admin_auth_sessions"("revoked_at");
CREATE INDEX "idx_admin_auth_sessions_active_assignment_id"
  ON "admin_auth_sessions"("active_assignment_id");
