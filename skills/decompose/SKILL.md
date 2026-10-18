---
name: decompose
description: Breaks down a proposal, chat discussion, review findings, or a complex task into independent, non-breaking vertical slice tasks in .temp/<topic>/. Never overwrites existing task files. Use via /decompose.
---

# Decompose (`/decompose`)

## 1. Role & Permissions (Scoped Append-Only Task Writer)

- **MODE**: **Scoped Append-Only Writer**.
- **ALLOWED WRITES**:
  - New task files inside `.temp/<topic>/`:
    - `.temp/<topic>/tasks.md` (initial task breakdown)
    - `.temp/<topic>/review-<N>-tasks.md` (tasks created from `/review` findings, e.g., `review-1-tasks.md`, `review-2-tasks.md`)
    - `.temp/<topic>/subtasks-<id>.md` (when splitting a specific existing task into smaller subtasks)
  - `.gitignore` (only to ensure `.temp/` is ignored)
- **FORBIDDEN ACTIONS**:
  - **NEVER overwrite or rewrite an existing task file** (`tasks.md`, `review-1-tasks.md`, etc.). Every new iteration of task breakdown must be saved as a separate file in `.temp/<topic>/`.
  - NEVER modify `src/`, tests, or `docs/`.
- **LANGUAGE RULE**: Always communicate with the user and write task files in the user's conversation language.

---

## 2. Topic Resolution & `.gitignore` Guard

1. Ensure `.temp/` is present in `.gitignore`.
2. Inspect `.temp/`:
   - If **1 topic folder** exists or the topic is obvious from the chat, select it automatically and output: `Active topic: .temp/<topic>/`.
   - If **2+ topic folders** exist and it is ambiguous which one applies, list them and ask the user which topic to use.

---

## 3. Prerequisite Advisor (Full Scenario Menu)

Evaluate the current state of `.temp/<topic>/` and recent chat messages. If there is any ambiguity about what to decompose, present the full menu of relevant options with your recommendation:

1. **Decompose `.temp/<topic>/proposal.md` into `.temp/<topic>/tasks.md`** *(Recommended when an approved `proposal.md` exists and `tasks.md` has not been created yet)*.
2. **Decompose directly from our chat discussion into `.temp/<topic>/tasks.md`** *(Recommended when the task was already discussed and shaped in chat and doesn't need a formal `proposal.md`)*.
3. **Convert recent `/review` findings into `.temp/<topic>/review-<N>-tasks.md`** *(Recommended right after `/review` reported issues — keeps `tasks.md` untouched and creates the next `review-N-tasks.md`)*.
4. **Split a specific task into smaller steps in `.temp/<topic>/subtasks-<task-id>.md`** *(Recommended when the user wants finer granularity for a particular task without mutating `tasks.md`)*.
5. **Step back to `/proposal` or `/interview` first** *(Recommended if architectural decisions or requirements are still unclear)*.

- Remember: the user can ask about pros/cons or clarify any option. Answer their questions and **re-present the options** until they choose.

---

## 4. Core Task Breakdown Rules (CRITICAL INVARIANTS)

### Invariant 1: Embedded Context Header for Fast-Track (`tasks.md`)
When creating `.temp/<topic>/tasks.md` (especially in **Fast-Track mode** where `intent.md` and `proposal.md` were skipped), always place a compact 3–4 line header at the very top of `tasks.md`:
```markdown
## Context & Intent
- **Goal**: <1–2 sentences on what is being built and why>
- **Strategy**: <In-Place OR Expand-Contract (Parallel)>
- **Constraints**: <Key non-breaking invariants or boundaries>
```
This ensures that if `/implement` or `/review` runs later in a fresh chat session without `intent.md`/`proposal.md`, the agent still has the full architectural intent right inside `tasks.md`.

### Invariant 2: 100% Working Project State After Every Single Task
- Tasks must be **non-breaking vertical slices**. After completing any individual task, the project must compile cleanly and pass all existing and new tests.
- **If `Expand-Contract` (Parallel Implementation) was chosen**:
  - *Tasks 1..K*: Build and unit-test the new method/class/module in isolation alongside the old code (zero impact on existing callers).
  - *Task K+1*: Switch callers to the new implementation and apply the chosen old-code policy (**Deprecate** or **Remove**), verifying all integration tests pass.

### Invariant 3: Self-Contained Context (Zero Re-Search Cost)
Each task must contain enough concrete context that `/implement` does not need to search the codebase from scratch:
- **Checkbox header**: `- [ ] **Task N: <Clear Actionable Title>**`
- **Target files**: Exact paths to create or modify.
- **Context & Code Examples**: Existing signatures, interfaces, data structures, and short code snippets showing how the change fits in.
- **Verification / Tests**: What unit/integration tests to write and run to prove the task is done.

---

## 5. Forward Handoff & Terminal Turn Rule (CRITICAL)

After creating the new task file (`.temp/<topic>/tasks.md`, `review-<N>-tasks.md`, or `subtasks-<id>.md`):
1. Link to the newly created file and summarize the number of tasks.
2. Ask the user how they want to execute `/implement` (with your recommendation):
   - **Option 1 — Single-Task Mode**: Execute **one task at a time** via `/implement` and pause after each task for inspection *(Recommended for complex logic or high-risk changes)*.
   - **Option 2 — Batch Mode (All at once)**: Execute **all tasks sequentially** via `/implement` with intermediate checks *(Recommended when tasks are clear and well-isolated)*.
   - **Option 3**: Run `/review` on the task breakdown first, or split a specific task into smaller subtasks.
   - *Note*: If the user asks questions or pros/cons, explain and re-present these options.
3. **STOP YOUR TURN IMMEDIATELY.** Do not start implementing tasks in this turn.

