---
name: cleanup
description: Safely inspects and cleans up completed temporary feature folders in .temp/ after explicit user confirmation (via the host's interactive question tool or a numbered text prompt). Use when finishing a feature topic or via /cleanup.
---

# Cleanup (`/cleanup`)

## 1. Role & Permissions (Scoped `.temp/` Cleaner)

- **MODE**: **Temp Cleaner**.
- **ALLOWED ACTIONS**:
  - Inspecting `.temp/` directories and their files.
  - Deleting specific `.temp/<topic>/` directories (or `.temp/` itself if empty) **ONLY after explicit user confirmation** (via the host's structured question tool if available, or via explicit numbered text confirmation in chat otherwise).
- **FORBIDDEN ACTIONS (STRICT)**:
  - **NEVER delete any file or folder without first asking the user and receiving explicit confirmation**.
  - **NEVER delete or modify anything outside `.temp/`** (`src/`, `docs/`, root files).
- **LANGUAGE RULE**: Always communicate with the user and write confirmation prompts/options in the user's conversation language.

---

## 2. Cleanup Process

### Step 1: Scan & Summarize `.temp/`

1. Check if `.temp/` exists and list all `<topic>` subdirectories inside it.
2. If `.temp/` does not exist or is already empty, inform the user that the workspace is already clean and stop your turn.
3. For each `<topic>` folder in `.temp/`, inspect its files (`intent.md`, `proposal.md`, `tasks.md`, `review-N-tasks.md`, `subtasks-*.md`) and output a brief status summary in chat:
   - Topic name: `.temp/<topic>/`
   - Files present
   - Task status: e.g., `All tasks resolved ([x] / [-])` or `Has N unfinished tasks ([ ])` (note: tasks marked `- [-]` are cancelled and count as resolved, not unfinished).

### Step 2: Ask the User for Confirmation (Tool-Agnostic with Fallback)

Use the host's structured question tool if one is available (e.g., `AskUserQuestion` in Claude Code, `ask_question` in Antigravity); **if none is available, present the numbered options in plain chat text and wait for the user's explicit reply**:

- If there is **1 completed topic** (`.temp/<topic>/`):
  - Option 1: `(Recommended)` Delete `.temp/<topic>/` (work is complete).
  - Option 2: Keep `.temp/<topic>/` for local history (do not delete).
- If there are **multiple topics** in `.temp/`:
  - Option 1: `(Recommended)` Delete the current completed topic `.temp/<active-topic>/`.
  - Option 2: Delete all completed topics in `.temp/`.
  - Option 3: Keep all `.temp/` folders for local history (do not delete).
- *Warning Guard*: If a topic still has unchecked tasks (`- [ ]`), warn the user in the summary and recommend keeping it (or finishing `/implement` first) unless they explicitly want to discard it.

### Step 3: Execute Choice & Report

- If the user selected a delete option, remove only the confirmed `.temp/<topic>/` directory and verify `git status` remains clean.
- If the user selected to keep `.temp/<topic>/`, confirm that no files were deleted.
- **STOP YOUR TURN IMMEDIATELY.**
