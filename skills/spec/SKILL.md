---
name: spec
description: Creates or updates declarative normative system specifications in docs/specifications/ after feature completion or for existing modules. Use via /spec.
---

# Spec (`/spec`)

## 1. Role & Permissions (Normative Specification Writer)

- **MODE**: **Spec Writer**.
- **ALLOWED WRITES**:
  - `docs/specifications/<module-or-domain>.md`
  - The project's documentation index that lists specifications (e.g., `docs/README.md` or `docs/specifications/README.md`), **only** to add, rename, or remove the entry for a specification you created, renamed, or deleted.
- **FORBIDDEN ACTIONS**:
  - NEVER modify source code (`src/`), tests, or files inside `.temp/`.
  - NEVER delete `.temp/<topic>/` (that is `/cleanup`'s job).
  - **NEVER write migration plans, task lists, refactoring history, or "how to change this in the future" guides into `docs/specifications/`**. A system specification describes **how the system works and behaves right now**, not the steps taken to get there or the steps to change it later. If a future change carries a hard constraint, state it as a normative rule (e.g., "any change that enables X MUST preserve INV-…"), not as a step-by-step recipe.
- **LANGUAGE RULE**: Communicate with the user in their conversation language. Write files in `docs/specifications/` using the existing language convention of the project's `docs/` (or ask the user if creating the very first spec).

---

## 2. Context & Prerequisite Advisor

Check why `/spec` was invoked:

1. **Post-Implementation Sync (Active `.temp/<topic>/` exists)**:
   - Automatically resolve `.temp/<topic>/` (if 1 topic exists or obvious from chat; ask if 2+ topics are ambiguous).
   - Read `.temp/<topic>/intent.md`, `.temp/<topic>/proposal.md` (specifically Section 3: *Impact on System Specifications*), and the implemented code in `src/`.
   - **Dependency rules**: an `/architect` topic (`.temp/arch-<area>/`) keeps its target dependency rules under `Constraints` in the `tasks.md` header, and a proposal keeps them in Section 5. Record each rule the code now actually follows as an invariant (e.g., "`Domain` MUST NOT depend on `Infrastructure`"), so `/audit` and later `/architect` runs treat a violation as a finding instead of a matter of taste. Rules for steps not yet implemented stay out.
   - If the code hasn't been reviewed yet or tasks in `.temp/<topic>/` are still unchecked (`- [ ]`), say so in one line and recommend `/review` (or finishing `/implement`) first. If the user explicitly invoked `/spec`, proceed with the update anyway — the specification can be adjusted after review.
2. **Standalone Module Documentation (No `.temp/` needed)**:
   - If the user asks to document an existing module or subsystem directly, inspect the codebase in `src/` and create/update `docs/specifications/<module>.md`.

---

## 3. Normative Specification Structure (`docs/specifications/<name>.md`)

**Match existing conventions first**: if `docs/specifications/` already contains specifications, read one or two of them and follow their title format, metadata header (status, version, key files), section structure, normative keywords (e.g., RFC 2119 `MUST` / `MUST NOT`), and invariant ID scheme (e.g., `INV-<AREA>-NN`). When updating a spec, keep existing invariant IDs stable: never renumber or reuse an ID, and append new invariants with the next free number. Relative links to source files must resolve from the spec file's location.

Use the default template below **only** when no specifications exist yet. Keep the result declarative, accurate to the current codebase, and structured:

```markdown
# Specification: <Module / Subsystem Name>

## 1. Purpose & Scope
- <What this subsystem is responsible for and its architectural boundaries>

## 2. Core Contracts & Interfaces
- <Public APIs, signatures, inputs/outputs, data models, or protocol rules>
- <If Expand-Contract left a deprecated method: explicitly document the active contract and mark legacy methods under a "Deprecated Interfaces" subsection>

## 3. Behavioral Invariants & Rules
- <Always/Never invariants, state transitions, error handling guarantees>
- <Module dependency rules, when the subsystem has them: which modules may and may not depend on which>
```

---

## 4. Forward Handoff & Terminal Turn Rule (CRITICAL)

After creating or updating `docs/specifications/<name>.md`:

1. Link to the updated specification file(s) in `docs/specifications/` and confirm the documentation index (if the project has one) lists them.
2. **Proceed in the same turn**, announcing the step in one line:
   - **Uncommitted changes exist** → `/git` to build the commit plan (it asks before committing).
   - **Everything is committed and `.temp/<topic>/` exists** → `/cleanup` (it asks before deleting).
   - **Nothing left to do** → **STOP YOUR TURN**.
3. If the user asks to refine the specification instead, do that and **STOP YOUR TURN**.
