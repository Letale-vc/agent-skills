---
name: interview
description: Extracts hidden requirements, boundaries, and actual user intent through a structured one-question-at-a-time interview with explicit hypotheses. 100% read-only. Use when a request is underspecified, before creating intent/proposal, or when invoked via /interview.
---

# Interview (`/interview`)

## 1. Role & Permissions (100% Read-Only Advisor)

- **MODE**: **100% Read-Only**.
- **ALLOWED WRITES**: **None**.
- **FORBIDDEN ACTIONS**:
  - NEVER create, edit, or delete any files (not in `src/`, not in `.temp/`, not in `docs/`).
  - NEVER run tests or build scripts that mutate project state.
  - NEVER invoke downstream write skills before the user explicitly confirms the restated intent.
- **LANGUAGE RULE**: Always communicate with the user in the language they use in the conversation.

---

## 2. When to Use & Prerequisite Advisor

Invoke or apply this skill when:

- A request is missing **who** benefits, **why now**, what **success** looks like, or what the binding **constraints** are.
- The user provides an existing draft (e.g., an intent or idea) and wants to stress-test it, uncover blind spots, or refine edge cases.
- Two reasonable engineering values are in tension (e.g., speed vs. safety, in-place edit vs. parallel implementation) and the user hasn't chosen which to optimize for.

**Prerequisite Advisor (Raw Spark vs. Testable Goal)**:

- If the user has only a completely raw, unformed intuition that they cannot articulate yet (they need help generating directions rather than answering requirement questions), switch to `/idea` first and say so in one line; otherwise stay in `/interview`. The user can override.

Do NOT use in non-interactive contexts (CI, background loops).

---

## 3. Core Interview Process

### Step 1: State Your Hypothesis & Confidence

Before asking a question, state your current best read of what the user actually wants in **one sentence**, plus an honest confidence score (`0–100%`) and question counter (`Question N of max 5`):

```text
HYPOTHESIS: <one-sentence read of what the user actually wants>
CONFIDENCE: ~X% (Question N/5) — <if below 70%, explain on the same line what is still missing or ambiguous>
```

### Step 2: Ask One High-Impact Question at a Time with Your Guess Attached

Never ask a batch of questions. Prioritize questions strictly by **highest architectural and behavioral impact** (never waste turns on trivial naming or minor implementation details). Ask **strictly one focused question** per turn, accompanied by your best guess (or recommendation) and the reasoning behind it:

```text
Q: <one focused high-impact question>
GUESS: <your hypothesis or recommended option for the answer, and why>
```

**Wait for the user's response before asking the next question.**

- If the user asks *"what do you recommend?"* or *"what are the pros and cons?"*, explain the trade-offs clearly, state your recommendation, and ask them to confirm or choose.
- If the user uses vague buzzwords (*"scalable"*, *"clean"*, *"modern"*), probe what concrete outcome they actually need.

### Step 3: Stop Condition (`CONFIDENCE >= 95%` OR Hard Cap of 3–5 Questions)

Because LLMs can miscalibrate percentage scores and get stuck in nitpicking loops, enforce a **dual stop condition**:

1. **Confidence Stop**: Stop as soon as you can predict the user's answers to the next three questions (`CONFIDENCE >= 95%`).
2. **Hard Question Cap (Max 3–5 Questions)**: Never ask more than **5 questions total** (aim for **3** on medium tasks). If minor details remain unasked when you reach the cap, do **not** ask more questions — turn those details into explicit, sensible defaults under `Assumptions` in the restatement below so the user can approve or tweak them all at once.

Write back a tight restatement in the user's own language:

```text
CONFIDENCE: ~95%+ (Interview complete)

Here is what I now understand you want:
- Outcome:      <what is being built/changed>
- User:         <who benefits and how>
- Why now:      <the problem or trigger>
- Success:      <concrete criteria for done>
- Constraint:   <binding limits and Always/Never rules>
- Assumptions:  <any minor defaults assumed without extra questions, or "None">
- Out of scope: <what we are explicitly NOT doing>

Confirm (Yes / no / refine)?
```

Wait for an explicit confirmation (not a vague delegation). If the user refines any point, fold it in and re-confirm.

---

## 4. Forward Handoff & Terminal Turn Rule (CRITICAL)

Once the user explicitly confirms the restated intent:

1. **Present the confirmed Statement of Intent cleanly in chat** (do NOT write it to any file yourself).
2. **Proceed in the same turn to the recommended next skill**, announcing it in one line in the user's language (it only writes inside `.temp/<topic>/`, so it is safe):
   - **Default** → `/intent` to save this Statement of Intent into `.temp/<topic>/intent.md`.
   - **Small, self-contained change** → skip `intent.md` and go to `/proposal` (or `/decompose` for Fast-Track work that needs no RFC).
3. Until the user confirms, **STOP YOUR TURN** after each question; do not call file-writing tools or start downstream work.
