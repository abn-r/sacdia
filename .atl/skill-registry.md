# Skill Registry

Generated fallback registry for skill discovery when memory does not provide `skill-registry`.

Last updated: 2026-03-14

## Lookup Protocol

1. Try memory first:
   - `mem_search(query: "skill-registry", project: "sacdia")`
   - If found, call `mem_get_observation(id)` to read full content.
2. If not found, read this file.
3. Load only skills relevant to the active task trigger.

## Generated Registry

| Scope | Location | Notes |
|---|---|---|
| Workspace | `/Users/abner/Documents/development/sacdia/.agents/skills/` | Primary project skills (app-builder, SDD helpers, UI, backend, security, etc.). |
| Workspace | `/Users/abner/Documents/development/sacdia/.claude/skills/` | Extra workspace-local skills (example: `frontend-dev-guidelines`). |
| User Global | `/Users/abner/.agents/skills/` | Personal/global skills shared across projects (example: `find-skills`). |
| OpenCode Global | `/Users/abner/.config/opencode/skills/` | Core runtime skills and SDD phase skills used by slash commands. |

## Workspace Skill Entries

| Skill | Location | Trigger / Notes |
|---|---|---|
| `sdd-orchestrator` | `.agents/skills/sdd-orchestrator/SKILL.md` | Use when coordinating SDD phases or delegated non-SDD work with coordinator-only behavior, shared persistence/recovery semantics, and runtime adapters for Claude Code and Codex/OpenCode. |

## Quick Usage Notes

- For SDD phase execution, prefer OpenCode global skills in `~/.config/opencode/skills/`.
- For project conventions and specialized workflows, check workspace `.agents/skills/` first.
- If the same skill exists in multiple roots, prefer workspace-local version over global.
- Keep this file concise; do not copy full SKILL content here.

## SDD Semantic Review Checklist

Use this after `node scripts/check-sdd-command-parity.mjs` passes.

- Meta commands (`sdd-new`, `sdd-continue`, `sdd-ff`) delegate phase work and do not execute phase logic inline.
- SDD phase commands describe the structured envelope: `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`.
- Persistence wording is mode-aware (`engram|openspec|hybrid|none`) and does not hardcode one backend.
- Commands that mention artifact retrieval in Engram use two-step guidance (`mem_search` then `mem_get_observation`) when full content is required.
- Any state-transition guidance points to `sdd/{change-name}/state` (or openspec equivalent) consistently.
