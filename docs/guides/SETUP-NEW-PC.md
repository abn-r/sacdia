# Setup PC Nueva — Replicar Workflow Claude Code + GitHub

Guía para configurar una PC nueva con cuenta de Claude distinta, replicando el flujo de trabajo de SACDIA: git/gh, convenciones de commits/PRs, Claude Code (plugins, skills, hooks) y workflow SDD.

> **Audiencia**: desarrollador que recibe la PC nueva y necesita arrancar listo para colaborar en los 3 repos (`sacdia-backend`, `sacdia-admin`, `sacdia-app`).

---

## 1. Git + GitHub CLI

### 1.1 Instalar herramientas (macOS)

```bash
# Si Homebrew no está instalado:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Toolchain estándar del proyecto
brew install git gh node bat ripgrep fd-find sd eza
```

> Las herramientas `bat`, `rg`, `fd`, `sd`, `eza` son requisito (regla global: nunca usar `cat`/`grep`/`find`/`sed`/`ls`).

### 1.2 Configurar git (cuenta nueva)

```bash
git config --global user.name "Nombre Apellido"
git config --global user.email "tu-email@example.com"
git config --global init.defaultBranch main
git config --global pull.rebase false
```

### 1.3 Autenticar GitHub CLI

```bash
gh auth login
# Selecciones:
#   GitHub.com
#   HTTPS
#   Authenticate with a web browser
```

Verificar:
```bash
gh auth status
```

Scopes mínimos: `repo`, `workflow`, `read:org`, `gist`.

### 1.4 SSH (recomendado)

```bash
ssh-keygen -t ed25519 -C "tu-email@example.com"
# Enter para defaults, passphrase opcional

eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

gh ssh-key add ~/.ssh/id_ed25519.pub --title "PC-nueva-$(date +%Y%m)"
```

### 1.5 Acceso a repos privados

Los 3 repos son privados bajo `abn-r`. La cuenta nueva necesita ser **collaborator** o miembro del org. Pedir invitación al owner antes de seguir.

### 1.6 Clonar repos

```bash
mkdir -p ~/Documents/development/sacdia
cd ~/Documents/development/sacdia

git clone https://github.com/abn-r/sacdia-backend.git
git clone https://github.com/abn-r/sacdia-admin.git
git clone https://github.com/abn-r/sacdia-app.git
```

---

## 2. Convenciones de Commits y PRs

### 2.1 Conventional Commits

Tipos permitidos: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`, `ci`, `build`.

Formato:
```
<tipo>(<scope opcional>): <subject ≤50 chars>

<body opcional — solo cuando el "why" no es obvio>
```

Reglas duras:

- **Subject ≤50 caracteres**.
- **Nunca** agregar `Co-Authored-By: Claude` ni cualquier atribución a IA.
- **Nunca** usar `--no-verify`, `--no-gpg-sign`, ni saltarse hooks.
- Crear commits **nuevos** en lugar de `--amend` (salvo pedido explícito).
- `git add <archivos>` — evitar `git add -A` o `git add .` (riesgo de filtrar `.env`/credenciales).
- Mensaje vía heredoc para preservar formato:
  ```bash
  git commit -m "$(cat <<'EOF'
  feat(auth): agregar refresh token rotation

  Mitigation contra token replay tras incidente Q1.
  EOF
  )"
  ```

### 2.2 Branch naming

```
feat/<scope>      → nueva funcionalidad
fix/<scope>       → bugfix
docs/<scope>      → documentación
refactor/<scope>  → refactor sin cambio funcional
chore/<scope>     → mantenimiento, deps
```

### 2.3 Pull Requests

Plantilla obligatoria (con `gh pr create`):

```markdown
## Summary
- Bullet 1
- Bullet 2
- Bullet 3

