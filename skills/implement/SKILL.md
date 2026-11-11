---
name: implement
description: Executes the pending tasks of a .temp/<topic>/ task file in Batch mode by default, one fresh pas:implementer subagent per task with model and effort taken from the task's complexity score, TDD (Red -> Green -> Verify), checkbox updates ([x] done, [-] cancelled) and the full check once per batch, without questions between tasks. Use when the user says to start, continue or resume the tasks, after a task breakdown is approved, or via /pas:implement.
argument-hint: "[topic] [single]"
---

# Implement

Mode: **writes code** (rules §1). The main session orchestrates and writes only checkbox states; code and tests come from `pas:implementer`. Shared rules: `${CLAUDE_PLUGIN_ROOT}/shared/rules.md`; routes and scores: `${CLAUDE_PLUGIN_ROOT}/shared/complexity.md`; task format: `${CLAUDE_PLUGIN_ROOT}/shared/task-template.md`.

## 1. Pick the task file

1. Resolve the topic (rules §3).
2. The active file is the first with a `- [ ]` task, in this order: `subtasks-*.md`, the highest `review-<N>-tasks.md`, `tasks.md`. Print `Active task file: .temp/<topic>/<file>`.
3. Read only its `## Context & Intent` header and the pending task blocks (in a long file, find `**Task N:` and read that block). Files with no `- [ ]` left are closed history: do not read them.
4. **No task file**:
   * one or two concrete changes (small, complexity.md §1) → write the task out per the template, score it and run it as a one-task batch of §2, with no `.temp/` topic;
   * more work → the main session writes `.temp/<topic>/tasks.md` per the template (medium) or hands the goal to `/pas:flow` (large);
   * the design is not settled → gate 2 (rules §5): recommend `/pas:flow <goal>`, which shapes and proposes first.
5. **Branch**: on `main` / `master` with no branch for the topic, create `feat/<topic>` (`feat/<topic-slug>` with a slug from the goal when there is no topic), before spawning the implementer, and announce it in one line (reversible), unless the project's instructions say otherwise. On any other branch, name it in the start line.

## 2. Run the batch

Announce in one line, do not ask: `Batch: tasks 3–7 of tasks.md in order. Say "stop" to halt after the current one.` **Single mode** only on request ("one at a time", "single"): run the next task, report, name the next one, stop.

For each pending task, in file order:

1. **Design check**: a task with a `**Design**:` line has no settled design. Stop the batch before it (§3); never write code for it and never skip past it to later tasks.
2. **Model**: model and effort from the task's score (complexity.md §2); no score → opus `high`; an explicit user instruction wins.
3. **Spawn** one `pas:implementer` with that model and effort. The prompt carries the full task text, the `## Context & Intent` header (or the relevant `proposal.md` excerpt) and, in a worktree, rules §4. Never this session's reasoning. The agent owns the TDD loop (Red → Green → Verify with the project's check command, circuit breaker) and never runs the full check.
4. **Check the report**: `Status`, Red evidence or `No new test: <reason>`, `Reuse`, the files changed, the check command and its result. `git diff --stat` must show changes only in the task's Target files and their tests; anything else is resolved before marking.
5. **Escalate once**: `blocked:` or a red project check from an implementer below opus `high` → rerun on opus `high` and change the task's tag to `high` (complexity.md §2). Blocked again → stop (§3).
6. **Mark** the task `- [x]` without touching its text; a task the report or the user shows to be obsolete becomes `- [-] ~~**Task N: <Title>**~~ (cancelled: <reason>)`.
7. **Parent sync**: when the last `- [ ]` of a file that carries a `Parent: <file>#Task M` line resolves, mark Task M `- [x]` in that file. A `subtasks-*.md` without a `Parent:` line points to `tasks.md`; a path like `../<other-topic>/tasks.md` points into another topic (one opened for a `**Design**:` task).

Tasks run one after another: each is a vertical slice that later tasks may build on. A host without subagents follows `${CLAUDE_PLUGIN_ROOT}/agents/implementer.md` in this session, one task at a time.

## 3. Stop early only when

* the next task has a `**Design**:` line → recommend `/pas:proposal` in the topic that line names (or continuing that topic if it exists);
* the implementer reports a near-duplicate whose extraction is too large for the task, or a conflict with the code or a spec (gate 2);
* a task is still blocked after escalation, or the same failure survived 3 attempts (gate 5);
* the user says stop.

**Manual checks** (gate 4) do not stop the batch: finish every automatable task first, then give one short numbered checklist and wait. Stop at a manual check earlier only when the next task depends on its result.

When stopping early, run the full check (§4) on the finished tasks, then report what is done, where the batch stopped and why, and the one question or checklist the user must answer. End the turn.

## 4. Full check and handoff

1. **Full check**, once, after the last task of the batch: the project's full build-and-test command from its instructions; without one, its build and test commands; without those, skip it and say so. When an implementer already reported the full check green and no file changed since (a one-task batch whose prompt asked for it), read its output instead of running it again.
2. **Full check red** → `/pas:debug` with the failure output (delegated: `pas:implementer` in debug mode, opus `high`), then the full check again; the same failure after 3 attempts → gate 5.
3. **Report**: one line per task (done, cancelled, escalated), the full-check result, any pending manual checklist.
4. **Next step**, announced in one line:
   * small work (no `.temp/` topic) → no review; `/pas:git` (it asks before committing);
   * a task file → `/pas:review` (zero-write, safe);
   * run from `/pas:flow` → return the report to the flow, which owns the next stage;
   * another task file in the topic still has pending tasks → name it as the step after the review.
