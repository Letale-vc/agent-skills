---
name: decompose
description: Breaks down a feature request, technical proposal (RFC), chat discussion, /review or /audit findings, or an /architect roadmap into independent, non-breaking vertical slice tasks in .temp/<topic>/. Never overwrites existing task files. Use when planning implementation steps, when a clear feature is too big for one edit, after a proposal is approved, after the user picks findings to fix, or via /decompose.
---

# Decompose (`/decompose`)

## 1. Role & Permissions (Scoped Append-Only Task Writer)

- **MODE**: **Scoped Append-Only Writer**.
- **ALLOWED WRITES**:
  - New task files inside `.temp/<topic>/`:
    - `.temp/<topic>/tasks.md` (initial task breakdown)
    - `.temp/<topic>/review-<N>-tasks.md` (tasks created from `/review` findings, e.g., `review-1-tasks.md`, `review-2-tasks.md`)
    - `.temp/<topic>/subtasks-<id>.md` or `.temp/<topic>/subtasks-r<M>-<id>.md` (when splitting a specific existing task into smaller subtasks)
  - `.gitignore` (only to ensure `.temp/` is ignored)
- **FORBIDDEN ACTIONS**:
  - **NEVER overwrite or rewrite an existing task file** (`tasks.md`, `review-1-tasks.md`, etc.). Every new iteration of task breakdown must be saved as a separate file in `.temp/<topic>/`.
  - NEVER modify `src/`, tests, or `docs/`.
- **LANGUAGE RULE**: Always communicate with the user and write task files in the user's conversation language.

---

## 2. Topic Resolution & `.gitignore` Guard

1. Check `.gitignore` in the project root. If no existing line already ignores it (`.temp`, `.temp/`, `/.temp/`, ignoring trailing whitespace or `\r`), append `.temp/` once; never add a duplicate entry.
2. Inspect `.temp/`:
   - If **1 topic folder** exists or the topic is obvious from the chat, select it automatically and output: `Active topic: .temp/<topic>/`.
   - If **2+ topic folders** exist and it is ambiguous which one applies, list them and ask the user which topic to use.

---

## 3. Source Selection (Default-Proceed)

Pick the source from the state of `.temp/<topic>/` and the recent chat, announce it in one line, and proceed — writing a new file in `.temp/<topic>/` is safe and never overwrites anything:

1. **Right after `/review` reported findings** → convert the findings the user agreed to into `.temp/<topic>/review-<N>-tasks.md`.
2. **Right after `/architect` reported a roadmap** → write the steps the user chose into `.temp/arch-<area>/tasks.md` in roadmap order, so the roadmap outlives the chat (if that topic already has a `tasks.md`, use a new topic such as `arch-<area>-2` — task files are never overwritten). Header: **Goal** = the target structure in one line, **Constraints** = its dependency rules. A `tasks` step becomes normal tasks (an Expand-Contract move is several). A `/proposal` step becomes one task with the step summary, the findings it closes and a `**Design**:` line naming its own topic (Invariant 3).
3. **The user asked to split a specific task** → `.temp/<topic>/subtasks-<id>.md`.
4. **An approved `proposal.md` exists and `tasks.md` does not** → decompose `proposal.md` into `tasks.md`.
5. **Otherwise (Fast-Track)** → decompose directly from the chat discussion into `tasks.md`.

Ask the user only when the sources genuinely conflict (e.g., the chat contradicts `proposal.md`) or when requirements or architecture are still unclear — then recommend stepping back to `/interview` or `/proposal`.

### Inside a Git Worktree

`.temp/` is git-ignored, so a worktree does not have it. If you are inside a worktree (`git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`), write task files to `.temp/<topic>/` at the worktree root (copy the topic folder from the main checkout first if it exists there). Never write to the main checkout by absolute path.

---

## 4. Core Task Breakdown Rules (CRITICAL INVARIANTS)

### Invariant 1: Embedded Context Header (`tasks.md`) & Parent Link (`subtasks-*.md`, Design Topics)

- **When creating `.temp/<topic>/tasks.md`** (especially in **Fast-Track mode** where no `proposal.md` exists), always place a compact 3–4 line header at the very top of `tasks.md`:

  ```markdown
  ## Context & Intent
  - **Goal**: <1–2 sentences on what is being built and why>
  - **Strategy**: <In-Place OR Expand-Contract (Parallel)>
  - **Constraints**: <Key non-breaking invariants or boundaries>
  ```

- **When creating a subtask file**, prevent ID collisions between `tasks.md` and `review-<M>-tasks.md`:
  - Name the file `subtasks-<N>.md` (if splitting `Task N` from `tasks.md`) or `subtasks-r<M>-<N>.md` (if splitting `Task N` from `review-<M>-tasks.md`).
  - Always include an explicit parent pointer on the first line after the title:

    ```markdown
    Parent: tasks.md#Task 3
    ```

    (or `Parent: review-1-tasks.md#Task 3`) so `/implement` knows the exact parent file and task to mark `[x]` when all subtasks finish.

