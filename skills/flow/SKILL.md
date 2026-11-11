---
name: flow
description: Single entry point of the pas pipeline. With no argument or a status question (where did I leave off, what next, status) it reports where work stands (unfinished .temp/ topics, task counts, the one next step). With a goal it picks the small, medium or large route, delegates code, review and specs to pas agents, runs the full check, and keeps the run's state in .temp/<topic>/flow.md so a fresh session resumes it with /pas:flow <topic>. Stops only at real gates (commit, design choice, review findings, manual check, failure). Use for /pas:flow, "where did I leave off", "what next", "continue flow <topic>", or any feature, change or fix the user wants taken all the way.
argument-hint: "[goal | topic]"
---

# Flow

**Mode**: conductor. This skill writes only `.temp/<topic>/flow.md` and, on the medium route, `.temp/<topic>/tasks.md`; every other write comes from the agent or skill that owns it.

Read first: `${CLAUDE_PLUGIN_ROOT}/shared/rules.md` (modes, `.temp/`, topics, gates, context hygiene) and `${CLAUDE_PLUGIN_ROOT}/shared/complexity.md` (routes, task score, context budget).

While the host can spawn subagents, the main session:

* never edits source, tests or `docs/`: that is `pas:implementer` or `pas:spec-writer` work;
* never searches the code beyond the three direct lookups of rules.md §8: the rest goes to `pas:scout`;
* never commits or deletes `.temp/` (gate 1), and never copies task checkboxes or task text into `flow.md`.

These rules override any project allowance for the main session to edit one or two files itself: while flow runs, every code change goes to an agent.

Without subagents, run each stage skill inline under its own mode; the rest of this skill still applies.

## 1. Entry

1. **No argument, or a status question** (where we stopped, what is next, the state of a topic) → Status (§2), limited to the topic it names, if any.
2. **An existing topic** (`/pas:flow <topic>`, "continue flow <topic>") → Resume (§3).
3. **Anything else** asks for a change: a new goal → §4.

## 2. Status

1. For each folder in `.temp/`: its artifacts (`proposal.md`, task files, `flow.md`), the count of `[x]`, `[-]` and `[ ]` tasks, the first unchecked task (`tasks.md`, then `review-<N>-tasks.md` in order, then subtask files), and `Stage` / `Next` from `flow.md`.
2. Recommend one next step with a one-line reason, plus at most one alternative:
   * `flow.md` exists → `/pas:flow <topic>`;
   * the next task has a `**Design**:` line → `/pas:proposal` in the topic it names;
   * unchecked tasks → `/pas:implement <topic>`;
   * everything resolved and not reviewed → `/pas:review`; reviewed → `/pas:git`.
3. Empty or missing `.temp/` → say so and ask for a goal.
4. **Stop the turn.** A status question is answered, not acted on.

## 3. Resume

1. Read `.temp/<topic>/flow.md` and continue at its `Stage` / `Next`.
2. **Owner**: the last `Log` line is a `Handoff:` line (the previous owner cleared itself, §6) → take over without asking. Ask whether to take over (gate 2) only on evidence of another live session that has not handed off: the host lists the `Owner` session as running, or `flow.md` changed after this session read it; two conductors break the same files. Then write this session into `Owner` (host session name or id, else date and time).
3. No `flow.md` → derive the stage from the artifacts (proposal without tasks → `decompose`; unchecked tasks → `implement`; all resolved → `review`) and create it.
4. The artifacts show later progress than `Stage` (a stage finished outside flow) → the artifacts win: fix the header and add a `Log` line.

## 4. New goal

1. Pick the size per complexity.md §1 and say it in one line, e.g. `→ Route: medium in .temp/<topic>/. Say "stop" to change it.` Two exceptions: a failing test, crash or regression → `/pas:debug`, delegated: investigation to `pas:scout`, the fix to `pas:implementer` in debug mode, never debugged inline in this session; a question about how the code should be structured → `/pas:audit structure`, then stop.
2. **Small**: no `.temp/` topic and no `flow.md`. On the default branch, create `feat/<topic-slug>` first (§5 Branch). Write the task out in the block format of `${CLAUDE_PLUGIN_ROOT}/shared/task-template.md`, score it, and spawn `pas:implementer` with the model and effort the score gives; the prompt asks it to finish with the full check, since this one task is the whole batch. Check its report and read the reported check output instead of re-running a check it reported green on files unchanged since. Run the full check once yourself only when the report shows no green full-check run. Then `/pas:git` (gate 1). No review.
3. **Medium**: resolve the topic, apply the `.gitignore` guard, and write `.temp/<topic>/tasks.md` yourself per the template: the header plus up to about five scored tasks, with the `Context` and `Reuse` lookups delegated to `pas:scout`. Create `flow.md` and enter the stage loop at `implement`.
4. **Large**: resolve the topic, create `flow.md`, and enter the stage loop at `shape` when the goal, success criteria or scope is unclear, else at `proposal`.
5. From here the run proceeds without asking until a gate (§7).

