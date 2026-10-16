---
name: proposal
description: Creates a technical Change Proposal (RFC) in .temp/<topic>/proposal.md, analyzing codebase/specification conflicts and recommending an integration strategy (Expand-Contract vs In-Place). Use via /proposal.
---

# Proposal (`/proposal`)

## 1. Role & Permissions (Scoped RFC Writer)

- **MODE**: **Scoped Writer**.
- **ALLOWED WRITES**:
  - `.temp/<topic>/proposal.md`
  - `.gitignore` (only to ensure `.temp/` is ignored)
- **FORBIDDEN ACTIONS**:
  - NEVER modify files in `src/`, tests, or `docs/specifications/`.
  - NEVER write full low-level production code in `proposal.md` (only architectural contracts, signatures, diagrams, or short pseudo-code snippets are allowed).
- **LANGUAGE RULE**: Always communicate with the user and write `.temp/<topic>/proposal.md` in the user's conversation language.

---

## 2. Topic Resolution & `.gitignore` Guard

1. Check `.gitignore` and ensure `.temp/` is present.
2. Inspect `.temp/`:
   - If **1 topic folder** exists or the topic is obvious from the chat, select it automatically and output: `Active topic: .temp/<topic>/`.
   - If **2+ topic folders** exist and the target topic is ambiguous, list them and ask the user which topic to work on.

---

## 3. Prerequisite Advisor (Interactive Loop)

Check whether `.temp/<topic>/intent.md` exists:
- **If `intent.md` exists**: Read it and proceed to Section 4.
- **If `intent.md` does NOT exist**: Do not hard-block. Offer the user a clear choice with your recommendation based on the complexity of the request:
  1. **Run `/interview` → create `/intent` → then `/proposal`** *(Recommended if requirements and boundaries are still vague)*.
  2. **Run `/interview` and go straight to creating `proposal.md`** *(Recommended if you want to clarify requirements interactively without saving a separate `intent.md`)*.
  3. **Create `proposal.md` immediately from current chat context** *(Recommended if the goal and scope are already clear from our discussion)*.
  - Allow the user to ask about pros/cons or clarify details. After answering any question, **re-present the choices** until the user selects one.

---

## 4. Conflict Analysis & Migration Strategy (CRITICAL)

Before finalizing `.temp/<topic>/proposal.md`:
1. **Inspect existing codebase, dependency versions & `docs/specifications/`**:
   - Check if the proposed change modifies or conflicts with existing functions, classes, public APIs, or normative specs in `docs/specifications/`.
   - **Source-Driven Verification**: When proposing changes that depend on external frameworks or libraries, check the exact version in the project manifest (`package.json`, `.csproj`, `Cargo.toml`, `pyproject.toml`, `go.mod`) and verify against official documentation or existing project patterns instead of relying on stale training memory.
2. **If a conflict or breaking change is possible, present an Integration Strategy choice** (or embed the confirmed choice if obvious, highlighting your recommendation):
   - **Strategy A — Parallel Implementation (Expand-Contract)**:
     - Create a new function/method/class alongside the existing implementation so current callers and tests never break during development.
     - Switch callers over only after the new implementation is 100% complete and tested.
     - Explicitly decide what happens to the old implementation: **Deprecate** (keep with deprecation notice) or **Remove** (delete once all callers are migrated).
   - **Strategy B — Direct In-Place Replacement**:
     - Modify the existing implementation directly (only recommended when the scope is small, internal, and non-breaking).
   - *Note*: This decision directly determines whether and how `docs/specifications/` will need to be updated at the end of the cycle.

---

## 5. Artifact Structure (`.temp/<topic>/proposal.md`)

Write `.temp/<topic>/proposal.md` with the following sections:

```markdown
# Proposal (RFC): <Title>

## 1. What & Why (Summary of Changes)
- <Concise description of what is changing and why>

## 2. Integration & Migration Strategy
- **Chosen Strategy**: <Expand-Contract (Parallel) OR In-Place Replacement>
- **Transition & Old Code Policy**: <How callers switch over; whether old implementation is Deprecated or Removed>

## 3. Impact on System Specifications (`docs/specifications/`)
- <Which specification files will need to be created/updated via `/spec` after implementation, or "None (internal change only)">

## 4. Architectural Boundaries, Contracts & Risks
- <Component boundaries, signatures/interfaces, key risks, and non-goals — no low-level implementation code>
```

---

## 6. Forward Handoff & Terminal Turn Rule (CRITICAL)

After saving `.temp/<topic>/proposal.md`:
1. Link to `.temp/<topic>/proposal.md` and highlight the chosen Integration Strategy (`Expand-Contract` vs `In-Place`).
2. Offer the next-step options with your recommendation:
   - **Option 1 (Recommended)**: Decompose `proposal.md` into independent, non-breaking tasks via `/decompose` (`.temp/<topic>/tasks.md`).
   - **Option 2**: Run `/review` on `proposal.md` to stress-test the architecture before creating tasks.
   - **Option 3**: Refine or adjust the strategy in `proposal.md`.
   - *Note*: If the user asks questions or pros/cons about any option or strategy, answer thoroughly and re-present the options.
3. **STOP YOUR TURN IMMEDIATELY.** Wait for the user's response.

