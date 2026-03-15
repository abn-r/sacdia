# SDD Orchestrator Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the vendor-neutral `sdd-orchestrator` skill as a documentation-first workspace skill that enforces coordinator-only behavior, shared SDD contracts, and runtime-specific adapters without implementing any business feature logic inline.

**Architecture:** Use `core + shared + adapters` inside a dedicated workspace skill folder. Keep normative behavior in shared/core documents, then layer runtime-specific guidance for Claude Code and Codex/OpenCode so vendor differences stay local and the orchestration contract remains stable.

**Tech Stack:** Markdown skill files, workspace skill registry (`.atl/skill-registry.md`), Engram persistence conventions, OpenCode/Claude-compatible skill composition patterns

---

## Constraints and Assumptions

- This plan is for documentation and skill authoring only; it does not implement product code.
- No automated repo-native test suite is currently documented for validating skill markdown semantics.
- Verification is therefore structural and manual: file presence, contract text checks, registry registration, and semantic review against the approved design.
- Keep the skill vendor-neutral; vendor-specific behavior belongs only in adapter sections.

## Target Files

**Create:**

- `.agents/skills/sdd-orchestrator/SKILL.md`
- `.agents/skills/sdd-orchestrator/core.md`
- `.agents/skills/sdd-orchestrator/shared-contracts.md`
- `.agents/skills/sdd-orchestrator/adapters/claude-code.md`
- `.agents/skills/sdd-orchestrator/adapters/codex-opencode.md`

**Modify:**

- `.atl/skill-registry.md`

---

### Task 1: Scaffold the skill directory

**Files:**

- Create: `.agents/skills/sdd-orchestrator/SKILL.md`
- Create: `.agents/skills/sdd-orchestrator/core.md`
- Create: `.agents/skills/sdd-orchestrator/shared-contracts.md`
- Create: `.agents/skills/sdd-orchestrator/adapters/claude-code.md`
- Create: `.agents/skills/sdd-orchestrator/adapters/codex-opencode.md`

**Step 1: Create the directory tree**

Run:

```bash
mkdir -p .agents/skills/sdd-orchestrator/adapters
```

Expected: the directory exists and is empty or contains only the new markdown files once created.

**Step 2: Verify the scaffold exists**

Run:

```bash
ls .agents/skills/sdd-orchestrator .agents/skills/sdd-orchestrator/adapters
```

Expected: both directories are listed without errors.

---

### Task 2: Write the shared contract document

**Files:**

- Create: `.agents/skills/sdd-orchestrator/shared-contracts.md`

**Step 1: Add the immutable orchestration invariants**

Write a shared contract document that contains, verbatim where appropriate:

- Allowed Inline Actions: `short_answer`, `coordinate`, `summarize`, `request_user_decision`, `track_state`
- Mandatory Delegation Triggers: `read_code`, `write_code`, `architecture_analysis`, `solution_design`, `run_tests`, `implementation`
- Exact Result Contract: `status`, `executive_summary`, `artifacts`, `next_recommended`, `risks`
- Standard SDD topic keys
- Mandatory recovery rule when state is missing
- Clarification and Safety Guards

**Step 2: Verify the contract text is present**

Run:

```bash
rg -n "Allowed Inline Actions|Mandatory Delegation Triggers|Result Contract|Topic Keys|Recovery|Clarification|Safety" .agents/skills/sdd-orchestrator/shared-contracts.md
```

Expected: all major sections appear in the output.

---

### Task 3: Write the core orchestrator behavior

**Files:**

- Create: `.agents/skills/sdd-orchestrator/core.md`

**Step 1: Document the coordinator-only operating model**

Write the core behavior document with these sections:

- coordinator mission and anti-patterns
- inline actions vs delegated work
- SDD meta-command routing for `/sdd-new`, `/sdd-continue`, `/sdd-ff`
- phase delegation model for `sdd-explore` through `sdd-archive`
- non-SDD delegation rules
- state tracking and synthesis expectations

**Step 2: Verify the core routing language is present**

Run:

```bash
rg -n "coordinator|delegate|/sdd-new|/sdd-continue|/sdd-ff|non-SDD|state" .agents/skills/sdd-orchestrator/core.md
```

Expected: the file shows coordinator-only rules and explicit routing references.

---

### Task 4: Write the Claude Code adapter

**Files:**

- Create: `.agents/skills/sdd-orchestrator/adapters/claude-code.md`

**Step 1: Map the shared contract to Claude-style runtime guidance**

Document:

- how the runtime invokes skills
- how the orchestrator launches sub-agents or equivalent delegated phases
- how Engram retrieval should be described in Claude-style instructions
- how the result contract is synthesized back to the user

**Step 2: Verify adapter scope stays adapter-specific**

Run:

```bash
rg -n "Skill|sub-agent|mem_search|mem_get_observation|result contract" .agents/skills/sdd-orchestrator/adapters/claude-code.md
```

Expected: the adapter explains runtime wiring without redefining shared invariants.

---

### Task 5: Write the Codex/OpenCode adapter

**Files:**

- Create: `.agents/skills/sdd-orchestrator/adapters/codex-opencode.md`

