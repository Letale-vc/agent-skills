---
name: proposal
description: Writes the design for large work into .temp/<topic>/proposal.md - goal and success criteria, conflicts with existing code, specifications and library versions, where the new code lives, reuse - then spawns 2–3 pas:architect agents in parallel (minimal, clean, pragmatic), compares their variants in one table with a recommendation, and records the variant and integration strategy (Expand-Contract or In-Place) the user picks. Use for large work - a new public contract, module, project or layer, or a change across layers - when /pas:flow reaches the proposal stage, when a task's Design line names a topic, or via /pas:proposal.
argument-hint: "[topic]"
---

# Proposal

**Mode**: writes `.temp/` (`proposal.md` only). No production code in it: contracts, signatures, short pseudo-code or diagrams at most.

Read `${CLAUDE_PLUGIN_ROOT}/shared/rules.md` first (topics, `.gitignore` guard, gates, reuse, context hygiene).

Small and medium work needs no proposal: say so in one line and hand the goal to `/pas:flow`, unless the user insists.

## 1. Intent

Resolve the topic (rules.md §3) and find Section 1 of the proposal, in this order:

1. A confirmed intent block from `/pas:shape` in the chat → use it as is.
2. A task in another topic whose `**Design**:` line names this topic → that task and its file's `## Context & Intent` header are the intent; its `Constraints` are binding (the structure was decided there).
3. Goal, criteria and scope clear from the chat → write them down and say so in one line.
4. Still vague → run `/pas:shape` first, then return here.

## 2. Context

Spawn `pas:scout` in parallel, one narrow question each, with the names and paths from the intent:

* the code the change touches: entry points, public types and their callers;
* `docs/specifications/` invariants and dependency rules the change must keep;
* existing code that already does the same or nearly the same (rules.md §7);
* the exact versions of the libraries the design relies on, from the project manifest. Check their behavior in official documentation or existing project code, not from memory.

## 3. Draft Sections 1–4

Write `proposal.md` with the template in §6 up to Section 4:

* **Conflicts**: every place where the intent disagrees with the code, a spec or a library version, with `path:line`. A conflict only the user can settle is gate 2: ask before spawning architects.
* **Placement**: where each new piece lives, by the project's layout rules and current dependency direction. A new module or package, an extraction, or a dependency arrow pointing the wrong way means the structure itself is open: recommend `/pas:audit structure` first (gate 2), or continue inside the current structure if the user prefers.
* **Reuse**: per new piece, `reuse path:line`, `extract <Name> from path:line + path:line` (note divergences), or `new (searched: <terms>)`.

## 4. Variants

1. Spawn `pas:architect` agents in parallel, one per lens: **minimal** (smallest change, maximum reuse), **clean** (the boundaries the next extensions want), **pragmatic** (the balance). Use two when minimal and pragmatic would coincide. Each gets Sections 1–4, the scout conclusions and its lens, never this session's reasoning.
2. Check each report against the conflicts and placement rules; a variant that breaks a binding constraint is dropped with one line of reason.
3. Write Section 5: one comparison table and a recommendation with its reasons.
4. **Gate 2**: ask which variant to take, recommended first. In a `/pas:flow` run this is the only stop of the stage.

## 5. Record the choice

1. Write Section 6 from the chosen variant: strategy and old-code policy, contracts and boundaries, spec impact, risks. Set `Status` to the choice and the date.
2. Shrink the other variants in Section 5 to one line each; the table may stay.
3. Check the size (`wc -l`): target ≤ 150 lines, hard cap 300. Over the cap, the topic is too big: split it into topics with their own proposals and say so.
4. Hand off: in a flow run, continue to `decompose`. Standalone, this stage is a clear point (complexity.md §3): give the user `/pas:flow <topic>` (or `/pas:decompose <topic>`) as the next message.

Later revisions edit sections in place: no changelogs, no "review fixes" sections, no superseded alternatives.

## 6. Template

```markdown
# Proposal: <title>

Status: draft | <variant> chosen <date>

## 1. What & why
- <what changes, for whom, why now>
- **Success criteria**: <verifiable outcomes>
- **Out of scope**: <what this topic does not change>

## 2. Conflicts
- <code / spec / version conflict with `path:line`, or "none found">

## 3. Placement
- <new piece → module or folder, and the dependency rules it keeps>

## 4. Reuse
- <reuse / extract / new, per piece>

## 5. Variants
| | Minimal | Clean | Pragmatic |
| --- | --- | --- | --- |
| Files touched | | | |
| New public types or contracts | | | |
| Strategy | | | |
| Main risk | | | |

**Recommendation**: <variant, and why>

## 6. Chosen design
- **Strategy**: Expand-Contract (new code beside the old, callers switch at the end; old code deprecated | removed) | In-Place
- **Contracts & boundaries**: <signatures, interfaces, dependency rules; no implementation code>
- **Spec impact**: <files in docs/specifications/ to update via /pas:spec, or "none">
- **Risks**: <key risks and non-goals>
```
