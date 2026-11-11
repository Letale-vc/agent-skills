# Shared rules

Every `pas` skill and agent follows these rules; skills link here instead of restating them. The project's own instructions (`CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, hooks, existing docs) win on project facts: build and test commands, conventions, file layout, commit rules. Read them before acting.

## 1. Role modes

Each skill and agent names one mode at the top.

| Mode | May write | Never |
| --- | --- | --- |
| **read-only** | nothing; ephemeral build and test caches (`bin/`, `obj/`, `__pycache__/`, coverage) are fine | create, edit, format or delete files; install packages; run `--fix`, `--write`, `-u`, `git checkout` |
| **writes `.temp/`** | its own files in `.temp/<topic>/`, and `.gitignore` only for the guard in §2 | touch source, tests or `docs/` |
| **writes code** | the source and tests the task needs, checkbox states in the task file | rewrite task text, edit `docs/specifications/`, delete `.temp/` |

Read-only verification is welcome in every mode: `git status` / `diff` / `log` / `blame`, the project's tests, build or typecheck, linters in check-only mode.

## 2. The `.temp/` workspace

* Temporary planning files live only in `.temp/<topic>/`: `proposal.md`, `tasks.md`, `review-<N>.md` (review findings), `review-<N>-tasks.md`, `subtasks-<id>.md`, `flow.md`. Never in the project root or `docs/`.
* `docs/specifications/` describes how the system works now; plans, task lists and history never go there.
* Task files are append-only: a new breakdown is a new file; only checkbox states change ([task-template.md](task-template.md)).
* **`.gitignore` guard**: before the first write to `.temp/`, check the project's `.gitignore`. If no line already ignores it (`.temp`, `.temp/`, `/.temp/`, ignoring trailing whitespace and `\r`), append `.temp/` once.
* `.temp/` is never staged or committed.

## 3. Topic resolution

1. A topic named in the arguments or obvious from the chat → use it.
2. Exactly one folder in `.temp/` → use it.
3. Several folders and no clear match → list them and ask (an agent reports `blocked:` instead).
4. A new goal → a short kebab-case slug from the goal.

Print `Active topic: .temp/<topic>/` once.

## 4. Worktrees

`.temp/` is git-ignored, so a git worktree has no copy of it; the main checkout's `.temp/<topic>/` is the source of truth.

* **Delegating into a worktree**: put the full task text and the `## Context & Intent` header (or the relevant `proposal.md` excerpt) into the prompt. The worker never reads or writes `.temp/`; the orchestrator updates checkboxes from its report.
* **Working inside a worktree** (`git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`): use `.temp/<topic>/` at the worktree root, copying the topic folder from the main checkout once if it is missing. Never write to or run commands in the main checkout by absolute path. At merge time, report which task files changed.

## 5. Gates and default-proceed

A menu costs the user a turn and the session a full context re-read. Safe and reversible steps are taken without asking and announced in one line, e.g. `→ Next: /pas:review. Say "stop" to change it.` Safe means read-only work, writing inside `.temp/<topic>/`, picking a topic or file the context makes obvious, and running a task file the user already approved.

Stop and ask one short question (recommended answer first, at most three options) only at these gates:

1. **Commit or delete**: `git commit`, `push`, `tag`, destructive git commands, deleting `.temp/<topic>/`.
2. **Design choice**: requirements conflict with each other, the code or a spec; an architectural ambiguity; a breaking public contract; a new dependency; picking a proposal variant.
3. **Review findings**: the user picks which findings to fix.
4. **Manual check**: a step only the user can run or observe (the app, a device, a UI).
5. **Failure**: a build or test failure the circuit breaker could not fix.

After the user answers, restate only the pending decision, not the whole menu.

**Subagents** have no channel to the user: they never ask or wait. They take the recommended choice only where it is safe and reversible, list their assumptions at the top of the report, and stop with `blocked: <question>` at a gate or an ambiguity instead of guessing. Gate 1 is never auto-approved.

## 6. Engineering behaviors

* **Surface conflicts**: when requirements and existing code disagree, name the discrepancy and ask; never guess silently.
* **Push back**: state concrete downsides and a safer alternative (for example Expand-Contract) instead of agreeing.
* **Scope discipline**: the simplest solution that works; no refactoring of orthogonal code, no removed comments, no unrequested features.
* **Working state**: every finished task leaves the project building with its tests green.

## 7. Reuse before writing new code

Before writing new logic, search for code that already does the same or nearly the same: the same domain names, data or fields, the same algorithm, sibling files of the one you touch. State one outcome in a line (`Reuse: …`):

* **Fits as-is** → call it; no second version.
* **Near-duplicate** → extract the shared helper, base or parameter first, switch the existing copy to it, then build on it. Copies that already diverged (different limits, guards, checks) are a likely bug: pick the correct behavior with evidence, or ask.
* **Nothing similar** → write it where its future siblings will look.

Generalize only what has two real users now. A large extraction, a public contract change or a cross-module move is gate 2: propose it as its own task instead of copying or refactoring silently.

## 8. Context hygiene

* Every turn re-reads the whole conversation, so a file read once is paid for on every later turn.
* For a file over ~300 lines, list its headings first and read only the sections you need. Never re-read a file that has not changed.
* Code searches go to `pas:scout`: one narrow question each, independent questions in parallel, with the paths or names to start from. Keep its conclusions, not file dumps. The main session makes at most three direct lookups per question.
* The session budget and when to clear: [complexity.md](complexity.md) §3.

## 9. Language

* Talk to the user in the language the project's instructions set, else in the language the user writes in.
* Files in `.temp/` use the chat language. `docs/` and specifications follow the project's existing convention.
* Commit messages follow the repository's `git log` convention (English Conventional Commits when there is no history).
* Skill and agent text stays English; user-facing product strings follow the project's rules.
