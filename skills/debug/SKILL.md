---
name: debug
description: Systematic root-cause debugging - Reproduce -> Localize -> Root cause -> Fix & guard with a regression test, fixing the cause once in a shared place instead of patching symptoms. Use when tests fail or are flaky, a build breaks, the app crashes or gives wrong output, something that used to work stopped working, when the full check is red after a batch, or via /pas:debug.
argument-hint: "[failing test, command or symptom]"
---

# Debug

Mode: **writes code** (`${CLAUDE_PLUGIN_ROOT}/shared/rules.md` §1), but only after the root cause is found. No shotgun edits hoping the failure goes away, no unrelated work past a red build, no scratch files outside `.temp/`. Searches across the codebase go to `pas:scout` (rules §8).

Run from `/pas:implement` or `/pas:flow` (a red full check or a bug goal), the main session does not debug inline: investigation (searches, localizing, sibling copies) goes to `pas:scout`, and the fix to one `pas:implementer` in debug mode (opus `high`), which gets the failure output and the scout's findings and returns the diagnosis and fix in its report. Flow's no-code-edit rule holds here and overrides any project allowance to edit one or two files.

## 1. Reproduce

* Make the failure happen on demand: the failing test, the build command, or the exact input and state. Keep the exact error, stack trace or failing assertion.
* **Flaky or intermittent**: do not guess. Check the usual sources of non-determinism: unawaited async work and races, state shared between tests, test order, clock and time zone, leaked resources. Run the test repeatedly and in isolation. Still not reproducible → go on with a hypothesis below 80% confidence (§4).

## 2. Localize

* Narrow it to the layer, module, file and line range where actual and expected behavior diverge.
* A regression ("worked yesterday") → `git log` / `git diff` of the recent changes in that area; `git bisect` when the window is wide.
* **Sibling copies**: search for other code with the same logic (same algorithm, data or paths, sibling classes). The bug often lives in every copy, or exists because the copies diverged.

## 3. Root cause

Before touching production code, post the diagnosis:

```markdown
## Bug Diagnosis
- **Symptom**: <what fails, the exact error>
- **Location**: `path:line`
- **Root cause**: <why, with evidence from code, logs or a run>
- **Sibling copies**: <`path:line` of the same logic, or "none found">
- **Confidence**: ~N%
```

Fix the cause **once, in a shared place** (rules §7): reuse logic that already exists; when several copies hold the bug, extract them into one and fix it there instead of patching each.

## 4. Route and fix

Pick the route from the diagnosis and announce it in one line (the user can override):

* **Confidence ≥ 80%, local cause** → fix now:
  1. write or extend a regression test (prefer a new case in the closest existing test) and see it fail;
  2. apply the minimal fix and see it pass;
  3. run the project's check command for the touched area, green with no regressions.
* **Confidence < 80%** → add targeted diagnostic logging or instrumentation that captures the missing state. If only the user can reproduce it (the app, a device, a UI), give a short numbered checklist and end the turn (gate 4).
* **The cause is a design flaw** (a broken public contract, the same rule spread across modules, wrong module boundaries) → gate 2: recommend `/pas:flow <goal>` for a multi-step fix, or `/pas:audit structure` when the flaw is in the structure itself; one short question, end the turn.

Circuit breaker: the same failure after 3 fix attempts → stop and report the diagnosis, what was tried and the output (gate 5).

## 5. Handoff

Announce the next step in one line:

* the bug came up mid-batch in `.temp/<topic>/` → back to `/pas:implement` on the active task file;
* the fix touched more than one module or a public contract → `/pas:review`;
* otherwise → `/pas:git` for a `fix:` commit (it asks before committing).
