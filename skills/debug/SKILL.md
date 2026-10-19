---
name: debug
description: Guides systematic root-cause debugging (Reproduce -> Localize -> Root Cause Hypothesis -> Fix & Guard). Use when tests fail, builds break, or unexpected bugs occur, or via /debug.
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

### Step 3: Formulate Root Cause Hypothesis

Present your diagnosis clearly in chat before touching production code:

```markdown
## Bug Diagnosis
- **Symptom**: <What is failing>
- **Location**: `<file_path#Lxx>`
- **Root Cause Hypothesis**: <Why it is failing, backed by concrete evidence from code/logs>
- **Confidence**: ~X%
```

---

## 3. Interactive Resolution Advisor (CRITICAL)

Once the root cause is identified, present the resolution options with your recommendation:

- **Option 1 (Recommended for localized, well-understood bugs)**:
  - Fix the root cause directly right now and add/update a **regression test** that fails without the fix and passes with it.
- **Option 2 (Recommended if the bug exposes a deeper architectural flaw or breaking API issue)**:
  - Hand off to `/proposal` or `/decompose` to plan a safe multi-step fix (e.g., in `.temp/<topic>/`) instead of patching a symptom.
- **Option 3**: Add targeted diagnostic instrumentation/logging first (if confidence in the root cause is `<80%` and more runtime evidence is needed).

*Note*: The user can ask about pros/cons or details of the diagnosis. Answer and re-present the options until they choose.

---

## 4. Fix Verification & Forward Handoff

If the user chooses **Option 1 (Direct Fix + Regression Test)**:

1. Write/update the regression test → apply the minimal fix → run the test suite to verify 100% green status.
2. Offer the next-step options with your recommendation:
   - **Option 1 (Recommended)**: Run `/review` to verify the fix is clean and introduces no side effects.
   - **Option 2**: Run `/git` to create a clean `fix:` commit.
   - **Option 3**: Return to `/implement` if this bug occurred mid-task in `.temp/<topic>/`.
3. **STOP YOUR TURN IMMEDIATELY.**
