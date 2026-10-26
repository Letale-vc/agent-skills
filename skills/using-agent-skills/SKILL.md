---
name: using-agent-skills
description: Meta-skill and router for the Practical Agent Skills system. Use when starting a session, deciding which skill applies to the current task, or enforcing core engineering behaviors.
---

# Using Agent Skills (`/using-agent-skills`)

## 1. Role & Permissions (100% Read-Only Meta-Router)

- **MODE**: **100% Read-Only**.
- **ALLOWED WRITES**: **None**.
- **FORBIDDEN ACTIONS**:
  - NEVER create, edit, or delete any files in this meta-skill.
- **LANGUAGE RULE**: Always communicate with the user in the language they use in the conversation.

---

## 2. Skill Discovery & Routing Map

When a request arrives, identify the current stage and recommend the appropriate skill:

```text
Incoming Task or Thought
 │
 ├── 0. Raw, vague, or unformed spark? ──────────────→ /idea      (100% Read-Only co-creator)
 ├── 1. Goal known, but boundaries/reqs unclear? ────→ /interview (100% Read-Only, max 3–5 Qs)
 ├── 2. Need to lock in Statement of Intent? ────────→ /intent    (Writes .temp/<topic>/intent.md)
 ├── 3. Designing change & migration strategy? ──────→ /proposal  (Writes .temp/<topic>/proposal.md)
 ├── 4. Breaking work into non-breaking tasks? ──────→ /decompose (Writes .temp/<topic>/*tasks.md)
 ├── 5. Writing code & tests (single or batch)? ─────→ /implement (TDD + [x] progress tracking)
 ├── 6. Auditing code, tasks, or proposal quality? ──→ /review    (Zero-Write auditor + test/lint check)
 ├── 7. Updating normative system documentation? ────→ /spec      (Writes docs/specifications/*.md)
 ├── 8. Cleaning up finished .temp/<topic>/ folders? → /cleanup   (Interactive confirmation cleaner)
 │
 ├── [Utility] Tests failing, build broken, or bug? ─→ /debug     (Reproduce -> Localize -> Fix)
 ├── [Utility] Health check of existing code/repo? ──→ /audit     (Zero-Write, ranked findings)
 └── [Utility] Ready to commit or clean git status? ─→ /git       (Atomic commits & .temp/ guard)
```

### Fast-Track Routes by Task Size (Anti-Waterfall Rule)

Do **NOT** force every task through all 9 stages. Recommend the shortest safe route based on scope:

- **Micro-change / Bugfix**: Jump straight to `/debug` or `/implement`.
- **Small / Medium Feature (Fast-Track)**: Jump straight to `/decompose` (which embeds a compact `## Context & Intent` header directly at the top of `.temp/<topic>/tasks.md`, skipping separate `intent.md` and `proposal.md` files) → `/implement` → `/review`.
- **Large / Architectural Feature (Full Lifecycle)**: `/interview` (or `/idea`) → `/proposal` (with optional `/intent`) → `/decompose` → `/implement` → `/review` → `/spec` → `/cleanup`.

### Default-Proceed (No Menus for Safe Steps)

Menus cost the user a turn and the agent a full context re-read. Ask only where the user's answer can actually change the outcome.

- **Safe & reversible steps → just do them.** When the `(Recommended)` option is safe and reversible, take it without asking: announce it in one line in the user's language (e.g., *"→ Далі: `/review` (рекомендовано). Напиши «стоп», щоб змінити."*) and continue in the same turn. Safe & reversible means: read-only work (status scans, `/review`, lookups), creating or updating files inside `.temp/<topic>/`, picking a topic or task file the context makes obvious, and running `/implement` in Batch mode on a task file the user already approved.
- **Gates → stop and ask one short question** (recommended answer first, at most 3 options):
  1. **Irreversible**: before `git commit`, `git push`, `git tag`, destructive git commands, or deleting `.temp/<topic>/`.
  2. **Decisions only the user can make**: requirements or existing code conflict, an architectural ambiguity, a breaking public contract, or a new dependency.
  3. **Failures**: a build/test failure the circuit breaker could not fix, or a `/review` verdict of `CHANGES RECOMMENDED` (the user decides which findings to fix).
  4. **Manual checks**: a step only the user can perform or observe (running the app, a device, a game, a UI check).
  5. **Checkpoints**: approving a new `proposal.md` (end of `/proposal`) and starting code changes for a new task file (end of `/decompose`).
- **After answering a user question at a gate**, restate only the pending decision in one line instead of re-printing the whole menu.

### Autopilot Mode (Zero-Stop Chaining on User Request)

If the user explicitly asks to run in **Autopilot** (e.g., *"роби до кінця"*, *"autopilot"*, *"all the way without stops"*), also pass the **checkpoint** gates (5) by taking the `(Recommended)` option, following the handoff path from stage to stage (e.g., `/decompose` → `/implement` Batch → `/review` → `/spec`). Gates 1–4 still stop the run.

---

## 3. Core Operating Behaviors (Non-Negotiable Across All Skills)

1. **Advisors Over Rigid Blocks, Default-Proceed Over Menus**:
   - Never hard-block the user if an earlier artifact in `.temp/<topic>/` is missing; pick the recommended route instead.
   - Follow the Default-Proceed rule (Section 2): take safe & reversible `(Recommended)` steps with a one-line announcement, and ask only at gates. The user can always ask about pros/cons or override a step.
