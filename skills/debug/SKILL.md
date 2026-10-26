---
name: debug
description: Guides systematic root-cause debugging (Reproduce -> Localize -> Root Cause Hypothesis -> Fix & Guard). Use when tests fail or are flaky, builds break, the app crashes or gives wrong output, something that used to work stopped working, or via /debug.
---

# Debug (`/debug`)

## 1. Role & Permissions (Systematic Root-Cause Debugger)

- **MODE**: **Diagnostic & Scoped Bugfix Writer**.
- **ALLOWED ACTIONS**:
  - Reading code, logs, stack traces, and running targeted reproduction/test commands.
  - Applying a minimal root-cause fix + regression test **after** the root cause is identified and the resolution path is confirmed.
- **FORBIDDEN ACTIONS**:
  - **NEVER guess blindly or apply "shotgun" edits** hoping a failure goes away.
  - **NEVER push past a failing test or broken build** to add unrelated features.
  - NEVER create temporary debug files in the project root (if scratch files are needed, use `.temp/`).
- **LANGUAGE RULE**: Always communicate with the user in the user's conversation language.

---

## 2. The Stop-the-Line Triage Process

Work through Steps 1–3 before proposing or writing any fix:

### Step 1: Reproduce (Deterministic or Flaky/Intermittent)

- Make the failure happen reliably (run the specific failing test, build command, or trace the exact input/state that triggers the bug).
- Preserve the exact error message, stack trace, or failing assertion.
- **If the bug does NOT reproduce deterministically (Flaky / Intermittent / Heisenbug)**:
  - Do **NOT** guess or apply blind fixes.
  - Inspect common non-determinism sources: race conditions / unawaited async calls, shared mutable state across tests, test execution order, clock/timezone assumptions, or resource leaks.
  - Try running the test in stress/repeat mode or isolation; if it still cannot be triggered reliably, formulate your best hypothesis in Step 3 with `<80%` confidence and recommend **Option 3 (Targeted Diagnostic Instrumentation)** to capture runtime state on the next occurrence.

### Step 2: Localize

- Narrow down the exact layer, module, file, and line range where actual behavior diverges from expected behavior.
- Check recent changes (`git diff` / `git log -n 5`) if this is a regression ("worked yesterday, broke today").
- **Sibling copies**: search for other code that implements the same logic (same algorithm, same data/paths, sibling classes). The bug often lives in every copy, or exists because copies diverged. Note them in the diagnosis.

### Step 3: Formulate Root Cause Hypothesis

Present your diagnosis clearly in chat before touching production code:

```markdown
## Bug Diagnosis
- **Symptom**: <What is failing>
- **Location**: `<file_path#Lxx>`
- **Root Cause Hypothesis**: <Why it is failing, backed by concrete evidence from code/logs>
- **Sibling copies**: <`path:line` of code with the same logic (same bug?), or "none found">
- **Confidence**: ~X%
```

Fix the root cause **once, in a shared place**: if the fix needs logic that already exists elsewhere, reuse it; if the same logic lives in several copies, extract it and fix it there rather than patching each copy or adding one more (`/using-agent-skills`, behavior 6). If that extraction is large or crosses modules, take the architectural route below.

---

## 3. Resolution Route (Default-Proceed)

Once the root cause is identified, pick the route from the diagnosis and announce it in one line (the user can override):

- **Localized, well-understood bug (confidence `≥80%`)** → fix the root cause right now and add/update a **regression test** that fails without the fix and passes with it.
- **Confidence `<80%`, more runtime evidence needed** → add targeted diagnostic instrumentation/logging first. If reproducing needs the user (running the app, a device, a game), give them a short numbered checklist in their language and **STOP YOUR TURN**.
- **The bug exposes a deeper architectural flaw or a breaking API issue** → this is a decision gate: recommend `/proposal` or `/decompose` for a safe multi-step fix (e.g., in `.temp/<topic>/`) instead of patching a symptom — or `/architect` when the flaw is in the structure itself (module boundaries, dependency direction, the same rule spread across modules) rather than in one contract — ask one short question, and **STOP YOUR TURN**.

If the user asks about pros/cons or details of the diagnosis, answer and restate the pending route in one line.

---

## 4. Fix Verification & Forward Handoff

When fixing directly:

1. Write/update the regression test → apply the minimal fix → run the test suite to verify 100% green status. Prefer adding a case to the closest existing test of that unit over a new test method or file.
2. Next step, announced in one line:
   - **The bug occurred mid-task in `.temp/<topic>/`** → return to `/implement` and continue the active task file.
   - **The fix touches more than one module or a public contract** → proceed to `/review` (zero-write, safe).
   - **Otherwise** → recommend `/git` for a clean `fix:` commit and **STOP YOUR TURN** (committing needs confirmation).
