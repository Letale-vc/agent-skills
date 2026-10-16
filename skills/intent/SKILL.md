---
name: intent
description: Captures and saves a concise Statement of Intent into .temp/<topic>/intent.md. Use after /interview or when starting a new feature topic via /intent.
---

# Intent (`/intent`)

## 1. Role & Permissions (Scoped Intent Writer)

- **MODE**: **Scoped Writer**.
- **ALLOWED WRITES**:
  - `.temp/<topic>/intent.md`
  - `.gitignore` (only to ensure `.temp/` is ignored)
- **FORBIDDEN ACTIONS**:
  - NEVER create or modify files in `src/`, `docs/`, or the project root (except `.gitignore`).
  - NEVER write implementation code or task lists in this skill.
- **LANGUAGE RULE**: Always communicate with the user and write `.temp/<topic>/intent.md` in the user's conversation language.

---

## 2. Topic Resolution & `.gitignore` Guard

1. **Ensure `.temp/` is git-ignored**:
   - Check `.gitignore` in the project root. If `.temp/` is missing, append `.temp/` to `.gitignore`.
2. **Resolve `<topic>`**:
   - Inspect existing folders inside `.temp/`.
   - If `.temp/` has **1 existing topic folder** that matches the current discussion, or if a clear topic slug (e.g., `auth-refactor`) is obvious from the conversation, select it automatically and state at the top of your reply: `Active topic: .temp/<topic>/`.
   - If `.temp/` has **2+ topic folders** and it is ambiguous which one applies, list the existing topics and ask the user which one to use (or whether to create a new `<topic>`).

---

## 3. Prerequisite Advisor (Interactive Loop)

Before writing `.temp/<topic>/intent.md`, evaluate whether the intent has already been clarified in the chat:

- **Case A — Intent was already confirmed via `/idea` / `/interview` or is crystal-clear in chat**:
  - Proceed directly to Section 4 and write `.temp/<topic>/intent.md`.
- **Case B — Request is underspecified, ambiguous, or missing key boundaries**:
  - Do NOT block rigidly. Present the user with choices and a clear recommendation:
    1. **(Recommended if the idea is still raw/unformed)** Run `/idea` first to explore directions and articulate the core concept.
    2. **(Recommended if the goal is known but boundaries/requirements need checking)** Run `/interview` first (1 question at a time) before saving `intent.md`.
    3. **(Recommended if you want a fast draft now)** Generate a draft `.temp/<topic>/intent.md` immediately from the current context, which we can refine together.
  - Tell the user they can pick an option or ask about pros/cons/details. If they ask a question, answer it and **re-present the options** until they choose.

---

## 4. Artifact Structure (`.temp/<topic>/intent.md`)

Write a clean, structured document to `.temp/<topic>/intent.md` containing:

```markdown
# Statement of Intent: <Title>

## 1. Problem & Context (Why Now)
- <Why the current state is insufficient and what triggered this work>

## 2. Outcome & Target User
- **User**: <Who benefits>
- **Outcome**: <High-level result to achieve>

## 3. Success Criteria
- <Concrete, verifiable outcomes that define success>

## 4. Boundaries (Always / Never)
- **Always**: <Invariants that must hold>
- **Never**: <Actions or patterns that are strictly forbidden>

## 5. Out of Scope
- <What we are explicitly NOT building or solving in this topic>
```

---

## 5. Forward Handoff & Terminal Turn Rule (CRITICAL)

After saving `.temp/<topic>/intent.md`:
1. Link to the created file `.temp/<topic>/intent.md`.
2. Offer the next-step options with your recommendation:
   - **Option 1 (Recommended)**: Proceed to `/proposal` to analyze codebase/spec impact, choose the migration strategy, and create `.temp/<topic>/proposal.md`.
   - **Option 2**: Skip `/proposal` and go straight to `/decompose` (`.temp/<topic>/tasks.md`) if the change is simple and requires no architectural RFC.
   - **Option 3**: Refine or adjust `.temp/<topic>/intent.md`.
   - *Note*: If the user asks follow-up questions or pros/cons, explain and re-present these options.
3. **STOP YOUR TURN IMMEDIATELY.** Wait for the user's decision.