## Test plan
- [ ] Caso happy path
- [ ] Edge case X
- [ ] Regresión en feature Y
```

Reglas:

- Título ≤70 caracteres.
- Crear con HEREDOC para preservar markdown:
  ```bash
  gh pr create --title "feat(auth): refresh token rotation" --body "$(cat <<'EOF'
  ## Summary
  - ...

  ## Test plan
  - [ ] ...
  EOF
  )"
  ```
- **Nunca** force-push a `main`/`master`.
- **Nunca** push si el usuario no lo pidió explícitamente.

---

## 3. Claude Code

### 3.1 Instalar Claude Code

Desde [claude.com/code](https://claude.com/code) o:
```bash
npm install -g @anthropic-ai/claude-code
```

Login con la cuenta nueva (`/login` dentro de la herramienta).

### 3.2 Marketplaces y plugins

Dentro de Claude Code:

```
/plugin marketplace add Gentleman-Programming/engram
/plugin marketplace add JuliusBrussee/caveman
/plugin marketplace add jarrodwatts/claude-hud
/plugin marketplace add anthropics/claude-plugins-official

/plugin install engram@engram
/plugin install caveman@caveman
/plugin install claude-hud@claude-hud
/plugin install superpowers@claude-plugins-official
/plugin install frontend-design@claude-plugins-official
```

Versions de referencia (de la PC actual, 2026-05-08):

| Plugin | Versión |
|--------|---------|
| engram | 0.1.0 |
| caveman | latest |
| claude-hud | 0.0.12 |
| superpowers | 5.1.0 |
| frontend-design | latest |

### 3.3 Archivos a transferir

Copiar de la PC actual a la nueva (mismo path, ajustar `/Users/<usuario>`):

| Origen | Destino | Contenido |
|--------|---------|-----------|
| `~/.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Reglas globales: protocolo engram, personalidad, idioma, agent teams orchestrator |
| `~/.claude/settings.json` | `~/.claude/settings.json` | Hooks, plugins enabled, output style, theme |
| `~/.claude/hooks/caveman-activate.js` | mismo path | Hook session start |
| `~/.claude/hooks/caveman-mode-tracker.js` | mismo path | Hook user prompt |
| `~/.claude/skills/sdd-*` (10 carpetas) | mismo path | Workflow SDD |
| `~/.claude/skills/repo-researcher` | mismo path | Skill búsqueda read-only |
| `~/.claude/skills/skill-creator` | mismo path | Skill para crear skills |
| `~/.claude/skills/go-testing` | mismo path | Skill testing Go |
| `~/.claude/skills/_shared` | mismo path | Convenciones compartidas |
| `<repo>/CLAUDE.md` (cada repo) | mismo path | Ya viene con el clone |

> **Symlinks**: en `~/.claude/skills/` hay 2 symlinks (`mobile-design`, `sleek-design-mobile-apps` → `~/.agents/skills/`). Si se necesitan, copiar también `~/.agents/skills/<name>/` y recrear los symlinks:
> ```bash
> ln -s ~/.agents/skills/mobile-design ~/.claude/skills/mobile-design
> ln -s ~/.agents/skills/sleek-design-mobile-apps ~/.claude/skills/sleek-design-mobile-apps
> ```

### 3.4 Settings clave (`~/.claude/settings.json`)

Mínimo viable:

```json
{
  "permissions": {
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo rm -rf /)",
      "Bash(rm -rf ~)",
      "Bash(sudo rm -rf ~)",
      "Read(.env)",
      "Read(.env.*)",
      "Edit(.env)",
      "Edit(.env.*)"
    ],
    "defaultMode": "bypassPermissions"
  },
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "node \"/Users/<USER>/.claude/hooks/caveman-activate.js\"",
        "timeout": 5
      }]
    }],
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": "node \"/Users/<USER>/.claude/hooks/caveman-mode-tracker.js\"",
        "timeout": 5
      }]
    }]
  },
  "outputStyle": "Gentleman",
  "language": "Español",
  "effortLevel": "high",
  "skipDangerousModePermissionPrompt": true,
  "ENABLE_TOOL_SEARCH": true,
  "enabledPlugins": {
    "engram@engram": true,
    "caveman@caveman": true
  },
  "extraKnownMarketplaces": {
    "engram": { "source": { "source": "github", "repo": "Gentleman-Programming/engram" } },
    "claude-code-plugins": { "source": { "source": "github", "repo": "anthropics/claude-code" } },
    "claude-hud": { "source": { "source": "github", "repo": "jarrodwatts/claude-hud" } },
    "caveman": { "source": { "source": "github", "repo": "JuliusBrussee/caveman" } }
  }
}
```

