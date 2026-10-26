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
   - Check `.gitignore` in the project root. If no existing line already ignores it (`.temp`, `.temp/`, `/.temp/`, ignoring trailing whitespace or `\r`), append `.temp/` once; never add a duplicate entry.
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
  - Do NOT block rigidly. Pick the route and announce it in one line (the user can override):
    - **The idea is still raw/unformed** → run `/idea` first.
    - **The goal is known but boundaries/requirements need checking** → run `/interview` first (1 question at a time), then save `intent.md`.
    - **The user asked for a fast draft** → write a draft `.temp/<topic>/intent.md` now from the current context and refine it together.

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
2. **Proceed in the same turn to the recommended next skill**, announcing it in one line in the user's language (both write only inside `.temp/<topic>/` and end with their own checkpoint):
   - **Default** → `/proposal` to analyze codebase/spec impact, choose the migration strategy, and create `.temp/<topic>/proposal.md`.
   - **Simple change that needs no architectural RFC** → `/decompose` (`.temp/<topic>/tasks.md`).
3. If the user asks to refine `intent.md` instead, do that and **STOP YOUR TURN**.
