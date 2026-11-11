---
name: audit
description: Zero-write audit of a whole repo or a named folder or package, in two modes. Code mode finds bugs, security and data-loss risks, what breaks under the real load, risky code without tests, slow paths, duplication and code to delete, merge or split. Structure mode maps modules and dependency direction, finds cycles, leaky boundaries and layouts that fight how the code changes, decides what should become a separate module, package, library or service, and designs a target structure with a non-breaking roadmap. Ranked, numbered findings in plain words, each with a concrete failure case; changes nothing. Use for "audit the repo", "review the whole codebase", "find bloat", "what can I delete", "review the architecture", "how should I structure the project", "should this be a separate library", "where should new code live", or via /pas:audit.
argument-hint: "[code|structure] [path]"
---

# Audit (`/pas:audit [code|structure] [path]`)

Mode: **read-only** ([rules.md](${CLAUDE_PLUGIN_ROOT}/shared/rules.md) §1), `.temp/` included: persisting the chosen findings is `/pas:decompose`'s job. Judge the code as the senior developer who just inherited it and is woken up when it breaks.

* `/pas:review` checks one change against its `.temp/<topic>/` plan; `/pas:audit` judges existing code with no plan.
* `/pas:proposal` (with `pas:architect` variants) designs one planned change; structure mode decides which structural changes are worth making and in what order.

## 1. Pick the mode

* **code** (default): what is wrong inside the code.
* **structure**: its shape: modules, boundaries, dependency direction, layout, extraction. Taken when the first argument is `structure` or the request is about architecture, layout, extraction or where code should live. Read [structure.md](structure.md) now and follow it in place of §3–§5 below.
* A request for both → code mode first; offer structure mode in the closing question.

## 2. Map before judging

1. **Scope**: the path in the arguments or named by the user; none → the whole repo.
2. **Project rules first**: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `docs/specifications/`, ADRs. A broken project rule or spec invariant is a finding; a documented, deliberate choice is not, unless its stated reason no longer holds (say which reason broke).
3. **Skeleton**: README, build and deploy config, dependency manifests, entry points (main, handlers, jobs, plugins, CLI commands), the tests.
4. **Expected load**, stated in the report: one person running a script, an app with per-frame or per-tick hot paths, or many users or processes at once. Scale is judged against it.
5. **Main flows end to end**: where data comes in, what is stored, what goes out. Read fully the paths where a mistake costs most: external input, auth, money, data writes, process or memory access, background threads, state shared between threads or processes.
6. **Large repo**: go deep where mistakes are expensive, not file by file. Fan independent questions (one per module or flow) out to `pas:scout` in parallel; read the expensive paths yourself. Record what you skipped.

## 3. What to look for (code mode)

Correct → safe → holds under the real load → tested → fast → lean. Lean counts: every extra line is read, tested and fixed later.

1. **Bug**: wrong result, crash, missed edge case (empty, zero, last item, rounding, time zones, null or invalid handle), callers that disagree with what a function returns, the same rule implemented differently in two places.
2. **Risk**: security holes (injection, weak randomness, secrets in code, unchecked external input), data loss (swallowed errors, writes in the wrong order, no atomic write or transaction), resources never released.
3. **Scale**: fine once, wrong under the real load: check-then-act races, unsynchronized shared state, work repeated by every thread, process or frame, caches or lists that only grow, a call or query per item, O(n²) on big input, allocations in a hot loop.
4. **Missing test**: risky logic (a branch, a parser, layout or offset math, money, security, data writes) with no test that fails when it breaks. Ask for one good test, not coverage.
5. **Speed**: real slowdowns are problems; small wins in a hot loop are suggestions. For per-frame code the frame budget matters.
6. **Lean**: code that should not exist or should be smaller:
   * **delete**: dead code, unused options, flags and config, speculative features;
   * **reuse**: a re-implementation of an existing helper (name the path to keep);
   * **merge**: near-copies that must change together, especially copies that already diverged (different limits, guards, checks): say which one looks correct;
   * **stdlib / platform**: the standard library or platform already does it; a dependency doing what a few lines can do;
   * **yagni**: an interface with one implementation, a factory with one product, a wrapper that only forwards calls;
   * **split**: one function or class doing unrelated jobs. Split by job, never by line count, never into helpers that exist only to shorten a function.

## 4. Verify before you report

* Every finding needs a **concrete case**: "this input or situation → this wrong result". No case, no finding.
* Before calling code unused, search the whole tree: tests, fixtures, config, reflection, string and dynamic references, plugin loading.
* A shortcut whose comment names its limit (`shortcut:`, `TODO(limit):`) is a decision, not a finding, unless the expected load already crosses that limit.
* Back findings with facts where cheap: the project's build, tests, typecheck or linters in check-only mode, `git log` / `git blame`.
* Propose the **smallest fix that works**, preferring fixes that delete code; never a layer, framework or config the problem does not need. No style taste, no "consider…", no vague worries.

## 5. Report

Plain, short sentences in everyday words; explain a technical term the first time it appears; assume the reader has never seen this code.

1. **What this repo does:** two or three sentences, plus the load you assumed.
2. Findings in groups, most important first, empty groups skipped:
   * **Must fix**: bug, security, data loss, breaks at the expected load.
   * **Should fix**: risky code without a test, real slowness, duplication, a function mixing jobs, code that should not exist.
   * **Nice to have**: small speed-ups, shorter forms.
3. Number findings **across all groups** so the user can say "fix 2 and 5"; at most 20, and say how many smaller ones you left out.
4. Each finding has four parts, one or two short sentences each:

   ```markdown
   2. **Two copies of the retry rule disagree** (`src/sync/upload.ts:40-52`, `src/sync/download.ts:88-97`)
      - **What this is:** Uploads and downloads retry a failed request a few times before giving up.
      - **Problem:** Upload waits 1 s between tries, download retries instantly 10 times. When the server is down, download floods it and fails in under a second.
      - **Fix:** Keep one `retryPolicy` helper with the upload behavior, call it from both places, delete the download copy.
      - **If we skip it:** Every outage turns into a burst of requests, and the next fix to one copy misses the other.
   ```

5. End with **Verdict:** (one line: healthy, or what to fix first), **Lean:** `-<N> lines, -<M> dependencies possible.` when lean findings exist, and **Not checked:** what you did not read or could not run, and why.

Nothing found: **What this repo does:**, then `Healthy. Nothing to fix.` and one line on what you checked.

## 6. Handoff

The report is the deliverable and lives only in this chat, so the chosen findings must reach a file before the session ends. Choosing them is gate 3 ([rules.md](${CLAUDE_PLUGIN_ROOT}/shared/rules.md) §5). Ask one short question, recommended answer first:

* code mode: take Must fix (1–N) → `/pas:decompose` into `.temp/audit-<area>/tasks.md`; alternatives: name the finding numbers, or fix a trivial one-liner straight away with `/pas:implement`;
* structure mode: the closing question in [structure.md](structure.md) §6.

Then stop the turn, even inside `/pas:flow`. In a subagent run, return the report only.