## 5. Stage loop

| Stage | Medium | Large |
| --- | --- | --- |
| `shape` | — | `/pas:shape` in this session, only if the goal is unclear |
| `proposal` | — | `/pas:proposal`: 2–3 `pas:architect` variants; the user picks one (gate 2) |
| `decompose` | done in §4 step 3 | `/pas:decompose` → `pas:decomposer` writes `tasks.md`; then clear (§6) |
| `implement` | `/pas:implement` batch: one `pas:implementer` per task | same |
| `verify` | the full check, once | same |
| `review` | `/pas:review`: one `pas:reviewer` | `/pas:review`: two `pas:reviewer` in parallel (correctness; simplicity and conventions) |
| `spec` | `/pas:spec`, only if specified behavior changed | `/pas:spec` when `docs/specifications/` exists |
| `git` | `/pas:git` (gate 1) | same |

* **Branch**: on `main` / `master`, create `feat/<topic>` (on the small route `feat/<topic-slug>`, a slug from the goal) before the first code change and say so in one line; a branch is reversible.
* **Full check**: the project's full build-and-test command from its instructions; without one, its build and test commands; without those, skip it and say so in `Log`. Failure → `/pas:debug` → full check again; the same failure after 3 attempts → gate 5.
* **Review verdict**: `APPROVED` or `APPROVED WITH NOTES` → the next stage (notes go into `Log` in one line, not into tasks). `CHANGES RECOMMENDED` → the review has written its numbered findings to `.temp/<topic>/review-<N>.md`; link it in `Next` and the `Log` line, then gate 3. Once the user picks findings ("fix 1,3", possibly in a new session), `/pas:decompose` writes `review-<N>-tasks.md` from that file, `Active task file` points to it, and the loop continues at `implement`.
* **Delegation**: every agent gets the full task text plus the `## Context & Intent` header (or the relevant `proposal.md` excerpt), never this session's reasoning. Check each report before trusting it; keep reports, not file dumps.

## 6. Stage boundary

After every stage, before the next:

1. Rewrite the `flow.md` header (`Stage`, `Active task file`, `Next`) and append one `Log` line: what the stage produced, the verdict, the full-check result.
2. Apply the context budget (complexity.md §3). A large run always clears after `decompose`; any run clears at about 300k tokens. To clear: make sure `flow.md` holds everything the next stage needs, append the `Log` line `Handoff: <next step>` just before clearing, give the user the one message to send next (`/pas:flow <topic>`), clear the session, and stop.
3. Otherwise continue with the next stage in the same turn, announced in one line.

## 7. Gates

* Stop and ask one short question (recommended answer first) only at the gates of rules.md §5: commit or delete, design choice, review findings, manual check, failure. Write `Stage` and `Next` before stopping, so the answer can arrive in a new session.
* Record each answer in `## Decisions`, then continue the loop.
* "All the way" or "autopilot" never passes a gate.
* **Run finished**: after `spec` (or when no spec is needed), `/pas:git` builds the commit plan and asks (gate 1). After the commit, set `Stage: done`; `/pas:git` then offers deleting the topic.

## 8. `flow.md` format

At most ~60 lines. The header is rewritten; `Decisions` and `Log` only grow, one line per entry. `Stage` is the stage that runs next (after `CHANGES RECOMMENDED` it is `decompose`).

```markdown
# Flow: <topic>

- **Goal**: <one sentence>
- **Route**: medium | large
- **Owner**: <host session name or id, else date and time>
- **Stage**: shape | proposal | decompose | implement | verify | review | spec | git | done
- **Active task file**: tasks.md | review-<N>-tasks.md | —
- **Next**: <the exact next step; at gate 3 a link to review-<N>.md>

## Decisions

- <date> — <decision> (gate <N>)

## Log

- <date> <stage> → <result>
- <date> Handoff: <next step>
```
