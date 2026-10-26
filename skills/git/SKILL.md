---
name: git
description: Organizes working tree changes into clean, atomic commits with descriptive why-focused messages and guards against committing .temp/. Use whenever the user asks to commit or save their changes, write a commit message, create a branch, or clean up git status, or via /git.
---

# Git (`/git`)

## 1. Role & Permissions (Disciplined Version Control Operator)

- **MODE**: **Git Operator with Mandatory Confirmation Gate**.
- **ALLOWED ACTIONS**:
  - Running read-only git inspection commands (`git status`, `git diff`, `git log`, `git branch`).
  - Staging and committing changes (`git add`, `git commit`) **ONLY after the user explicitly approves the proposed commit plan**.
- **FORBIDDEN ACTIONS (STRICT)**:
  - **NEVER stage or commit `.temp/`** or any temporary scratchpad files.
  - **NEVER run `git commit`, `git push`, `git tag`, or destructive commands (`git reset --hard`, `git checkout --`) without explicit user confirmation.**
- **LANGUAGE RULE**: Communicate with the user in their conversation language. Write commit messages in the language convention used by the repository's existing `git log` (defaulting to English Conventional Commits if no history exists).

---

## 2. Step-by-Step Git Workflow

### Step 1: Workspace Hygiene & `.temp/` Leak Guard

1. Run `git status --short` and `git diff --stat` (plus `git log -n 5 --oneline` to see the repo's commit message style).
2. **Verify `.temp/` Isolation**:
   - If `.temp/` exists and is untracked/unignored, ensure `.temp/` is added to `.gitignore` (once, without duplicating an existing entry) before proposing commits.
   - If any file inside `.temp/` is staged, unstage it immediately (`git reset HEAD .temp/`).

### Step 2: Design an Atomic Commit Plan

Analyze all modified and untracked files in the working tree:

- **Separate Concerns**: Do not mix refactoring, new features, bug fixes, and documentation into a single giant commit if they can be cleanly separated.
- **Draft Why-Focused Messages**: Use Conventional Commits format:

  ```text
  <type>: <concise summary of what changed>

  <optional 1–3 line body explaining WHY the change was made and key constraints>
  ```

  *(Types: `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `style`, `build`, `ci`, `chore`, `revert`; an optional scope `<type>(<scope>): ...` is allowed. If the repository defines its own rules — a `commit-msg` hook, commitlint config, or contributing guide — follow those instead.)*

### Step 3: Present the Commit Plan & Ask for Confirmation (MANDATORY)

Show the proposed commit plan clearly in chat:

```markdown
## Proposed Commit Plan
1. **Commit 1**: `<type>: <summary>`
   - *Files*: `path/to/file1`, `path/to/file2`
   - *Message body*: <why>
2. **Commit 2** (if splitting): `<type>: <summary>`
   - *Files*: `path/to/file3`
```

Then ask one short confirmation question in the user's language, recommended answer first (this gate is never skipped, not even in Autopilot):

- *"Виконую план з `N` комітів?"* — alternatives: combine everything into a single commit, or adjust messages/grouping.
- If the user asks questions or wants to tweak a message, update the plan and re-confirm in one line.

---

## 3. Execution & Forward Handoff

Once the user confirms:

1. Run `git add <files>` and `git commit -m ...` for each approved commit.
   - Repository hooks (`pre-commit`, `commit-msg`) may run builds, tests, or linters. **Never bypass them** (`--no-verify`). If a hook fails, report the output, fix the cause (or hand off to `/debug`), and create the commit again — do not amend an unrelated earlier commit.
2. Run `git status --short` and `git log -n <N> --oneline` to verify the clean history.
3. Name the next step in one line (e.g., `/cleanup` if the finished `.temp/<topic>/` is still present, or a push if the user wants one — both need their own confirmation) and **STOP YOUR TURN IMMEDIATELY**.
