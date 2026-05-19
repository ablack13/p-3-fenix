# Worker rules

Behavioral rules for the `worker` subagent.

---

## Execution discipline

- Execute the architect's plan precisely. If something is unclear, stop and ask.
- File ordering: create new files before modifying references to them.
- Match existing wing patterns for style, naming, and structure. Read the rooms the plan cited.
- Use named arguments in function calls when the project's existing code does.
- Match existing import ordering conventions in each file you touch.

## Status tracking — real time

The worker-log.md file is the live record. Update after each plan item, not at the end.

- Before starting an item: set Status to `in-progress`, fill `Started`.
- On completion: set Status to `done`, fill `Completed`, add to `Files actually touched`.
- On blocker: set Status to `blocked`, log in `Blockers encountered`, STOP.
- On deviation: log in `Deviations from plan` with reason.

Updates happen via Edit on worker-log.md. Don't batch them.

## Scope discipline

- Do not refactor unrelated code, even if you notice it's bad.
- Do not bump versions, dependencies, or build configuration unless the plan specified.
- Do not reformat lines you didn't otherwise need to touch.
- Do not add tests unless the plan asked for them.
- Do not add documentation comments unless the plan asked for them.

## Tests

- If the plan says "with tests," add tests in the project's existing test pattern (read a similar wing's tests for the pattern).
- If the plan doesn't mention tests, don't add them.
- If the plan mentions tests but you can't run them in this environment, write the tests anyway — the developer will run them.

## Doc-system boundaries (hard rules)

- Never edit files under `docs/`, `<module>/docs/`, or `reference/`.
- Never edit `CLAUDE.md`, `hint_index_map.md`, `task-router.md`, `info.md`, or `STYLE.md`.
- Never edit other tasks' folders. Only `<task_dir>/worker-log.md`.
- Documentation updates happen exclusively in `/fx-doc update`. The worker does not pre-empt that.

## When to stop and ask

- Plan item references a file that doesn't exist.
- Plan item conflicts with current code state (already implemented, contradictory).
- Ambiguity the plan didn't resolve, can't be answered from rooms/references.
- A test fails in a way suggesting the plan itself was wrong.

Set Status to `blocked`, log the blocker, write a brief note about what you tried, return. The orchestrator and developer take it from there.

## Simplicity

- Minimum code that satisfies the plan item. Nothing speculative.
- No abstractions for single-use code. No configurability the plan didn't ask for.
- No error handling for impossible scenarios.
- If it grew to 200 lines and could be 50, rewrite before marking done.
- Self-check: "would a senior engineer call this overcomplicated?" If yes, simplify.
- Does not override the plan. If the plan asks for complexity, implement it and raise it under `Deviations from plan`.

---
*Simplicity rules above adapted from [Karpathy guidelines](https://github.com/multica-ai/andrej-karpathy-skills) (MIT).*
