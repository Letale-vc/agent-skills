# Structure mode

Judge the shape of the code, not its lines: modules, boundaries, dependency direction, file layout, extraction. Every decision is judged by what the next real changes will cost. Map per SKILL.md §2 first, then follow this file.

## Contents

1. Focus
2. Map additions
3. What to look for
4. Extraction
5. Simplicity rules
6. Report and handoff

## 1. Focus

Combine as the request needs; an extraction question often comes up inside an assessment.

* **Assess** (default for existing code): what is wrong with the structure and what to fix first.
* **Evolve**: the user names what comes next (a new kind of feature, a platform, a second app, plugins, more developers) → what to change now so it lands cheaply.
* **Design**: a new project or package with no code yet → structure, boundaries and contracts before code. One planned change inside existing code is `/pas:proposal`'s job instead.
* **Extract**: should X be a separate module, package, library or service (§4).

## 2. Map additions

1. **Earlier roadmaps**: an open `.temp/arch-*/tasks.md` is a roadmap in progress: read its header and open tasks and build on it rather than starting a competing one.
2. **Units**: deployables (apps, services, CLIs, plugins, jobs), packages or projects, top-level folders or namespaces, one line each on its job.
3. **Dependency graph** from manifests, project references and imports, backed by the project's read-only tools where they exist (`dotnet list reference`, `npm ls`, `cargo tree`, `go list -deps`). Note direction, cycles and what everything depends on.
4. **Core vs. edges**: where the domain rules live and where I/O lives (UI, DB, network, filesystem, framework, OS, external SDKs); the composition root, where objects are created and wired.
5. **Real axes of change**: hotspots and change coupling from history, e.g. `git log --since="1 year ago" --name-only --format=` for the most-changed files and the folders that change in the same commits; existing variants such as type switches, if-chains and near-copy handlers per kind.
6. **Next changes**: what the user said is coming. Unknown, and the answer would change the recommendation → a design gate: ask one question with your best guess (a subagent infers from history and states the assumption). Turn it into 2–3 concrete **change scenarios** ("add a second payment provider", "ship a CLI next to the GUI"); every finding and recommendation is tested against them.
7. **Size**: script, single app, multi-app product, several teams; size the architecture to it.

## 3. What to look for

Dependencies point the right way → boundaries hold → a change stays local → the structure is findable → seams exist where change is proven → nothing is built for a future without evidence.

1. **Direction and cycles**: core or domain importing UI, DB, framework or SDK types; cycles between modules or packages; a `common` / `shared` / `utils` grab-bag that everything imports and that imports back.
2. **Boundaries**: a module reaching into another's internals (private files, internal types, another module's tables); the same rule implemented in several modules; one module owning unrelated jobs; boundaries that cut across how code changes (one feature always touches five folders).
3. **Contracts**: a public surface wider than its users need, third-party types leaking through a public API, persistence or transport models used as the domain everywhere, a contract with outside consumers and no versioning.
4. **Findability**: folders by technical layer (`controllers/`, `services/`, `models/`) while features change as units, or the reverse when a layer is the real unit; the same kind of thing in two places; misplaced files; tests that do not mirror the source; wiring scattered instead of one composition root; global mutable state that blocks a second consumer or a test.
5. **Missing seam**: where scenarios, history or ≥ 2 existing variants prove new variants will come → one seam there (registry, strategy, plugin contract, adapter around the external system).
6. **Speculative structure** (a cost, not a virtue): an interface with one implementation and no planned second, a factory with one product, layers that only forward, a plugin system with one plugin, a package nobody else consumes, services split for one team's one app → collapse it.

## 4. Extraction

Recommend extracting X only when most of these hold, and name the ones that do not:

* **Consumers**: ≥ 2 real consumers now (or one confirmed next), or a different owner, release cadence, license, platform or runtime.
* **Stable, narrow API**: few entry points; in history X rarely changes in the same commit as its callers.
* **Clean direction**: X depends only downward: no imports back into the app, no app config, globals or DI container.
* **Testable alone**: its tests run without the rest of the app.

Pick the **lowest level that solves the problem**; each level up adds release, versioning and breaking-change cost:

1. Folder or namespace with one public entry (facade, `index`, internal visibility for the rest): the default while boundaries are fuzzy.
2. Separate project or package in the same repo: the compiler enforces the boundary, no versioning yet.
3. Published package: semantic versioning, changelog, CI, a deprecation policy.
4. Separate repo: only for a different owner or lifecycle.
5. Separate service: only for independent deploy, scaling, failure isolation or a team boundary; a network call replaces a function call.

Anti-signals → keep X internal behind a clean boundary (cheap to extract later): it changes with the app in most commits, its API is still in flux, or the only other consumer is "maybe someday". Before calling a module unused, search the whole tree as in SKILL.md §4.

For each recommended extraction give: name, level, public API, what moves and what stays, dependency direction, and how callers switch (Expand-Contract: move + re-export or shim → switch callers → remove the shim).

## 5. Simplicity rules

* Extensibility comes first from **boundaries and dependency direction**: cheap and always worth it. Abstractions (interfaces, plugins, events) are paid upfront: add them only on an axis of change proven by a scenario, history or ≥ 2 existing variants.
* Fit the ceremony to the size: no layered "clean architecture" for a 2,000-line tool, no single tangled project for a product with three deployables.
* Prefer move, merge and delete over add. Never a rewrite: only incremental steps that each leave the project building with green tests.
* Every finding and step names the **change scenario** it makes cheaper or the failure it prevents.

## 6. Report and handoff

1. **What this system is:** two or three sentences, plus the size and the change scenarios you assumed.
2. **Current map:** a small text diagram of units and dependency arrows; mark cycles and wrong-direction arrows.
3. **Findings** (Assess, Evolve) in the SKILL.md §5 groups and four-part format, numbered across groups, at most 15. Must fix here means: blocks a named scenario, a cycle, core depending on I/O, a boundary violation that already duplicates rules.
4. **Extraction candidates** (when any): candidate → level → why → what must be true first.
5. **Target structure:** a tree of only the parts that change; the dependency rules one per line (`Domain → nothing`, `Infrastructure → Domain`, `App → all`); how they are enforced: project or package references where possible, else the project's existing lint or architecture-test tool (a new tool is a new dependency: gate 2).
6. **Roadmap:** ordered steps, cycle-breaking and unblocking steps first. Each names the findings it closes, size (S/M/L), risk, how it is verified (build, tests, a dependency check) and its route: `tasks` when this report settles the design (what moves, the public API, how callers switch), `/pas:proposal` when a decision stays open or a contract with outside consumers changes.
7. **Verdict:** one line, sound or what to change first; **Not checked:** what you skipped and why.

**Design** focus: replace Current map and Findings with **Options**: 2–3 structures with trade-offs, recommended first, only where a real choice exists; then Target structure, the contracts between modules and the first roadmap steps.

Nothing to change: **What this system is:**, the map, then `Architecture fits the scenarios. Nothing to change.` and one line on what you checked. Ask only if an assumption (a change scenario, a second consumer) would flip the verdict, and then about that assumption alone.

**Closing question** (gate 3), recommended answer first: hand **all** roadmap steps 1–N to `/pas:decompose` into `.temp/arch-<area>/tasks.md`, `/pas:proposal` steps included: they become `**Design**` tasks that wait for their decision, while a step left out of the file is lost when the chat ends. Alternatives: name the step or finding numbers, or take one step straight to `/pas:proposal`.
