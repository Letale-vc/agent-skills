# Task file template

Used by `pas:decomposer` and by the main session for medium work. File names: `tasks.md` (first breakdown), `review-<N>-tasks.md` (from review findings), `subtasks-<N>.md` or `subtasks-r<M>-<N>.md` (splitting task N of `tasks.md` or of `review-<M>-tasks.md`). Never overwrite an existing task file.

## Header

`tasks.md` opens with the context header; a subtask file opens with `Parent: tasks.md#Task 3` (or `review-1-tasks.md#Task 3`) on the line after its title. A `tasks.md` in a topic that another task's `**Design**:` line names adds `Parent: ../<topic>/<file>#Task N` right after its header.

```markdown
## Context & Intent
- **Goal**: <1–2 sentences: what is built and why>
- **Strategy**: In-Place | Expand-Contract
- **Constraints**: <non-breaking invariants, boundaries, where new code lives>
```

## Task block

```markdown
- [ ] **Task 3: Read the retry limit from config**
  - **Model**: standard (D0 V0 S1)
  - **Target files**: `src/net/client.ts`, `test/net/client.test.ts`
  - **Context**: `Client.send` retries in `src/net/client.ts:40`; config is parsed in `src/config.ts:12`.
  - **Reuse**: `parsePositiveInt` (`src/config.ts:30`).
  - **Verification**: new case `client retries up to the configured limit` fails first, then passes; test project green.
  - **Manual check**: <only when part of the check needs the user>
```

* **Model**: tag and score per [complexity.md](complexity.md) §2.
* **Target files**: exact paths to create or modify, placed by the project's layout rules.
* **Context**: the signatures, data and `path:line` references the implementer needs, so it does not search from scratch; no large pasted blocks.
* **Reuse**: the existing code to call or extend (`path:line`), or `none found (searched: <terms>)` ([rules.md](rules.md) §7).
* **Verification**: the smallest check that proves the task, one of: an existing test that already covers it (name it); one new test or case for logic that can break silently (branch, parser, math, state, contract, bug fix); `build + existing tests` for wiring, config, renames, UI text, docs or behavior-preserving refactors. Never a bare "add tests".
* **Manual check**: exactly what the user must run or look at. The batch does not pause there: manual checks are collected and asked once, as one checklist at the end of the batch (gate 4), unless a later task depends on the result.
* **Design** (only when the design is still open): `**Design**: proposal first in .temp/<own-topic>/` in place of Target files and Context. The implementer stops before such a task; it closes when the last task of its own topic does, through that topic's `Parent:` line.

## Rules

* Each task is a non-breaking vertical slice: after it the project builds and its tests pass.
* Expand-Contract: first tasks build the new code beside the old one; the last switches callers and removes or deprecates the old code.
* A shared extraction gets its own earlier, behavior-preserving task; later tasks reuse it.

## Checkbox states

* `- [ ]` pending.
* `- [x]` done and verified.
* `- [-] ~~**Task N: <Title>**~~ (cancelled: <reason>)` cancelled or superseded; counts as resolved.
