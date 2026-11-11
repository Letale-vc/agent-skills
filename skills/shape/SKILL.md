---
name: shape
description: Turns a raw idea or an underspecified request into a confirmed statement of intent (goal, success criteria, constraints, assumptions, out of scope) before any design or task writing. Offers 2–3 concrete directions with a recommendation when the idea has no shape yet, then asks at most five high-impact questions one at a time, each with its own hypothesis and guess. Read-only. Use when the user has a vague spark ("I want something like…", "not sure how to put it"), when a request lacks who, why, success or boundaries, before /pas:proposal on large work, or via /pas:shape.
argument-hint: "[idea or request]"
---

# Shape

**Mode**: read-only. The result is a block in chat, never a file. Interactive only: in a subagent or CI, report `blocked:` with the open questions instead.

Read `${CLAUDE_PLUGIN_ROOT}/shared/rules.md` first (gates, language, context hygiene).

## 1. Pick the starting step

* **No shape yet** (a feeling, a pain point, "something like…") → start at §2.
* **Goal known, boundaries unclear** (who, why now, what done means, what must not change) → skip to §3.
* **Goal, criteria and scope already clear** → write the intent block (§4) straight away.

When the options depend on what the code already has, send one narrow question to `pas:scout` first, so the directions name real modules instead of guesses.

## 2. Diverge

1. Mirror the underlying problem or goal in 1–2 sentences.
2. Offer 2–3 concrete directions, each a mechanism the user can react to, not an abstraction. Put the recommended one first with a one-line reason; make the others genuinely different (simpler, more automated, a different owner).
3. Ask one question: which direction is closest, or what to mix or change.
4. **Stop the turn.** Repeat until a direction is chosen, then go to §3 (or §4 if nothing is unclear).

## 3. Clarify

Ask the questions whose answers change the behavior or the architecture; never spend a turn on naming or minor details. One question per turn, in this form:

```text
HYPOTHESIS: <one-sentence read of what the user wants>
CONFIDENCE: ~X% (question N of max 5): <what is still missing, when below 70%>
Q: <one focused question>
GUESS: <your recommended answer and why>
```

* **Stop the turn** after each question.
* A vague value word ("scalable", "clean", "fast") → ask what concrete outcome it means.
* "What do you recommend?" → give the trade-off and the recommendation, then restate the pending question in one line.
* **Stop asking** when you could predict the answers to the next three questions, or after five questions. Details still open become explicit defaults under `Assumptions`, approved all at once.

## 4. Intent block

```markdown
## Intent: <short name>

- **Goal**: <what changes, for whom, and why now>
- **Success criteria**: <verifiable outcomes that define done>
- **Constraints**: <binding limits, must-keep behavior, always / never rules>
- **Assumptions**: <defaults taken without asking, or "none">
- **Out of scope**: <what this work does not change>
```

Ask for an explicit confirmation (yes / refine). A refinement is folded in and the block shown again. A vague delegation ("whatever you think") confirms only the defaults you name in `Assumptions`.

## 5. Handoff

Once confirmed, continue in the same turn, announced in one line:

* inside a `/pas:flow` run → back to the flow at `proposal` (large) or at the route the block now fits;
* standalone → `/pas:flow <goal>` with the block in context; it picks the size, and on the large route `/pas:proposal` records the block as its Section 1.