- **When creating `tasks.md` in a topic that another task file's `**Design**:` line names** (search `.temp/` for the topic name), put `Parent: ../<that-topic>/<file>#Task N` on the line right after the `## Context & Intent` header, so `/implement` closes that roadmap task once this topic is done.

### Invariant 2: 100% Working Project State After Every Single Task

- Tasks must be **non-breaking vertical slices**. After completing any individual task, the project must compile cleanly and pass all existing and new tests.
- **If `Expand-Contract` (Parallel Implementation) was chosen**:
  - *Tasks 1..K*: Build and unit-test the new method/class/module in isolation alongside the old code (zero impact on existing callers).
  - *Task K+1*: Switch callers to the new implementation and apply the chosen old-code policy (**Deprecate** or **Remove**), verifying all integration tests pass.
- **Generalize-first tasks**: when a feature would reuse a near-duplicate of existing code, put the extraction in its **own earlier task** (behavior-preserving refactor: extract the shared helper, switch the existing copies, existing tests stay green; resolve or flag divergent copies there). Feature tasks then build on the shared helper. Likewise, when two tasks in the breakdown would write the same logic, make one of them introduce the shared piece and the other reuse it.

### Invariant 3: Self-Contained Context & Standard Checkbox States

Each task must contain enough concrete context that `/implement` does not need to search the codebase from scratch:

- **Checkbox header**: `- [ ] **Task N: <Clear Actionable Title>**`
  - Supported status markers across the lifecycle:
    - `- [ ]` — Pending (to be executed)
    - `- [x]` — Completed and verified
    - `- [-] ~~**Task N: <Title>**~~ (cancelled: <reason>)` — Cancelled / Superseded (treated as resolved by `/implement` and `/cleanup`)
- **Model**: `high` or `standard` — which model tier should implement the task when it is delegated:
  - `high`: core or non-trivial logic, public APIs and contracts, concurrency, memory/unsafe/native code, security, performance-critical paths, cross-module changes, or anything hard to verify with tests.
  - `standard`: mechanical, localized, fully specified changes (renames, wiring, UI tweaks, config, docs, adding tests for existing behavior).
  - When in doubt, use `high`. The concrete model per tier comes from the project's instructions (e.g., in Claude Code `high` → `opus`, `standard` → `sonnet`).
- **Target files**: Exact paths to create or modify.
- **Context & Code Examples**: Existing signatures, interfaces, data structures, and short code snippets showing how the change fits in. Keep it to what `/implement` needs: reference existing code by `path:line` instead of pasting large blocks.
- **Reuse**: Which existing code the task must call or extend instead of re-writing (`path:line`), or `none found (searched: <terms>)`. Fill it from the proposal's Reuse section or, in Fast-Track, from your own search (`/using-agent-skills`, behavior 6) — never leave `/implement` to discover it.
- **Verification / Tests**: The smallest check that proves the task is done — one of: an existing test that already covers it (name it); one new test or one new case in an existing test for new logic that can break silently (branch, parser, math, state, contract, bug fix); `build + existing tests` for wiring, config/defaults, renames, UI text/layout, docs, or behavior-preserving refactors. Follow the test rules in `/implement` (section 4); never write "add tests" by default. If part of the verification can only be done by the user (running the app, a device, a game, a visual check), add a `Manual check:` line saying exactly what to check — `/implement` pauses there in Batch mode.
- **Design** (only when the task's design is still open, e.g. an `/architect` step routed to `/proposal`): `**Design**: /proposal first in .temp/<own-topic>/` in place of Target files and Context, which do not exist yet. `/implement` stops before such a task instead of guessing the design. Give it no Verification or completion rule of its own: it closes when the last task of its own topic does, through the `Parent:` line that topic's `tasks.md` gets (Invariant 1) — an approved proposal alone does not close it.

Example task block:

```markdown
- [ ] **Task 3: Read flask charges from the Charges component**
  - **Model**: high
  - **Target files**: `src/Reader/Components/Charges.cs`, `tests/Reader/ChargesTests.cs`
  - **Context**: `Charges` mirrors `Life` (`src/Reader/Components/Life.cs:12`); offsets live in `ChargesOffsets`.
  - **Reuse**: read through `ComponentReader.ReadStruct` (`src/Reader/Components/ComponentReader.cs:30`), as `Life` does.
  - **Verification**: `ChargesTests.Reads_current_and_max` fails first, then passes; full test project green.
  - **Manual check**: in the app, the flask panel shows the same charges as the game.
```

---

## 5. Forward Handoff & Terminal Turn Rule (CRITICAL)

After creating the new task file (`.temp/<topic>/tasks.md`, `review-<N>-tasks.md`, or `subtasks-<id>.md`):

1. Link to the newly created file and list the tasks one line each (title, `Model` tier, and `Manual check` / `Design` marker if any).
2. This is a **checkpoint gate** (code changes start next). Ask one short question in the user's language, Batch first:
   - *"Запускаю `/implement` у Batch (усі задачі по черзі)?"* — alternatives: Single-Task Mode (one task, then pause), or `/review` of the breakdown first.
3. **STOP YOUR TURN IMMEDIATELY.** Do not start implementing tasks in this turn — unless the user requested Autopilot, in which case start `/implement` in Batch mode right away.
