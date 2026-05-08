# SDD Orchestrator Design Spec

**Date:** 2026-03-14
**Status:** Approved design persisted
**Scope:** Vendor-neutral orchestration skill for Spec-Driven Development and general delegated work

## Purpose

Define the normative behavior for a reusable `sdd-orchestrator` skill that acts as a thin coordinator instead of an inline executor. The skill must preserve a stable operating contract across vendors by separating core orchestration rules from platform-specific adapter guidance.

## Design Goals

- Keep the user-facing conversation thread thin and stateful while pushing real work into skills or sub-agents.
- Make delegation behavior explicit, enforceable, and vendor-neutral.
- Preserve SDD artifact flow, persistence, and recovery semantics as a shared contract.
- Prevent inline code reading, code writing, architecture analysis, solution design, test execution, or implementation by the coordinator.
- Make adapter differences local so the behavioral contract stays stable across Claude Code, Codex/OpenCode, and future runtimes.

## Non-Goals

- Implement the skill in this document.
- Redesign the approved SDD dependency graph.
- Add new persistence backends beyond the approved `engram | openspec | hybrid | none` modes.
- Move vendor-specific slash commands into the vendor-neutral core.

## Architecture

The skill follows `core + shared + adapters`.

- **Core** defines orchestrator behavior: conversation boundaries, delegation rules, phase routing, result synthesis, and safety boundaries.
- **Shared** defines contracts used by all adapters: allowed inline actions, delegation triggers, result contract, persistence conventions, topic keys, and recovery rules.
- **Adapters** translate the shared contract into runtime-specific wording and operational guidance without changing behavior.

This split keeps the semantic contract stable while letting each runtime describe its own tool surface, command model, and handoff mechanics.

## Core Orchestrator Contract

### Allowed Inline Actions

The coordinator may only perform these inline actions:

- `short_answer`
- `coordinate`
- `summarize`
- `request_user_decision`
- `track_state`

Anything outside this list is out of bounds for the coordinator and must be delegated.

### Mandatory Delegation Triggers

If the requested work crosses any of these triggers, delegation is mandatory:

- `read_code`
- `write_code`
- `architecture_analysis`
- `solution_design`
- `run_tests`
- `implementation`

This rule applies to both SDD and non-SDD flows. There is no "small enough to do inline" exception once a trigger is crossed.

### Clarification and Safety Guards

The coordinator may ask for clarification only when blocked after checking the approved context and when the missing information materially changes the outcome. It must not ask procedural permission questions.

The coordinator must stop and request user input when a decision is destructive, irreversible, production-impacting, security-sensitive, or billing-sensitive.

## SDD Command Model

### Meta-Commands Owned by the Coordinator

These commands are coordinator-only meta-commands:

- `/sdd-new`
- `/sdd-continue`
- `/sdd-ff`

They do not execute phase logic inline. They inspect state, determine the next phase, launch the right skill-based phase, and synthesize the result back to the user.

### Phase Skills

The coordinator delegates the execution work to the phase skills:

- `sdd-explore`
- `sdd-propose`
- `sdd-spec`
- `sdd-design`
- `sdd-tasks`
- `sdd-apply`
- `sdd-verify`
- `sdd-archive`

Each phase is responsible for reading its required dependencies from the persistence backend and writing its own artifact.

## Shared Result Contract

Every delegated phase must return this exact envelope:

- `status`
- `executive_summary`
- `artifacts`
- `next_recommended`
- `risks`

This contract is normative. Adapters may rephrase surrounding guidance, but they must not rename, remove, or reorder the contract fields semantically.

## Shared Persistence Contract

### Artifact Store Modes

The orchestrator supports these persistence modes:

- `engram`
- `openspec`
- `hybrid`
- `none`

Behavior by mode:

- `engram`: persistent memory is the source of truth.
- `openspec`: local files are the source of truth.
- `hybrid`: both are written and either can be used for recovery.
- `none`: no files are written; outputs are returned inline and the coordinator should recommend enabling persistence.

### Topic Keys

The SDD topic keys are a shared normative contract and must stay stable:

- `sdd-init/{project}`
- `sdd/{change-name}/explore`
- `sdd/{change-name}/proposal`
- `sdd/{change-name}/spec`
- `sdd/{change-name}/design`
- `sdd/{change-name}/tasks`
- `sdd/{change-name}/apply-progress`
- `sdd/{change-name}/verify-report`
- `sdd/{change-name}/archive-report`
- `sdd/{change-name}/state`

### Recovery

Recovery is mandatory before continuing when state is missing.

- In `engram`, recover with `mem_search(...)` followed by `mem_get_observation(...)`.
- In `openspec`, recover from the persisted state file.
- In `hybrid`, either backend may be used, but state must be reconciled consistently.
- In `none`, the coordinator must explain that state was not persisted and cannot be recovered automatically.

## Non-SDD Delegation Rules

For general tasks outside the SDD command set, the coordinator still delegates whenever work crosses the mandatory triggers. The delegated sub-agent must receive the relevant context and must persist important discoveries, bug fixes, or decisions.

This keeps the orchestrator consistent: SDD is a specialized flow, not an exception to the delegation model.

## Adapter Responsibilities

Adapters may define:

- how skills are invoked in the local runtime
- how sub-agents are launched or simulated
- how memory and file persistence tools are referenced
- how slash commands or equivalent entrypoints are described

Adapters may not change:

- allowed inline actions
- mandatory delegation triggers
- meta-command ownership
- result contract fields
- topic key contract
- recovery requirement

## Recommended Skill File Decomposition

The eventual implementation should mirror the architecture split:

- root `SKILL.md` for the entrypoint and routing rules
- one shared contract document for invariants and persistence
- one core behavior document for orchestration flow
- one adapter document per supported runtime

This keeps the skill maintainable and reduces the risk of adapter-specific drift.

## Acceptance Criteria

The design is satisfied when the implemented skill:

- behaves as a coordinator, not an inline executor
- delegates whenever a mandatory trigger is crossed
- treats `/sdd-new`, `/sdd-continue`, and `/sdd-ff` as meta-commands only
- preserves the exact result contract
- preserves the standard SDD topic keys
- performs mandatory recovery when state is missing
- documents explicit clarification and safety guards
- keeps vendor-specific differences inside adapter guidance instead of the shared contract

## Open Risks To Control During Implementation

- Adapter text may accidentally weaken mandatory delegation language.
- A runtime-specific implementation may smuggle inline analysis into the coordinator.
- Topic keys may drift if copied manually instead of being sourced from a shared section.
- Recovery wording may become backend-specific and break `hybrid` or `none` semantics.

## Implementation Note

The next artifact should be an implementation plan that creates the skill as documentation-first files under the workspace skill registry, then registers it in the local skill discovery fallback.
