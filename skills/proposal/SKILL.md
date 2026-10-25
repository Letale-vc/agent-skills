---
name: proposal
description: Creates a technical Change Proposal (RFC) in .temp/<topic>/proposal.md, analyzing codebase/specification conflicts, library versions, and recommending an integration strategy (Expand-Contract vs In-Place). Use when designing architectural changes, modifying public APIs/contracts, or via /proposal.
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

1. Check `.gitignore` in the project root. If no existing line already ignores it (`.temp`, `.temp/`, `/.temp/`, ignoring trailing whitespace or `\r`), append `.temp/` once; never add a duplicate entry.
2. Inspect `.temp/`:
   - If **1 topic folder** exists or the topic is obvious from the chat, select it automatically and output: `Active topic: .temp/<topic>/`.
   - If **2+ topic folders** exist and the target topic is ambiguous, list them and ask the user which topic to work on.

---

## 3. Prerequisite Advisor (Default-Proceed)

Check whether `.temp/<topic>/intent.md` exists:

- **If `intent.md` exists**: Read it and proceed to Section 4.
- **If `intent.md` does NOT exist**: Do not hard-block:
  - **Goal and scope are clear from the chat** → create `proposal.md` from the current context right away, announcing it in one line.
  - **Requirements or boundaries are still vague** → run `/interview` first (it is read-only and asks its own questions), then return here.
  - The user can override either choice; if they ask about pros/cons, answer and restate the pending choice in one line.

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

### Size Budget (Token Hygiene)

`proposal.md` is re-read by `/decompose`, `/implement`, `/review`, and `/spec`, often several times, so every extra line is paid for repeatedly:

- **Target ≤ 150 lines; hard cap 300 lines** (roughly 15 KB). If the design does not fit, the topic is too big: split it into separate topics (`.temp/<topic-a>/`, `.temp/<topic-b>/`), each with its own proposal, and say so.
- Record **decisions and contracts**, not the discussion that led to them. Reference existing code and specs by `path:line` or section instead of copying them.
- When revising after `/review` or user feedback, **edit the affected sections in place**. Do not append changelogs, "Review-N fixes" sections, or superseded alternatives.
- Before finishing, check the line count (e.g., `wc -l`); if it is over the cap, trim before handing off.

---

## 6. Forward Handoff & Terminal Turn Rule (CRITICAL)

After saving `.temp/<topic>/proposal.md`:

1. Link to `.temp/<topic>/proposal.md`, state its line count, and highlight the chosen Integration Strategy (`Expand-Contract` vs `In-Place`) plus any open decision.
2. This is a **checkpoint gate** (the user approves the architecture). Ask one short question in the user's language, recommended answer first:
   - *"Затверджуєш? Далі `/decompose` у `tasks.md`."* — alternatives: `/review` of `proposal.md` first, or refine the strategy.
3. **STOP YOUR TURN IMMEDIATELY.** Wait for the user's response — unless the user requested Autopilot and no decision is open, in which case proceed to `/decompose`.
