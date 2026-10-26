---
name: implement
description: Executes tasks from .temp/<topic>/ using TDD (Red -> Green -> Verify), in Batch mode by default (single-task on request), updating task checkboxes ([x] completed or [-] cancelled). Use when writing code/tests for planned tasks, when the user says to start, continue or resume the tasks, or via /implement.
---

# Implement (`/implement`)

## 1. Role & Permissions (Code & Progress Writer)

- **MODE**: **Code & Progress Writer**.
- **ALLOWED WRITES**:
  - Source code and test files required by the active task(s).
  - Updating task status in the active `.temp/<topic>/*tasks.md` file:
    - `- [ ]` → `- [x]` when a task is completed and verified.
    - `- [ ] **Task N: <Title>**` → `- [-] ~~**Task N: <Title>**~~ (cancelled: <reason>)` when the user or architectural context confirms a task is obsolete/superseded.
- **FORBIDDEN ACTIONS**:
  - NEVER delete task blocks or rewrite active task descriptions in `.temp/<topic>/` (only update status `[ ]` → `[x]` or `[-]`).
  - NEVER modify `docs/specifications/` (that is `/spec`'s responsibility) or delete `.temp/` (that is `/cleanup`'s responsibility).
  - NEVER create draft files (`SPEC.md`, `todo.md`, etc.) in the project root.
- **LANGUAGE RULE**: Always communicate with the user in the user's conversation language.

---

## 2. Topic & Active Task File Resolution

1. **Resolve `<topic>` in `.temp/`**:
   - If `.temp/` has **1 topic folder** or the topic is obvious from the chat, select it automatically and output: `Active topic: .temp/<topic>/`.
   - If `.temp/` has **2+ topic folders** and the target topic is ambiguous, list them and ask the user which topic to execute.
2. **Resolve the active task file**:
   - Look inside `.temp/<topic>/` for files containing unchecked tasks (`- [ ]`) in this priority order (tasks marked `[x]` or `[-]` are already resolved):
     1. `subtasks-*.md` (if a task was broken down into subtasks)
     2. `review-<N>-tasks.md` (with the highest `N`, representing the latest review fixes)
     3. `tasks.md` (the primary task list)
   - State clearly which file you are executing from (e.g., `Active task file: .temp/<topic>/tasks.md`).
3. **Inside a Git Worktree**:
   - `.temp/` is git-ignored, so a worktree does not have it. If you are inside a worktree (`git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`) and `.temp/<topic>/` is missing at the worktree root, copy the topic folder from the main checkout once and work on that copy. Never write to the main checkout by absolute path.
4. **Context Hygiene (Token Saving)**:
   - **NEVER read full contents of resolved (`100% [x]` / `[-]`) task files into your context window.** Once a file has zero remaining `- [ ]` items, treat it as closed history so obsolete code snippets from earlier iterations do not pollute your context. Read only the **active task file** (plus `proposal.md` if present, or the `## Context & Intent` header in `tasks.md`).
   - If the active task file is longer than ~300 lines, read the `## Context & Intent` header and then only the current task block (locate `**Task N:` by search, read it by offset/limit). Read `proposal.md` by section, not in full, and never re-read a file that has not changed since you last read it.

---

## 3. Prerequisite Advisor, Branch Check & Execution Mode

- **If NO task file exists in `.temp/<topic>/`**:
  - Do not start coding blindly:
    - **(Recommended, default)** Run `/decompose` to create `.temp/<topic>/tasks.md` from `proposal.md` or our chat context, then return here.
    - Run `/proposal` or `/interview` first if the design isn't settled (ask the user — this is a decision gate).
    - Execute a direct one-off micro-fix only if the user explicitly asks to skip `.temp/` tasks.
- **Git Branch Check (When starting the first task of a feature on `main`/`master`)**:
  - If the repo is currently on `main` or `master` and no feature branch has been created for `<topic>`, ask once whether to create `feat/<topic>` before coding (recommended: yes). On any other branch, just state it in the start line.
- **Execution Mode — Batch by Default**:
  - Unless the user asked for Single-Task Mode, run **Batch Mode**: complete all remaining `- [ ]` tasks of the active file sequentially, marking each `[x]` as it passes verification, without stopping between tasks.
  - Announce it in one line in the user's language (e.g., *"Batch: задачі 3–7 з `tasks.md` по черзі. Напиши «стоп», щоб зупинитись після поточної."*) — do not ask.
  - **Single-Task Mode** (only on request, e.g., *"по одній"*, *"single"*): complete the next `- [ ]` task, mark it `[x]`, and pause for inspection.
- **Delegation & Model Tag**:
  - When tasks run in subagents, give each subagent the full task text plus the `## Context & Intent` header, and choose its model from the task's `**Model**:` tag via the project's mapping (e.g., in Claude Code `high` → `opus`, `standard` → `sonnet`). A user instruction overrides the tag; a missing tag counts as `high`.
  - A subagent working in a worktree does not touch `.temp/`; you update the checkbox after verifying its report.

---

## 4. TDD Execution Loop & Non-Breaking Invariant

For each task (`- [ ] **Task N**`):