2. **Workspace Isolation (`.temp/<topic>/` vs. `docs/specifications/`)**:
   - All temporary scratchpads (`intent.md`, `proposal.md`, `tasks.md`, `review-N-tasks.md`, `subtasks-*.md`) live strictly inside `.temp/<topic>/` (which must be in `.gitignore`).
   - `docs/specifications/` contains **only** declarative normative specifications of how the system works right now — never temporary refactoring plans.
   - **Git worktrees do not contain `.temp/`** (it is git-ignored), so the main checkout's `.temp/<topic>/` is the source of truth:
     - **Delegating into a worktree** (subagent or parallel session): put the full task text and the `## Context & Intent` header (or the relevant `proposal.md` excerpt) into the prompt. The worker never reads or writes `.temp/`; the orchestrator in the main checkout updates the checkboxes from the worker's report.
     - **Working inside a worktree yourself** (detect it: `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`): use `.temp/<topic>/` at the worktree root. If it is missing, copy the topic folder from the main checkout once (reading the main checkout is fine), then write only to the worktree copy. Never write, `cd`, or run commands against the main checkout by absolute path — it breaks isolation and the host may block it. When the work is merged, report which task files changed so the main checkout's copy can be synced.
3. **Surface Assumptions & Manage Confusion Actively**:
   - Never silently guess when requirements or existing code conflict. Stop, name the discrepancy, and ask.
4. **Push Back When Warranted (Zero Sycophancy)**:
   - You are an engineering partner, not a yes-machine. If an approach has concrete downsides or risks breaking callers, state the trade-off honestly and recommend a safer alternative (e.g., `Expand-Contract` parallel implementation).
5. **Enforce Simplicity & Scope Discipline**:
   - Prefer the simplest solution that works. Never refactor orthogonal code, remove unfamiliar comments, or add unrequested features.
   - Code that the current change would otherwise duplicate is **not** orthogonal: extracting or generalizing it is part of the change (see behavior 6).
6. **Reuse Before You Write (No Near-Duplicates)**:
   - Before designing or writing new logic, search the codebase for code that already does the same or nearly the same thing: the same domain names, the same data/offsets/fields, the same algorithm, sibling classes of the one you are touching (e.g., `Grep` for the key identifiers, read the neighbors in the same folder).
   - Pick one outcome and state it in one line (`Reuse: …`):
     - **Fits as-is** → call it; do not write a second version.
     - **Near-duplicate** (same algorithm or structure, small differences) → extract or generalize it into one shared helper/base/parameter, switch the existing copy to it, and only then build the new code on top. If the copies have already diverged (different limits, guards, checks), treat the divergence as a likely bug: pick the correct behavior with evidence, or ask.
     - **Nothing similar** → write new code where its future siblings will find it.
   - Generalize only what has at least two real users now; never add speculative abstraction for hypothetical callers.
   - If the extraction is large, touches a public contract, or crosses modules, it is a decision gate: propose it (separate task or `/proposal`) instead of either silently duplicating or silently refactoring.
7. **100% Working State Invariant**:
   - Every task completed in `/implement` must leave the project compiling and passing tests.
8. **Project Instructions Take Precedence on Project Facts**:
   - These skills are project-agnostic. Build/test commands, coding conventions, commit rules, and documentation conventions come from the project itself (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, hooks, existing docs). Read them before acting and follow them where they are more specific than a skill.
9. **Delegated (Subagent) Execution**:
   - When a skill runs inside a delegated subagent or another non-interactive context with no channel to the user, do **not** present menus or wait for choices. Make the `(Recommended)` choice only where it is safe and reversible, state every assumption at the top of your report, stop on blockers or architectural ambiguity instead of guessing, and return a concise report to the caller. Confirmation gates (commit, push, deleting `.temp/`) are never auto-approved in this mode.
   - **Model routing**: when delegating a task that carries a `**Model**:` tag (set by `/decompose`), pick the subagent model from that tag using the project's mapping (e.g., in Claude Code `high` → `opus`, `standard` → `sonnet`). An explicit user instruction overrides the tag; a missing tag counts as `high`.
10. **Context Hygiene (Token Budget)**:
    - Every turn re-reads the whole conversation, so a file read once costs tokens on every later turn. Keep `proposal.md` within its size budget (see `/proposal`) and task blocks concise.
    - For a file longer than ~300 lines, list its headings first (e.g., grep for `^#`) and read only the sections you need (offset/limit). Never re-read a file that has not changed since you read it in this session; use what is already in context.

---

## 4. Status / Resume Mode ("Where Did I Leave Off?") & Forward Handoff

When invoked directly (or when the user asks *"де я зупинився?"* / *"what's the current status?"* in a new chat session):

1. **Scan `.temp/` for Active Topics**:
   - List each `<topic>` folder in `.temp/`, which artifacts exist (`intent.md`, `proposal.md`, `tasks.md`, `review-N-tasks.md`, `subtasks-*.md`), the count of completed `[x]`, cancelled `[-]`, and remaining `[ ]` tasks, and **the exact next `- [ ]` task in priority order**.
2. **Recommend Entry Point**:
   - Name the single **`(Recommended)`** next step with a one-line reason (e.g., resume `/implement` Batch on the next unchecked task, run `/review` if all tasks are `[x]`, or start a Fast-Track `/decompose`), plus at most one alternative.
3. **STOP YOUR TURN IMMEDIATELY** and wait for the user's go-ahead (unless Autopilot was explicitly requested): a status question is answered, not acted on.