**Step 1: Map the shared contract to Codex/OpenCode runtime guidance**

Document:

- skill loading expectations
- how delegation is framed in a Codex/OpenCode session
- how memory/file persistence references are phrased
- how slash-command or command-equivalent behavior should be described without hardcoding a vendor-only implementation into the shared core

**Step 2: Verify adapter wording is parallel to Claude Code**

Run:

```bash
rg -n "skill|delegat|mem_search|openspec|slash|command" .agents/skills/sdd-orchestrator/adapters/codex-opencode.md
```

Expected: the adapter is vendor-specific in phrasing only, not in semantics.

---

### Task 6: Compose the root skill entrypoint

**Files:**

- Create: `.agents/skills/sdd-orchestrator/SKILL.md`

**Step 1: Add frontmatter and entry instructions**

Write `SKILL.md` with:

- `name: sdd-orchestrator`
- a clear description explaining that this is a coordinator skill, not an implementation skill
- a short entry section instructing the runtime to apply the shared contracts first, then the core behavior, then the relevant adapter

**Step 2: Inline or reference the internal documents clearly**

The root file must make it obvious that `shared-contracts.md` is normative, `core.md` defines orchestration flow, and the adapter files only localize runtime behavior.

**Step 3: Verify the root file references every internal document**

Run:

```bash
rg -n "shared-contracts|core|claude-code|codex-opencode|coordinator" .agents/skills/sdd-orchestrator/SKILL.md
```

Expected: all supporting documents are referenced from the entrypoint.

---

### Task 7: Register the new skill in the fallback registry

**Files:**

- Modify: `.atl/skill-registry.md`

**Step 1: Add the new workspace skill entry**

Update the generated registry so `sdd-orchestrator` appears as a workspace skill with a short note explaining that it coordinates SDD and general delegated work via a vendor-neutral contract.

**Step 2: Verify the registry entry is discoverable**

Run:

```bash
rg -n "sdd-orchestrator" .atl/skill-registry.md
```

Expected: exactly one clear registry entry appears.

---

### Task 8: Perform structural and semantic verification

**Files:**

- Review: `.agents/skills/sdd-orchestrator/SKILL.md`
- Review: `.agents/skills/sdd-orchestrator/core.md`
- Review: `.agents/skills/sdd-orchestrator/shared-contracts.md`
- Review: `.agents/skills/sdd-orchestrator/adapters/claude-code.md`
- Review: `.agents/skills/sdd-orchestrator/adapters/codex-opencode.md`
- Review: `.atl/skill-registry.md`

**Step 1: Verify all planned files exist**

Run:

```bash
ls .agents/skills/sdd-orchestrator .agents/skills/sdd-orchestrator/adapters && test -f .atl/skill-registry.md
```

Expected: all files resolve without errors.

**Step 2: Verify invariant coverage across the full skill**

Run:

```bash
rg -n "short_answer|coordinate|summarize|request_user_decision|track_state|read_code|write_code|architecture_analysis|solution_design|run_tests|implementation|status|executive_summary|artifacts|next_recommended|risks|sdd/\{change-name\}/state" .agents/skills/sdd-orchestrator
```

Expected: the search confirms every approved invariant is represented somewhere in the skill docs.

**Step 3: Do the semantic review manually**

Checklist:

- confirm the coordinator never performs forbidden inline work
- confirm meta-commands are described as coordinator-owned only
- confirm topic keys are unchanged
- confirm recovery is mandatory before continuing if state is missing
- confirm both adapters preserve shared semantics

**Step 4: Be honest about tests**

Record in the implementation notes that no automated tests were run because the repository does not document a native automated test harness for skill markdown behavior.

---

## Verification Commands Summary

Use these commands during implementation:

```bash
ls .agents/skills/sdd-orchestrator .agents/skills/sdd-orchestrator/adapters
rg -n "sdd-orchestrator" .atl/skill-registry.md
rg -n "Allowed Inline Actions|Mandatory Delegation Triggers|Result Contract|Topic Keys|Recovery" .agents/skills/sdd-orchestrator
rg -n "short_answer|coordinate|summarize|request_user_decision|track_state|read_code|write_code|architecture_analysis|solution_design|run_tests|implementation|status|executive_summary|artifacts|next_recommended|risks" .agents/skills/sdd-orchestrator
```

Expected outcome: structural completeness and textual confirmation that every approved invariant exists in the implemented skill.

## Documentation Follow-Through

- If the implementation changes the local skill catalog, keep `.atl/skill-registry.md` aligned in the same work.
- If a cross-tool convention about skill placement or persistence wording changes materially, capture that decision in Engram for future reuse.
- If the workspace later introduces a dedicated docs index for skills, add `sdd-orchestrator` there too, but do not invent that index unless it already exists.

## Done Criteria

The implementation is complete when:

- the skill exists under `.agents/skills/sdd-orchestrator/`
- the file split matches `core + shared + adapters`
- the shared contract preserves the approved invariants verbatim
- the adapters localize runtime behavior without mutating the contract
- `.atl/skill-registry.md` lists the skill
- manual semantic review passes
- the implementer explicitly records that automated tests were not applicable