1. **Read Context & Verify Stack**:
   - Use the file paths, signatures, and code examples already embedded in the task description.
   - **Source-Driven Verification**: Never write framework/library code from stale memory. Verify the exact library version in the project manifest (`package.json`, `.csproj`, `Cargo.toml`, `pyproject.toml`, `go.mod`) and match the official documentation or established codebase patterns.
   - **Reuse Check** (`/using-agent-skills`, behavior 6): use the task's `**Reuse**:` line, and before writing any new helper, method, or class still search for existing code with the same names, data, or algorithm (the task list can miss it). If you are about to copy an existing block or write one that mirrors it:
     - small, local, covered by tests → extract the shared piece within this task and switch the existing copy to it (behavior-preserving; existing tests must stay green);
     - large, cross-module, or touching a public contract → do not duplicate silently: stop (in Batch too) and propose a generalize-first task, recommended answer first.
   - State the outcome in the task report: `Reuse: <used/extracted path>` or `Reuse: none found`.
2. **Red → Green → Verify (TDD Where a Test Earns Its Place)**:
   - **Does this task need a new test?** The task's `**Verification**:` line decides. Without one, write a new test only when the change adds or changes logic that can break silently: a branch, a parser, calculation or layout math, state handling, concurrency, a public contract, or a bug fix (regression test). **No new test** for wiring, renames and moves, config or default values, UI layout and text, docs, pass-through code, or behavior-preserving refactors that existing tests already cover (those tests are the safety net). Then Verify = build + the area's existing tests (+ manual check).
   - **Extend before adding**: if a test for the same unit already exists, add a case (another `InlineData` / parameter row) or an assertion there instead of a new method or file. One test per behavior, not per method or branch.
   - **No low-value tests**: never write tests that restate a constant or literal, mirror the implementation line by line, only assert "not null", or silently pass when the environment is missing (use the framework's skip mechanism instead of an early `return`).
   - **Obsolete tests are part of the change**: update or delete tests that the change made wrong or redundant; do not leave them beside the new ones.
   - **Red (Write & Run Failing Test)**: When a new or extended test is warranted, **run it first to confirm it fails (or fails to compile) for the expected reason**. Never skip verifying the Red phase, as that leads to tautological tests that always pass.
   - **Green (Implement)**: Write the minimal, clean code change required to satisfy the test and task requirements.
   - **Verify (100% Working State Invariant)**: Run the build/test suite to confirm the new test passes and zero existing tests regressed.
3. **Update Progress Checkbox (Tool-Agnostic)**:
   - Use your file-editing tool on the active task file in `.temp/<topic>/` to change `- [ ] **Task N:` to `- [x] **Task N:` (or `- [-] ~~**Task N: <Title>**~~ (cancelled: <reason>)` if the task was superseded/cancelled) without altering the rest of the task text.
   - **Subtask Parent Sync**: When the last remaining `- [ ]` item in a `subtasks-*.md` file is resolved (`[x]` or `[-]`), inspect the `Parent: <parent-file>#Task <M>` header at the top of `subtasks-*.md` (defaulting to `tasks.md` if omitted) and mark the corresponding parent `Task M` as `- [x]` in that exact parent file. The same applies to a topic's `tasks.md` that carries a `Parent:` line (a topic opened for a `**Design**:` task): its path, e.g. `../arch-<area>/tasks.md`, points into the other topic.
4. **Mode Control**:
   - In **Single-Task Mode**: Stop after completing 1 task and run Forward Handoff.
   - In **Batch / Autopilot Mode**: Continue to the next `- [ ]` task until all tasks in the file are resolved (`[x]` or `[-]`). Stop early only when:
     - a blocker or architectural ambiguity arises, or the same failure survives 3 fix attempts;
     - the next task has a `**Design**:` line — its design is not settled yet, so recommend `/proposal` in the topic that line names (or continuing that topic if it already exists) instead of inventing one;
     - the Reuse Check found a near-duplicate whose extraction is too large for the current task;
     - a task's verification needs a **manual check** only the user can do (running the app, a device, a game, a visual UI check) — finish everything automatable first, then give the user a short numbered checklist in their language and wait for the result;
     - the user says stop.

---

## 5. Forward Handoff & Terminal Turn Rule (CRITICAL)

- **When stopping after 1 task (Single-Task Mode, with more `- [ ]` tasks remaining)**:
  - Report the task result and name the next task in one line (recommended: continue, or switch to Batch for the rest; alternative: `/git` for an atomic commit while the project is green). **STOP YOUR TURN** and wait.
- **When stopping early in Batch Mode** (blocker, failure, manual check, design task): report what is done, what blocks, and the one question or checklist the user must answer. **STOP YOUR TURN**.
- **When all tasks in the active file are resolved (`[x]` / `[-]`)**:
  - Summarize the completed tasks (one line each) and **proceed automatically to `/review`** (zero-write, safe), announcing it in one line. If the user asked to skip review, offer `/git` instead.
  - **Fresh eyes**: when the host can spawn a subagent, run `/review` there (model tier `high`) and give it only the topic path, the active task file and the diff range — not this session's reasoning. A reviewer that shares the author's context tends to share the author's blind spots. Relay its report and present its gate yourself (`CHANGES RECOMMENDED` → the user picks findings; `APPROVED` → its next step). Without subagent support, run `/review` here.
  - If another pending task file exists in `.temp/<topic>/`, mention it as the next step after the review.
