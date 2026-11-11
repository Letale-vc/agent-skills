---
name: git
description: Turns working tree changes into clean, atomic Conventional Commits with why-focused messages after one plan confirmation, keeps .temp/ out of history, and afterwards offers to delete the finished .temp/<topic>/ folder. Use whenever the user asks to commit or save changes, write a commit message, create a branch, clean up git status, tidy the workspace or remove finished plans and task files from .temp/, or via /pas:git.
argument-hint: "[topic]"
allowed-tools:
  - Bash(git status *)
  - Bash(git diff *)
  - Bash(git log *)
  - PowerShell(git status *)
  - PowerShell(git diff *)
  - PowerShell(git log *)
---

# Git (`/pas:git`)

Mode: writes git history and deletes `.temp/<topic>/`, both only after gate 1 of [rules.md](${CLAUDE_PLUGIN_ROOT}/shared/rules.md) §5, which is never auto-approved: not in `/pas:flow`, not in a subagent (it reports `blocked:` with the plan instead). Everything else follows the shared rules.

## Current state

* Status: !`git status --short --branch`
* Staged: !`git diff --cached --stat`
* Unstaged: !`git diff --stat`
* Recent commits (message style): !`git log -n 8 --oneline --all`

If the lines above show the commands instead of their output (shell execution disabled, another host), run them yourself.

## 1. Guard and read the rules

1. Apply the `.gitignore` guard ([rules.md](${CLAUDE_PLUGIN_ROOT}/shared/rules.md) §2). A staged `.temp/` path is unstaged at once; a `.temp/` already tracked in history goes into the plan as its own `git rm -r --cached .temp/` commit.
2. The commit convention comes from the repository: a `commit-msg` hook, commitlint or contributing rules, else the style of the log above, else English Conventional Commits (`feat|fix|perf|refactor|test|docs|style|build|ci|chore|revert`, optional scope).
3. Branch rules: when the project forbids committing to the default branch, or the user asked for a branch, create `<type>/<short-slug>` before the first commit and say so in the plan.

## 2. Plan atomic commits

* Read the per-file diffs you need (`git diff <path>`), not one huge diff: the stats above are the map.
* One concern per commit: a refactor, a feature, a fix and docs are separate when their files separate cleanly. A test goes with the code it covers.
* Subject: what changed, imperative, ≤ 72 characters. Body (1–3 lines): why, and the constraint a reader would miss.
* **Leave out and name** anything that does not belong to the work: secrets and local config (`.env`, keys, `*.local.*`), build output, large binaries, editor files, and changes that look like another session's or agent's work. Ask about them; never sweep them in.

```markdown
## Commit plan
1. `fix(sync): retry uploads with backoff`: `src/sync/upload.ts`, `test/sync/upload.test.ts`
   Why: a dead server got 10 instant retries.
2. `docs: describe the retry policy`: `docs/sync.md`
Left out: `.env.local` (local secrets).
```

## 3. Gate

Show the plan and ask one short question, recommended answer first: run the N commits / one commit / adjust. A tweak to a message updates the plan and is re-confirmed in one line.

## 4. Commit

1. Stage explicit paths only (`git add <paths>`), never `git add -A` or `git add .`.
2. Commit each approved entry. Hooks run builds, tests or linters: never `--no-verify`. A failed hook means the commit did not happen, so fix the cause (or hand off to `/pas:debug`) and run the same commit again; `--amend` here would rewrite the previous, unrelated commit.
3. Check `git status --short` and `git log -n <N> --oneline`, and report the commits.
4. Push only when the user asks; it is its own gate.

## 5. Finish the topic

Run this after the commits, or alone when the tree is clean and the user asks to tidy `.temp/`.

1. List the `.temp/<topic>/` folders. Inside a worktree, only the worktree's own `.temp/`, never the main checkout's by absolute path; mention whether the main checkout still has the topic.
2. Per topic, one line: files, open tasks (`[ ]` open; `[x]` and `[-]` resolved), and any `flow.md` stage not done.
3. Ask one question (gate 1), recommended answer first:
   * one finished topic → delete `.temp/<topic>/` / keep it;
   * several finished topics → delete the active one / delete all finished / keep all;
   * a topic with open tasks or an unfinished flow is never recommended for deletion: say what is open.
4. Delete only the confirmed folders and check that `git status` did not change. Nothing in `.temp/` → say the workspace is clean.

End with one line naming the next step (push, or nothing) and stop.
