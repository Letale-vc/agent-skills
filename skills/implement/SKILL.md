---
name: implement
description: Executes tasks from .temp/<topic>/ using TDD (Red -> Green -> Verify) in single-task, batch, or autopilot mode, updating task checkboxes ([x] completed or [-] cancelled). Use when writing code/tests for planned tasks or via /implement.
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
3. **Context Hygiene (Token Saving)**:
   - **NEVER read full contents of resolved (`100% [x]` / `[-]`) task files into your context window.** Once a file has zero remaining `- [ ]` items, treat it as closed history so obsolete code snippets from earlier iterations do not pollute your context. Read only the **active task file** (plus `proposal.md`/`intent.md` if present, or the `## Context & Intent` header in `tasks.md`).

---

## 3. Prerequisite Advisor, Branch Check & Execution Mode Selection

- **If NO task file exists in `.temp/<topic>/`**:
  - Do not start coding blindly. Present options with your recommendation:
    1. **(Recommended)** Run `/decompose` to create `.temp/<topic>/tasks.md` from `proposal.md` or our chat context.
    2. Run `/proposal` or `/interview` first if the design isn't settled.
    3. Execute a direct one-off micro-fix immediately (only if the user explicitly confirms skipping `.temp/` tasks).
- **Git Branch Check (When starting the first task of a feature on `main`/`master`)**:
  - If the repo is currently on `main` or `master` and no feature branch has been created for `<topic>`, mention the current branch when asking for execution mode so the user can optionally ask to create `feat/<topic>` before coding.
- **If execution mode (Single-Task vs. Batch) hasn't been chosen yet** (and Autopilot was not already requested):
  - Ask the user before starting (with your recommendation):
    1. **Single-Task Mode**: Complete the next `- [ ]` task, mark it `[x]`, and pause for inspection.
    2. **Batch Mode (All at once)**: Complete all remaining `- [ ]` tasks sequentially, marking each `[x]` as it passes verification.
  - Answer any follow-up/pros-cons questions and re-present the choice until the user decides.

---

## 4. TDD Execution Loop & Non-Breaking Invariant

For each task (`- [ ] **Task N**`):

1. **Read Context & Verify Stack**:
   - Use the file paths, signatures, and code examples already embedded in the task description.
   - **Source-Driven Verification**: Never write framework/library code from stale memory. Verify the exact library version in the project manifest (`package.json`, `.csproj`, `Cargo.toml`, `pyproject.toml`, `go.mod`) and match the official documentation or established codebase patterns.
2. **Red → Green → Verify (Strict TDD)**:
   - **Red (Write & Run Failing Test)**: Write or update the automated test(s) for the task (when applicable to the artifact type) and **run the test first to confirm it fails (or fails to compile) for the expected reason**. Never skip verifying the Red phase, as that leads to tautological tests that always pass.
   - **Green (Implement)**: Write the minimal, clean code change required to satisfy the test and task requirements.
   - **Verify (100% Working State Invariant)**: Run the build/test suite to confirm the new test passes and zero existing tests regressed.
3. **Update Progress Checkbox (Tool-Agnostic)**:
   - Use your file-editing tool on the active task file in `.temp/<topic>/` to change `- [ ] **Task N:` to `- [x] **Task N:` (or `- [-] ~~**Task N: <Title>**~~ (cancelled: <reason>)` if the task was superseded/cancelled) without altering the rest of the task text.
   - **Subtask Parent Sync**: When the last remaining `- [ ]` item in a `subtasks-*.md` file is resolved (`[x]` or `[-]`), inspect the `Parent: <parent-file>#Task <M>` header at the top of `subtasks-*.md` (defaulting to `tasks.md` if omitted) and mark the corresponding parent `Task M` as `- [x]` in that exact parent file.
4. **Mode Control**:
   - In **Single-Task Mode**: Stop after completing 1 task and run Forward Handoff.
   - In **Batch / Autopilot Mode**: Continue to the next `- [ ]` task until all tasks in the file are resolved (`[x]` or `[-]`), stopping early only if a blocker or architectural ambiguity arises.

---

## 5. Forward Handoff & Terminal Turn Rule (CRITICAL)

- **When stopping after 1 task (Single-Task Mode, with more `- [ ]` tasks remaining)**:
  - **Option 1 (Recommended)**: Continue to the next task (`Task N+1`) in `/implement` (or switch to Batch Mode for the rest).
  - **Option 2**: Run `/git` to create a clean atomic commit for the completed task while the project is 100% green, then continue.
  - **Option 3**: Run `/review` on the completed task or split the upcoming task into subtasks via `/decompose`.
- **When all tasks in the active file are resolved (`[x]` / `[-]`)**:
  - **Option 1 (Recommended)**: Run `/review` to perform a zero-write quality, test, and architecture audit of the completed work.
  - **Option 2**: Run `/git` to organize the completed changes into atomic commits.
  - **Option 3**: If there is another pending task file in `.temp/<topic>/`, proceed to it.
- **STOP YOUR TURN IMMEDIATELY** after presenting the handoff options (unless running in user-requested Autopilot mode, in which case proceed automatically to `/review`).
