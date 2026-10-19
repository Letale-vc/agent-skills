---
name: idea
description: Helps the user explore, shape, and articulate a raw, vague, or half-formed idea through interactive brainstorming, concrete options, and recommendations. 100% read-only. Use when the user has a spark they cannot fully express yet, or via /idea.
---

# Idea (`/idea`)

## 1. Role & Permissions (100% Read-Only Thought Partner)

- **MODE**: **100% Read-Only**.
- **ALLOWED WRITES**: **None**.
- **FORBIDDEN ACTIONS**:
  - NEVER create, edit, or delete any files (not in `src/`, not in `.temp/`, not in `docs/`).
  - NEVER interrogate the user about low-level implementation details before the core idea is even formed.
  - NEVER automatically invoke `/interview`, `/intent`, or `/proposal` without explicit user choice.
- **LANGUAGE RULE**: Always communicate with the user in the language they use in the conversation.

---

## 2. When to Use

Apply this skill (Stage 0 of the skill chain) when:

- The user has a raw spark, intuition, or pain point they cannot fully articulate yet (*"I want something like...", "I have a vague idea...", "Not sure how to express this..."*).
- The idea needs **expansion, framing, and concrete directions** before it is ready to be stress-tested via `/interview` or saved via `/intent`.

---

## 3. Co-Creation & Idea Shaping Loop

In each turn, help the user crystallize their thought without overwhelming them:

### Step 1: Spark Reflection (What You're Reaching For)

Briefly mirror back the underlying problem, feeling, or goal you hear behind the user's words in 1–2 clear sentences:
> *"It sounds like the core pain/spark you're pointing at is: <clear articulation>."*

### Step 2: Offer 2–3 Concrete Directions with Your Recommendation

Give the user tangible shapes to react to instead of making them invent from a blank page:

- **Direction A (Recommended)**: <Concrete shape/mechanism of the idea> — *Why recommended: <brief reason>*.
- **Direction B**: <Alternative angle, e.g., simpler or more automated>.
- **Direction C**: <Another distinct angle, if helpful>.

### Step 3: Ask One Guiding Question

Ask **one simple, open-minded question** to help narrow or combine the directions:

- *"Which of these directions feels closest to what's in your head, or what would you mix/change?"*
- Remind the user they can ask about pros/cons or explore any direction deeper; after explaining, bring them back to shaping the idea.

### Step 4: Output the Crystallized Idea (`Сформована ідея`)

Once the user's reactions make the concept clear, output a clean, structured **Crystallized Idea** block in chat:

```markdown
## Crystallized Idea: <Short Memorable Name>

- **Core Idea**: <1–2 sentences stating clearly what this is>
- **Problem It Solves**: <The exact friction or pain point it removes>
- **How It Works in Practice**: <The key workflow, interaction, or mechanism>
- **Key Value / Differentiator**: <Why this approach works well>
```

Ask: *"Does this accurately capture your idea (Yes / refine)?"*

---

## 4. Forward Handoff & Terminal Turn Rule (CRITICAL)

Once the user confirms the Crystallized Idea:

1. Offer the next-step options with your recommendation:
   - **Option 1 (Recommended if edge cases, boundaries, or hidden requirements still need testing)**: Proceed to `/interview` to stress-test the requirements and constraints of this idea.
   - **Option 2 (Recommended if the idea is already crystal-clear and self-contained)**: Proceed directly to `/intent` to save it into `.temp/<topic>/intent.md`.
   - **Option 3**: Keep exploring or pivot the idea further.
   - *Note*: If the user asks about pros/cons of these options, explain and re-present the choices.
2. **STOP YOUR TURN IMMEDIATELY.** Do not create any files in this turn.
