---
name: decompose
description: Breaks an approved proposal, the review findings the user picked, an audit report or structure roadmap, one oversized task, or a clear chat discussion into a new task file of non-breaking vertical slices in .temp/<topic>/, each task scored for model and effort. Spawns pas:decomposer for large sources and writes small ones itself; never overwrites an existing task file. Use after /pas:proposal is approved, after the user picks /pas:review or /pas:audit findings to fix, when a task is too big for one implementer, when /pas:flow reaches the decompose stage, or via /pas:decompose.
argument-hint: "[topic] [task to split]"
---

# Decompose

**Mode**: writes `.temp/` (new task files only; never rewrites an existing one).

Read `${CLAUDE_PLUGIN_ROOT}/shared/rules.md` (topics, `.gitignore` guard, worktrees, gates) and `${CLAUDE_PLUGIN_ROOT}/shared/task-template.md` (file names, header, task block, checkbox states) first. Scores come from `${CLAUDE_PLUGIN_ROOT}/shared/complexity.md` §2.

## 1. Source and target file

Resolve the topic (rules.md §3), pick the source from the chat and `.temp/<topic>/`, announce it in one line, and proceed: a new file in `.temp/` overwrites nothing.

| Source | Target file |
| --- | --- |
| Review findings the user picked | `review-<N>-tasks.md`, `N` from the `review-<N>.md` they were picked from, else the next free number |
| `/pas:audit` code findings | `tasks.md` in a new topic `audit-<area>` (`audit-<area>-2` if that one already has a `tasks.md`) |
| `/pas:audit structure` findings or roadmap | `tasks.md` in a new topic `arch-<area>` (`arch-<area>-2` likewise) |
| One task to split | `subtasks-<N>.md`, or `subtasks-r<M>-<N>.md` for task `N` of `review-<M>-tasks.md` |
| An approved `proposal.md`, no `tasks.md` yet | `tasks.md` |
| A clear goal discussed in the chat | `tasks.md` |

* **Audit roadmap**: the header's `Goal` is the target structure in one line and its `Constraints` are the dependency rules. Settled steps become tasks in roadmap order (an Expand-Contract move is several tasks). A step whose design is still open becomes one task with a `**Design**:` line naming its own topic, per the template.
* **Findings**: one task per finding unless two findings share a fix; a bug fix's `Verification` names a test that fails before the fix.
* Sources that contradict each other (the chat against `proposal.md`) or requirements still unclear → gate 2: recommend `/pas:shape` or `/pas:proposal` instead of guessing.

## 2. Who writes it

* **Large source** (a proposal, an audit roadmap, or more than about five tasks): spawn `pas:decomposer` with the topic path, the source kind, the target file name, and the source itself (the path of `proposal.md`, or the findings or roadmap pasted from the chat). It never asks the user; a `blocked: <question>` in its report is a gate for you to put to the user, after which you spawn it again with the answer.
* **Small source** (picked findings, one task to split, a short chat goal): write it here; the context is already in this session. Lookups for `Context` and `Reuse` go to `pas:scout`.
* Without subagents, write every source here.

## 3. Check the file

Before handing off, whoever wrote it:

* [ ] The file is new; no existing task file changed.
* [ ] `tasks.md` opens with `## Context & Intent`; a subtask file has its `Parent:` line; a design topic named by another task has its `Parent: ../<topic>/<file>#Task N`.
* [ ] Every task has `**Model**` with a `(D V S)` score, `Target files`, `Context`, `Reuse` and `Verification`; a task with `**Design**:` has none of Target files, Context or Verification.
* [ ] A shared extraction comes before the tasks that reuse it; Expand-Contract switches callers only in its last task.
* [ ] Each task leaves the project building with its tests green.
* [ ] `Target files` follow the project's layout rules (its instructions say where new files go).

Fix what fails before reporting; a decomposer file that fails is sent back once with the list.

## 4. Handoff

1. Link the file and list its tasks, one line each: title, model tag, and a `Manual check` or `Design` marker if any.
2. In a `/pas:flow` run → return to the flow (a large run clears here; complexity.md §3).
3. Standalone → the user has not seen the file yet: ask one question, `Start /pas:implement on <file>?` (recommended) or review the breakdown first, and stop the turn.
