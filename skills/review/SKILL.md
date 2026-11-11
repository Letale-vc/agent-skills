---
name: review
description: Review of finished work in .temp/<topic>/ - implemented code against its task file, proposal, project rules and specifications, or a proposal or task breakdown before it is built. Spawns fresh pas:reviewer subagents (one for medium work, two in parallel with correctness and simplicity+conventions focus for large work), merges their findings, keeps only those with confidence of 80 or more, and gives a verdict with the next step. Writes nothing but its numbered findings to .temp/<topic>/review-<N>.md. Use after /pas:implement finishes, before committing, when the user asks to check or verify work against the plan, when auditing a proposal or task file, or via /pas:review.
argument-hint: "[topic] [code|tasks|proposal]"
---

# Review

Mode: **writes `.temp/`** (`${CLAUDE_PLUGIN_ROOT}/shared/rules.md` §1): only its findings file `.temp/<topic>/review-<N>.md` (§3). The review never writes `review-<N>-tasks.md`, specifications or code; it recommends the skill that does. Read-only verification (tests, build, typecheck, linters in check mode, `git diff`) backs every finding with facts.

## 1. Target

1. Resolve the topic (rules §3).
2. **What is reviewed**, from the arguments or the context: implemented code (the default after `/pas:implement`), a task file, or `proposal.md`.
3. **Diff range** for code: the range given by the caller or `flow.md`; else the branch against its merge base with the default branch, plus uncommitted changes.
4. **Size**: large when the topic has a `proposal.md` or `flow.md` says so; otherwise medium. Small work gets no review (complexity.md §1).
5. Read only the active task file (the highest `review-<N>-tasks.md`, else `tasks.md`) and the `proposal.md` sections on goal, criteria and spec impact, never every historical file.

## 2. Spawn reviewers

| Target | Reviewers (`pas:reviewer`, model from its definition) |
| --- | --- |
| Code, medium | one, `focus: correctness + simplicity+conventions` |
| Code, large | two in parallel: `focus: correctness` and `focus: simplicity+conventions` |
| Task file or proposal | one, `focus: correctness` |

Each prompt carries the topic path, the target file, the diff range and the focus; the agent owns the checklist, the confidence score and the severity rules. Never the author's reasoning: a reviewer that shares the author's context shares its blind spots. A host without subagents follows `${CLAUDE_PLUGIN_ROOT}/agents/reviewer.md` in this session, one focus after the other.

## 3. Merge and verdict

1. **Collect** the findings of all reviewers; merge duplicates (same place, same cause), keeping the higher severity.
2. **Drop** what slipped past the agents' filter: confidence below 80, issues on lines the change did not touch, anything a compiler or linter catches, style the project's rules do not ask for.
3. **Spot-check** every Critical and Major finding: read the cited `path:line`; a scenario that does not hold is dropped or becomes Minor.
4. **Severity** stays as the agent gave it unless the spot-check changes it; never raise a Minor to Major to get a gate.
5. **Verdict**: `CHANGES RECOMMENDED` needs at least one Critical or Major; only Minor → `APPROVED WITH NOTES`; none → `APPROVED`.
6. **Persist**: write the report below to `.temp/<topic>/review-<N>.md` (`N` = the next free number; apply the `.gitignore` guard, rules §2), so "fix 1,3" still resolves in a new session. Finding numbers in the chat and in the file are the same.

```markdown
## Review Verdict: APPROVED | APPROVED WITH NOTES | CHANGES RECOMMENDED
Active topic: `.temp/<topic>/` · Reviewers: <focus list>
Verification: <tests / build / typecheck results, or "static"> · Simplicity: checked N, findings M

### Summary
<1–3 sentences>

### Findings
1. **[Critical | Major | Minor]** `path:line` — <issue and the concrete failure> (confidence N)
   - *Recommendation*: <the fix>
```

## 4. Handoff

* **`CHANGES RECOMMENDED`** is gate 3 (rules §5): one question, recommended answer first: create `review-<N>-tasks.md` through `/pas:decompose` from all Critical and Major findings (Minor too?); alternatives: name the finding numbers, or a trivial one-line fix through one `pas:implementer`. Discuss a disputed finding, then restate the pending decision in one line. End the turn; nothing besides `review-<N>.md` is written or run before the user answers, not even inside `/pas:flow`.
* **`APPROVED` / `APPROVED WITH NOTES`**: list the Minor notes one line each (they get no tasks unless the user asks) and proceed, announcing the step:
  * public behavior, a contract or a dependency rule changed and the project has `docs/specifications/` → `/pas:spec`;
  * otherwise → `/pas:git` (it asks before committing).
* **Reviewed a task file or proposal** → the next stage: `/pas:implement` or `/pas:decompose`.
* **Run from `/pas:flow`** → return the verdict, findings, the `review-<N>.md` path and the next step; the flow links the file in `flow.md` and presents the gate.
