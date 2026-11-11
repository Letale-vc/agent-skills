---
name: spec
description: Creates or updates the normative specifications in docs/specifications/ - how a module works and must behave right now - its contracts, invariants and module dependency rules, through a fresh pas:spec-writer subagent. Runs only in projects that keep docs/specifications/ (or when the user asks for the first one). Use after a reviewed change alters public behavior, contracts or dependency rules, when the user asks to document how an existing module works, when the specifications no longer match the code, or via /pas:spec.
argument-hint: "[topic | module]"
---

# Spec

Mode: writes **only** `docs/specifications/*.md` and the project's documentation index entry for a spec created, renamed or removed; never source, tests or `.temp/` (`${CLAUDE_PLUGIN_ROOT}/shared/rules.md`). The writing goes to `pas:spec-writer`; the main session prepares the input and relays the report.

## 1. When it runs

1. **No `docs/specifications/`** in the project → skip and say so in one line, unless the user explicitly asks for the first specification (then ask once which language and location `docs/` uses, if nothing shows it).
2. **After a change** (a `.temp/<topic>/` exists): resolve the topic (rules §3). Unchecked tasks or no approving review yet → say so in one line and recommend `/pas:review` first; an explicit `/pas:spec` from the user proceeds anyway.
3. **Standalone**: the user asks to document an existing module → no topic; the module's code is the input.

## 2. Spawn the writer

One `pas:spec-writer` (model from its definition). The prompt carries:

* the reason: the topic path and the diff range, or the module to document;
* where the intended change is stated: the spec-impact section of `proposal.md`, or the `## Context & Intent` header of the task file;
* the target dependency rules, if any: from `Constraints` of the task header or the proposal's placement or structure section;
* the specs likely affected (a `pas:scout` question if unclear).

The agent owns the writing rules: the current state only, never plans or history; the existing specs' format and language; stable invariant IDs; dependency rules as invariants only once the code follows them; links that resolve. A host without subagents follows `${CLAUDE_PLUGIN_ROOT}/agents/spec-writer.md` in this session.

## 3. Handoff

1. Relay the report: specs created or changed, invariants added or changed (one line each), the index entry, anything left out and why.
2. Next step, announced in one line:
   * uncommitted changes → `/pas:git` (it asks before committing and offers to delete the finished `.temp/<topic>/`);
   * run from `/pas:flow` → return the report to the flow;
   * nothing left → end the turn.
3. The user asks to refine a spec → spawn the writer again with the request, relay, end the turn.
