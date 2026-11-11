# Routes, complexity score and context budget

The project may override any mapping below in its `CLAUDE.md` or `AGENTS.md` (its own calibration, models or efforts); its rules win.

## 1. Route by size

Before starting, pick the shortest route that fits and say it in one line. In doubt between two sizes, take the smaller one and move up when the work proves bigger.

| Size | When | Route |
| --- | --- | --- |
| **Small** | one or two tasks, a bug fix | the task written out in the prompt → `pas:implementer` (or `/pas:debug`) → the project's check; no `.temp/` topic, no review |
| **Medium** | up to about five tasks inside existing modules; no new public contract, project, layer or `S2` design | the main session writes `.temp/<topic>/tasks.md` per [task-template.md](task-template.md) → implementer batch → the full check → one `pas:reviewer` → `/pas:spec` only if specified behavior changed |
| **Large** | a new public contract, project or layer, work across layers, or more than about five tasks | `/pas:flow <goal>`: shape (if unclear) → proposal → `pas:decomposer` → implementer batches → the full check → two `pas:reviewer` in parallel → `pas:spec-writer` → `/pas:git`; state in `.temp/<topic>/flow.md` |

## 2. Task complexity score

Every task carries `**Model**: <tag> (D<n> V<n> S<n>)`, e.g. `**Model**: standard (D0 V1 S1)`. A task without a score counts as opus `high`; for an ad-hoc task the main session scores it before spawning the implementer.

| Axis | 0 | 1 | 2 |
| --- | --- | --- | --- |
| **D**ecisions left to the implementer | the task fixes the values, rules, names and paths | one local choice with named options, or a check-then-decide step | an algorithm, flow or contract must be invented |
| **V**erification: what catches a mistake | the compiler or the tests named in the task | tests catch the logic, but real behavior is confirmed only in the running system (fakes, mocks, UI, timing assumptions) | the mistake stays silent or shows up mainly in a manual check |
| **S**tate | one pass, nothing kept | state across calls or ticks, retries, cleanup on cancel, or a new meaning several layers must agree on | concurrency, a timing-sensitive state machine, native or unsafe code, an allocation-free protocol |

The lowest matching row gives the tag and the implementer's model and effort:

| Score | Tag | Implementer |
| --- | --- | --- |
| sum 0 | `standard` | sonnet, `medium` |
| sum 1–2 | `standard` | sonnet, `high` |
| sum 3 | `high` | opus, `medium` |
| sum 4+, any `D2` or `S2`, security, licensing, data-loss risk | `high` | opus, `high` |
| `D2` and `S2` together | `high` | opus, `xhigh` |

* **Not counted**: the area of the code and the number of files or lines. A complete task text lowers `D`, so a detailed task in an important area can be `standard`. In doubt, raise that one axis by 1 instead of tagging the whole task `high`.
* **Escalation**: when an implementer below opus `high` reports `blocked:`, or the project's check is red after its report, rerun the task once on opus `high` and change its tag to `high` in the task file. Red tests inside its own TDD cycle do not count.
* **User override**: an explicit instruction ("use opus", "use sonnet") beats the score.
* **Other roles** carry their model in their agent definition: `pas:scout` haiku `high`, `pas:decomposer`, `pas:architect` and `pas:reviewer` opus `high`, `pas:spec-writer` sonnet `high`.
* **Never used**: sonnet above `high` (opus costs less for the same result), opus `max`, haiku for writing code. A `pas:scout` answer of "no such code" or "this is safe" is checked before it is relied on.

## 3. Context budget

* **The conversation is disposable, the state is not**: everything the next stage needs lives in `.temp/<topic>/` (`flow.md`, task checkboxes, `proposal.md`). User decisions, why a task was cancelled, and the next step are written there as soon as they are made.
* **One stage per context**: a commit or a finished stage (proposal, breakdown, implementation batch, review) is the point to clear. A large run always clears after the breakdown; implementation starts from the task file.
* **About 300k tokens is the limit**: when the context reaches it, finish the current step and do not continue in this context.
* **Decide and say so** without waiting for the user, picking one:
  * **Clear** when the next work can resume from `.temp/<topic>/`: write any missing state there and append `Handoff: <next step>` as the last `Log` line of `flow.md` (the next session takes over without asking), give the user the one message to send next (e.g. `/pas:flow <topic>`), then clear the session (the host's clear-session tool if it has one, else ask the user to run `/clear`). Do not open a side session to move on; a new session is only for unrelated work.
  * **`/compact`** when the work continues and needs this conversation: only the user can run it, so recommend it in one line and stop.
