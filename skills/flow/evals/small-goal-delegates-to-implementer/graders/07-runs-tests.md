---
type: llm
focus: trace
weight: 1
---

The project's tests (python -m unittest) run green after the change: the implementer's report shows the passing run, and the main session reads that reported output instead of running the same tests again on unchanged files. The main session runs the tests itself only if the report shows no green run.