> Reemplazar `<USER>` con el usuario de la PC nueva. La defaultMode `bypassPermissions` deja correr tools sin prompt — solo si la persona acepta el riesgo.

### 3.5 Memoria Engram

Engram es local por máquina. Dos opciones:

- **Recomendado para cuenta separada**: empezar limpio. La memoria se construye sola con el uso.
- **Migrar contexto**: copiar `~/.claude/projects/-Users-<USER-VIEJO>-Documents-development-sacdia/memory/` al equivalente con el usuario nuevo. El path se regenera con el username de la PC nueva — renombrar la carpeta acorde.

### 3.6 Caveman mode (opcional pero recomendado)

Activado por defecto vía hooks (ver `settings.json`). Niveles: `lite`, `full`, `ultra`. Cambiar con:
```
/caveman lite|full|ultra
```
Desactivar: `stop caveman` o `normal mode`.

---

## 4. Workflow SDD (Spec-Driven Development)

Toda la lógica está en `~/.claude/CLAUDE.md` y `~/.claude/skills/sdd-*`. Si copiaste los archivos del paso 3, ya está listo.

### 4.1 Comandos disponibles

| Comando | Cuándo |
|---------|--------|
| `/sdd-init` | Bootstrap del contexto SDD en el proyecto |
| `/sdd-new <name>` | Iniciar feature: exploración + propuesta |
| `/sdd-explore <topic>` | Investigar idea sin crear archivos |
| `/sdd-continue` | Avanzar siguiente fase del DAG |
| `/sdd-ff <name>` | Fast-forward: propuesta → specs → design → tasks |
| `/sdd-apply` | Implementar tasks |
| `/sdd-verify` | Validar implementación contra specs |
| `/sdd-archive` | Cerrar y persistir |

### 4.2 DAG de dependencias

```
proposal → specs ────→ tasks → apply → verify → archive
            ↑
          design
```

### 4.3 Reglas del orchestrator

- **No ejecutar inline**: leer/escribir código → delegar a sub-agente.
- **Preferir `delegate` (async)** sobre `task` (sync). Solo `task` si el resultado bloquea el siguiente paso.
- **Hard stop**: antes de `Read`/`Edit`/`Write`/`Grep` sobre código fuente, preguntarse "¿es orquestación o ejecución?". Si es ejecución → delegar.

---

## 5. Verificación final

Después de configurar, validar que todo funciona:

```bash
# Git/GH
git config --global --get user.email
gh auth status
gh repo view abn-r/sacdia-admin

# Claude Code
claude --version
# Dentro de Claude Code:
/plugin list                 # ver plugins instalados
/help                        # ver skills disponibles
```

Probar el flujo completo:
1. Abrir Claude Code en `~/Documents/development/sacdia`.
2. Pedir un cambio chico (`fix typo en README`).
3. Verificar que se respete: caveman mode, idioma español, conventional commits.

---

## 6. Troubleshooting

| Problema | Causa probable | Fix |
|----------|----------------|-----|
| `gh: not authenticated` | Auth no completado | `gh auth login` |
| `permission denied (publickey)` | SSH key no agregada a GitHub | `gh ssh-key add` |
| Plugins no aparecen | Marketplace no registrado | `/plugin marketplace add <repo>` |
| Hooks fallan al iniciar | Path de `node` distinto | Editar `settings.json` con `which node` resultado |
| Engram sin contexto | Memoria local nueva | Esperado — se construye con uso, o copiar carpeta `memory/` |
| Caveman no activa | Hook script no ejecutable | `chmod +x ~/.claude/hooks/*.js` |

---

## 7. Recursos del proyecto

- `CLAUDE.md` raíz — visión general del monorepo
- `sacdia-backend/CLAUDE.md` — API, endpoints, tests
- `sacdia-admin/CLAUDE.md` — Next.js, components, routes
- `sacdia-app/CLAUDE.md` — Flutter, screens, providers
- `docs/api/ENDPOINTS-LIVE-REFERENCE.md` — referencia runtime canónica
- `docs/database/SCHEMA-REFERENCE.md` — esquema DB
- `docs/audit/REALITY-MATRIX.md` — estado real vs documentado
- `docs/features/README.md` — feature registry

---

**Última actualización**: 2026-05-08
**Owner**: Abner Reyes (`abner.reyes03@gmail.com`)
