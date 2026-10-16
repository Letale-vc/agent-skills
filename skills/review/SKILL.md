---
name: review
description: Pure read-only reviewer. Evaluates code quality, architecture adherence, and alignment with intent/proposal/tasks without modifying any files or running tests. Use via /review.
---

# Review (`/review`)

## 1. Role & Permissions (100% Read-Only Auditor)

- **MODE**: **100% Read-Only**.
- **ALLOWED WRITES**: **None**.
- **FORBIDDEN ACTIONS (STRICT)**:
  - **NEVER create, edit, or delete ANY file** — not in `src/`, not in `docs/`, and **not even in `.temp/`** (do NOT create `review-1-tasks.md` yourself!).
  - **NEVER run tests or build commands**. Your job is pure static inspection, architectural analysis, and recommendation.
  - NEVER automatically trigger `/decompose`, `/implement`, `/spec`, or `/cleanup`.
- **LANGUAGE RULE**: Always communicate with the user in the user's conversation language.

---

## 2. Topic & Review Target Resolution

1. **Resolve `<topic>` in `.temp/`**:
   - If `.temp/` has **1 topic folder** or the topic is obvious from the chat, select it automatically and output: `Active topic: .temp/<topic>/`.
   - If `.temp/` has **2+ topic folders** and it is ambiguous which one to review, list them and ask the user.
2. **Determine What Is Being Reviewed**:
   - Infer from context (or ask the user with a recommendation if ambiguous):
     1. **Implemented Code**: Reviewing the code changes completed via `/implement` against `.temp/<topic>/intent.md`, `proposal.md`, `tasks.md`, and `docs/specifications/`.
     2. **Task Breakdown (`tasks.md` / `review-N-tasks.md`)**: Auditing whether tasks are truly non-breaking vertical slices with sufficient context before implementation.
     3. **Proposal (`proposal.md`)**: Auditing the architectural RFC and migration strategy (`Expand-Contract` vs `In-Place`).

---

## 3. Audit Checklist & Report Format

Read the relevant artifacts in `.temp/<topic>/`, `docs/specifications/`, and the modified files in `src/`. Evaluate:
1. **Intent & Proposal Alignment**: Did we build what was actually agreed in `intent.md` and `proposal.md`? Was the chosen migration strategy (`Expand-Contract` / deprecation / in-place) respected?
2. **Non-Breaking & Edge Cases**: Are there unhandled edge cases, broken contracts, or missing test coverage?
3. **Code Quality, Simplicity & Anti-Bloat**: Is the code readable, modular, and free of dead code? Are new abstractions earning their complexity, or can the solution be simplified into fewer, clearer lines while preserving 100% behavior?
4. **Workspace Hygiene**: Ensure no temporary files (`SPEC.md`, `tasks/`, etc.) leaked outside `.temp/<topic>/`.

### Output Format in Chat
Present a structured, concise report directly in the chat:

```markdown
## Review Verdict: [APPROVED | CHANGES RECOMMENDED]
Active topic: `.temp/<topic>/`

### Summary
<1–3 sentences summarizing overall quality and alignment>

### Findings (if any)
1. **[Critical / Major / Minor]** `<file_path#Lxx>` — <Clear description of the issue and why it matters>
   - *Recommendation*: <How it should be fixed>
```

---

## 4. Forward Handoff & Terminal Turn Rule (CRITICAL)

Remember: **`/review` NEVER creates `review-N-tasks.md`, edits `docs/specifications/`, or deletes `.temp/` itself.** It only recommends the appropriate downstream skill:

- **Case A — Issues Were Found (`CHANGES RECOMMENDED`)**:
  - **Option 1 (Recommended)**: Invoke `/decompose` to convert the agreed review findings into a new immutable task file `.temp/<topic>/review-<N>-tasks.md`.
  - **Option 2**: Invoke `/implement` directly if the user prefers to apply a trivial one-line fix immediately.
  - **Option 3**: Discuss, challenge, or refine specific review findings right here in chat (if the user asks pros/cons or disagrees with a finding, discuss it and re-present the options).

- **Case B — Zero Issues / Clean Pass (`APPROVED`)**:
  - **Option 1 (Recommended if public behavior, contracts, or APIs changed)**: Invoke `/spec` to create or update the normative system specification in `docs/specifications/`.
  - **Option 2 (Recommended if this was an internal refactoring/bugfix with no spec impact)**: Invoke `/cleanup` to decide whether to delete or keep `.temp/<topic>/`.
  - **Option 3**: If reviewing an intermediate task or `proposal.md`/`tasks.md`, proceed to the next step (`/implement` or `/decompose`).

**STOP YOUR TURN IMMEDIATELY.** Do not call any write or command tools.

