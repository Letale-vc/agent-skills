---
name: implement
description: Executes tasks from .temp/<topic>/ using TDD (test-first, implementation, verification) in either single-task or batch mode, updating task checkboxes [ ] to [x]. Use via /implement.
---

# Implement (`/implement`)

## 1. Role & Permissions (Code & Progress Writer)

- **MODE**: **Code & Progress Writer**.
- **ALLOWED WRITES**:
  - Source code and test files required by the active task(s).
  - Toggling checkboxes `- [ ]` → `- [x]` in the active `.temp/<topic>/*tasks.md` file.
- **FORBIDDEN ACTIONS**:
  - NEVER rewrite or delete task descriptions in `.temp/<topic>/` (only toggle `[ ]` to `[x]`).
  - NEVER modify `docs/specifications/` (that is `/spec`'s responsibility) or delete `.temp/` (that is `/cleanup`'s responsibility).
  - NEVER create draft files (`SPEC.md`, `todo.md`, etc.) in the project root.
- **LANGUAGE RULE**: Always communicate with the user in the user's conversation language.

---

## 2. Topic & Active Task File Resolution

1. **Resolve `<topic>` in `.temp/`**:
   - If `.temp/` has **1 topic folder** or the topic is obvious from the chat, select it automatically and output: `Active topic: .temp/<topic>/`.
   - If `.temp/` has **2+ topic folders** and the target topic is ambiguous, list them and ask the user which topic to execute.
2. **Resolve the active task file**:
   - Look inside `.temp/<topic>/` for files containing unchecked tasks (`- [ ]`) in this priority order:
     1. `subtasks-*.md` (if a task was broken down into subtasks)
     2. `review-<N>-tasks.md` (with the highest `N`, representing the latest review fixes)
     3. `tasks.md` (the primary task list)
   - State clearly which file you are executing from (e.g., `Active task file: .temp/<topic>/tasks.md`).

---

## 3. Prerequisite Advisor & Execution Mode Selection

- **If NO task file exists in `.temp/<topic>/`**:
  - Do not start coding blindly. Present options with your recommendation:
    1. **(Recommended)** Run `/decompose` to create `.temp/<topic>/tasks.md` from `proposal.md` or our chat context.
    2. Run `/proposal` or `/interview` first if the design isn't settled.
    3. Execute a direct one-off micro-fix immediately (only if the user explicitly confirms skipping `.temp/` tasks).
- **If execution mode (Single-Task vs. Batch) hasn't been chosen yet**:
  - Ask the user before starting (with your recommendation):
    1. **Single-Task Mode**: Complete the next `- [ ]` task, mark it `[x]`, and pause for review.
    2. **Batch Mode (All at once)**: Complete all remaining `- [ ]` tasks sequentially, marking each `[x]` as it passes verification.
  - Answer any follow-up/pros-cons questions and re-present the choice until the user decides.

---

## 4. TDD Execution Loop & Non-Breaking Invariant

For each task (`- [ ] **Task N**`):
1. **Read Context & Verify Stack**:
   - Use the file paths, signatures, and code examples already embedded in the task description.
   - **Source-Driven Verification**: Never write framework/library code from stale memory. Verify the exact library version in the project manifest (`package.json`, `.csproj`, `Cargo.toml`, `pyproject.toml`, `go.mod`) and match the official documentation or established codebase patterns.
2. **Red → Green → Verify (TDD)**:
   - Write or update the automated test(s) for the task (when applicable to the artifact type).
   - Implement the code change cleanly.
   - Run build/tests to verify the **100% Working State Invariant** (nothing is broken, all tests pass).
3. **Update Progress Checkbox**:
   - Use `replace_file_content` on the active task file in `.temp/<topic>/` to change `- [ ] **Task N:` to `- [x] **Task N:` without altering the task text.
   - **Subtask Parent Sync**: When the last remaining `- [ ]` item in a `subtasks-<id>.md` file is marked `- [x]`, also mark its corresponding parent task `- [ ]` → `- [x]` in `tasks.md` (or `review-N-tasks.md`) so the parent task list stays accurate.
4. **Mode Control**:
   - In **Single-Task Mode**: Stop after completing 1 task and run Forward Handoff.
   - In **Batch Mode**: Continue to the next `- [ ]` task until all tasks in the file are `[x]` (stop early only if a blocker or architectural ambiguity arises).

---

## 5. Forward Handoff & Terminal Turn Rule (CRITICAL)

- **When stopping after 1 task (Single-Task Mode, with more `- [ ]` tasks remaining)**:
  - **Option 1 (Recommended)**: Continue to the next task (`Task N+1`) in `/implement` (or switch to Batch Mode for the rest).
  - **Option 2**: Run `/review` on the completed task before moving on.
  - **Option 3**: Split the upcoming task into smaller subtasks via `/decompose`.
- **When all tasks in the active file are completed (`[x]`)**:
  - **Option 1 (Recommended)**: Run `/review` to perform a read-only quality and architecture audit of the completed work.
  - **Option 2**: If there is another pending task file in `.temp/<topic>/`, proceed to it.
- **STOP YOUR TURN IMMEDIATELY** after presenting the handoff options.

