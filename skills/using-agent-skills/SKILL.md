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
 └── [Utility] Ready to commit or clean git status? ─→ /git       (Atomic commits & .temp/ guard)
```

### Fast-Track Routes by Task Size (Anti-Waterfall Rule)
Do **NOT** force every task through all 9 stages. Recommend the shortest safe route based on scope:
- **Micro-change / Bugfix**: Jump straight to `/debug` or `/implement`.
- **Small / Medium Feature (Fast-Track)**: Jump straight to `/decompose` (which embeds a compact `## Context & Intent` header directly at the top of `.temp/<topic>/tasks.md`, skipping separate `intent.md` and `proposal.md` files) → `/implement` → `/review`.
- **Large / Architectural Feature (Full Lifecycle)**: `/interview` (or `/idea`) → `/proposal` (with optional `/intent`) → `/decompose` → `/implement` → `/review` → `/spec` → `/cleanup`.

### Autopilot Mode (Zero-Stop Chaining on User Request)
- By default, each skill stops at its Forward Handoff menu so the user stays in control.
- **However**, if the user explicitly asks to run in **Autopilot** (e.g., *"роби до кінця"*, *"autopilot"*, *"all the way without stops"*), automatically follow the `(Recommended)` handoff path from stage to stage (e.g., `/decompose` → `/implement` Batch → `/review` → `/spec`) and **pause ONLY if**:
  1. `/review` reports `CHANGES RECOMMENDED` or a test/build check fails,
  2. An architectural ambiguity or breaking conflict is discovered, or
  3. Before executing `git commit` / `git push` (`/git`) or deleting `.temp/<topic>/` (`/cleanup`).

---

## 3. Core Operating Behaviors (Non-Negotiable Across All Skills)

1. **Interactive Advisors Over Rigid Blocks**:
   - Never hard-block the user if an earlier artifact in `.temp/<topic>/` is missing.
   - Present the full menu of viable options, mark one as **`(Recommended)`** with a clear reason, and allow the user to ask about pros/cons or clarify details before choosing. After answering any question, **re-present the options**.
2. **Workspace Isolation (`.temp/<topic>/` vs. `docs/specifications/`)**:
   - All temporary scratchpads (`intent.md`, `proposal.md`, `tasks.md`, `review-N-tasks.md`, `subtasks-*.md`) live strictly inside `.temp/<topic>/` (which must be in `.gitignore`).
   - `docs/specifications/` contains **only** declarative normative specifications of how the system works right now — never temporary refactoring plans.
3. **Surface Assumptions & Manage Confusion Actively**:
   - Never silently guess when requirements or existing code conflict. Stop, name the discrepancy, and ask.
4. **Push Back When Warranted (Zero Sycophancy)**:
   - You are an engineering partner, not a yes-machine. If an approach has concrete downsides or risks breaking callers, state the trade-off honestly and recommend a safer alternative (e.g., `Expand-Contract` parallel implementation).
5. **Enforce Simplicity & Scope Discipline**:
   - Prefer the simplest solution that works. Never refactor orthogonal code, remove unfamiliar comments, or add unrequested features.
6. **100% Working State Invariant**:
   - Every task completed in `/implement` must leave the project compiling and passing tests.

---

## 4. Status / Resume Mode ("Where Did I Leave Off?") & Forward Handoff

When invoked directly (or when the user asks *"де я зупинився?"* / *"what's the current status?"* in a new chat session):
1. **Scan `.temp/` for Active Topics**:
   - List each `<topic>` folder in `.temp/`, which artifacts exist (`intent.md`, `proposal.md`, `tasks.md`, `review-N-tasks.md`, `subtasks-*.md`), the count of completed `[x]`, cancelled `[-]`, and remaining `[ ]` tasks, and **the exact next `- [ ]` task in priority order**.
2. **Recommend Entry Point**:
   - Present 2–3 relevant skills (e.g., resume `/implement` on the next unchecked task, run `/review` if all tasks are `[x]`, or start a Fast-Track `/decompose`) with your **`(Recommended)`** choice and reasoning.
3. **STOP YOUR TURN IMMEDIATELY** and wait for the user to choose (unless Autopilot was explicitly requested).

