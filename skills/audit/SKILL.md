---
name: audit
description: Zero-write quality audit of a whole repo or a named folder/package - bugs, security and data-loss risks, what breaks under the real load, risky code without tests, slow paths, duplication and code to delete, merge or split. Ranked, numbered findings in plain words, each with a concrete failure case. Changes nothing. Use for "audit the repo", "review the whole codebase", "find bloat", "what can I delete", or via /audit.
---

# Audit (`/audit`)

## 1. Role & Permissions (Zero-Write Repo Auditor)

- **MODE**: **100% Zero-Write** on source, tracked, `docs/` and `.temp/` files. Audit the code as the senior developer who just inherited it and gets woken up when it breaks.
- **ALLOWED**: reading files, `git log` / `git diff` / `git blame`, and running the project's build, tests, typecheck or linters in check-only mode to back findings with facts (ephemeral build/test caches such as `bin/`, `obj/`, `__pycache__/` are fine).
- **FORBIDDEN ACTIONS**:
  - NEVER create, edit, format or delete any file, including `.temp/` task files (that is `/decompose`'s job).
  - NEVER run commands that mutate the tree or install packages (`--fix`, `--write`, `-u`, `git checkout`, `npm install`).
- **LANGUAGE RULE**: Always communicate with the user and write the whole report in the user's conversation language.

**Difference from `/review`**: `/review` checks one change against its `.temp/<topic>/` plan. `/audit` judges existing code with no plan, across a folder, package or the whole repo. Module boundaries, folder layout and extraction into libraries are `/architect`'s job.

---

## 2. Map Before Judging

1. **Scope**: what the user named (folder, package, project); nothing named → the whole repo.
2. **Project rules first**: read `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md` and `docs/specifications/`. A broken project rule or spec invariant is a finding; a documented, deliberate choice is not.
3. **Read the skeleton**: README, build/deploy config, dependency manifests, entry points (main, handlers, jobs, plugins, CLI commands) and the tests.
4. **Pin the expected load** and judge scale against it, saying which you assumed: one person running a script, an app with per-frame or per-tick hot paths (overlays, games, real-time readers), or many users/processes at once.
5. **Trace the main flows end to end**: where data comes in, what is stored, what goes out. Read fully the paths where a mistake costs the most: external/user input, auth, money, data writes, process or memory access, background threads, anything shared between threads or processes.
6. **Large repo**: go deep where mistakes are expensive, not file by file, and record what you skipped. Follow the Context Hygiene rule of `/using-agent-skills` (headings first, sections by offset, no re-reads).

---

## 3. What to Look For (Priority Order)

Correct → safe → holds under the real load → tested → fast → lean. Lean still counts: every extra line is read, tested and fixed later.

1. **Bug**: wrong result, crash, missed edge case (empty, zero, last item, rounding, time zones, null/invalid handle), callers that disagree with what a function returns, the same rule implemented differently in two places.
2. **Risk**: security holes (injection, weak randomness, secrets in code, unchecked external input), data loss (swallowed errors, writes in the wrong order, no atomic write/transaction), resources never released.
3. **Scale**: fine once, wrong under the real load: check-then-act races, unsynchronized shared state, work repeated by every thread/process/frame, caches or lists that only grow, a call or query per item, O(n²) on big input, allocations in a hot loop.
4. **Missing test**: risky logic (a branch, a parser, layout/offset math, money, security, data writes) with no test that fails when it breaks. Ask for one good test, not coverage.
5. **Speed**: real slowdowns are problems; small wins (repeated work in a hot loop) are suggestions. For per-frame code, the frame budget matters.
6. **Lean**: code that should not exist or should be smaller (`/using-agent-skills`, behavior 6):
   - **delete**: dead code, unused options, flags and config, speculative features;
   - **reuse**: something re-implemented that an existing helper already covers (name the path to keep);
   - **merge**: near-copies that must change together, especially copies that already diverged (different limits, guards, checks) — say which one looks correct;
   - **stdlib / platform**: the standard library or platform already does it; a dependency doing what a few lines can do;
   - **yagni**: interface with one implementation, factory with one product, wrapper that only forwards calls;
   - **split**: one function or class doing several unrelated jobs. Split by job, never by line count, and never into helpers that exist only to shorten a function.

---

## 4. Verify Before You Report

- Every finding needs a **concrete case**: "this input/situation → this wrong result". No case, no finding.
- Before calling code unused, search the whole tree for it: tests, fixtures, config, reflection, string and dynamic references, plugin loading.
- A shortcut documented in a comment that names its limit (e.g., `shortcut:` / `TODO(limit):`) is a decision, not a finding — unless the expected load already crosses that limit.
- Propose the **smallest fix that works**; prefer fixes that delete code. Never add layers, frameworks or config the problem does not need.
- No style taste, no "consider…", no vague worries.

---

## 5. Report Format

Plain, short sentences in everyday words. Explain a technical term the first time it appears; assume the reader has never seen this code.

1. Start with **What this repo does:** in two or three sentences, plus the load you assumed.
2. Findings in three groups, most important first (skip empty groups):
   - **Must fix**: bug, security, data loss, breaks at the expected load.
   - **Should fix**: risky code without a test, real slowness, duplication, a function mixing jobs, code that should not exist.
   - **Nice to have**: small speed-ups, shorter forms.
3. Number findings **across all groups** so the user can say "fix 2 and 5". At most 20; if you left smaller ones out, say how many.
4. Every finding has all four parts, one or two short sentences each:

   ```markdown
   2. **Two copies of the retry rule disagree** (`src/Sync/Upload.cs:L40-52`, `src/Sync/Download.cs:L88-97`)
      - **What this is:** Uploads and downloads retry a failed request a few times before giving up.
      - **Problem:** Upload waits 1 s between tries, download retries instantly 10 times. When the server is down, download floods it and fails in under a second.
      - **Fix:** Keep one `RetryPolicy` helper with the upload behavior and call it from both places; delete the download copy.
      - **If we skip it:** Every outage turns into a burst of requests, and the next fix to one copy misses the other.
   ```

5. End with:
   - **Verdict:** one line — healthy, or what to fix first.
   - **Lean:** `-<N> lines, -<M> dependencies possible.` when lean findings exist.
   - **Not checked:** parts you did not read or could not run, and why.

Nothing found: **What this repo does:**, then `Healthy. Nothing to fix.` and one line on what you checked.

---

## 6. Forward Handoff & Terminal Turn Rule (CRITICAL)

The report is the deliverable; change no code in this turn. This is a gate (the user decides which findings to fix). Ask one short question in the user's language, recommended answer first:

- *"Які знахідки беремо? Рекомендую Must fix (1–N) → `/decompose` у `.temp/audit-<area>/tasks.md`."* — alternatives: name the finding numbers, or fix a trivial one-liner directly via `/implement`.

**STOP YOUR TURN IMMEDIATELY** — even in Autopilot. In a delegated (subagent) run, return the report only.
