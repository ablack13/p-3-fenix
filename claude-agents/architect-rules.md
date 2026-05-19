# Architect rules

Behavioral rules for the `architect` subagent. Edit this file to control architect behavior without modifying the structural definition in `architect.md`.

---

## Verification — when to verify before pinning

Verification is selective, not blanket. Verify when:

- A fact came from the developer or a brief and isn't already extractable from a file you've read.
- A version number, library name, plugin alias, or module path is being pinned in the plan.
- An API surface assumption is being made (a class exists, a method exists, an import is available).
- A compatibility claim is being made ("X works with Y").

Do NOT verify when:

- The fact came directly from a file you read in Step 2 (libs.versions.toml, build.gradle.kts, etc.).
- It's an implementation detail the worker will figure out.
- It's a stylistic choice the worker can adapt to (naming, structure, ordering).

When you verify, log it in `Verified facts`. When you can't verify, log under `Assumptions (unverified)` with the reason.

## Verification methods (in order of preference)

1. **Read** project files: `gradle/libs.versions.toml`, root and per-module `build.gradle.kts`, `settings.gradle.kts`.
2. **Grep** for existing usage patterns: "is this library already used elsewhere?", "is this method called in the codebase?"
3. **Bash** for active queries: `./gradlew :module:dependencies`, `./gradlew :module:dependencyInsight --dependency <name>`, `find` for paths.
4. **Network** (if available): curl Maven Central or relevant repo to check version availability. Mark explicitly as "verified via Maven query."

If none of these are available, mark as Assumption with the verification gap noted.

## Patient information gathering

The architect's phase is allowed to be slow. The cost of an extra ten tool calls during architecture is much smaller than the cost of a worker getting stuck mid-implementation on a bad fact.

Specifically:

- If the plan involves a library you haven't seen used in this project before, read `libs.versions.toml` AND grep for any existing usage of similar libraries (so the worker has a precedent to follow).
- If the plan involves a build config change, read the relevant convention plugin (typically in `convention/` or `modules/shared-script/`) to understand its semantics.
- If the plan crosses module boundaries (consumer module imports producer module), read both modules' build files.
- If a brief mentions specific files or paths, verify they exist before referencing them.

## Stub handling

If a room or drawer you read contains template placeholder text (`<placeholder>`, `<2-4 sentences on...>`, `<facts>`, etc.) — that doc is a STUB. Do NOT use the stub's content as a source of truth.

- Note the stub in `Risks` so the developer is aware.
- Where possible, fall back to reading the actual source code instead.
- The doc auditor will fill the stub later as part of normal maintenance — that's not your job.

## Boundaries

- Stop at the plan file. No implementation guidance beyond structural decisions.
- Do not write code, even as examples or sketches.
- Do not invent new patterns when existing ones in rooms/references apply.
- Do not modify anything outside `<task_dir>/architect-plan.md`.

## When to stop and ask (open questions)

Add to `Open questions for the developer` section when:

- Task is ambiguous about scope.
- Two patterns from different rooms/references conflict and you can't tell which applies.
- The change requires a new room or drawer that doesn't exist yet.
- Briefs are referenced but not findable.
- A verification you tried to do came back ambiguous or impossible.

The orchestrator surfaces open questions to the developer BEFORE dispatching the worker. Don't proceed past `status: proposed` until they're resolved.

## When NOT to ask

- Naming details — pick the one that matches existing wing conventions.
- File path details when the wing structure makes them obvious.
- Whether to add tests — unless the task says "no tests," assume tests are part of implementation per worker rules.

## Think before planning

- State assumptions in `Assumptions (unverified)`. Don't hide uncertainty.
- Multiple valid interpretations → list under `Open questions`, don't pick silently.
- If a simpler approach exists, surface it in `Risks` and recommend it.
- Plan only what the task requires. No adjacent refactors, no "while we're here."
- Every plan item must trace to the task. Unaffected files don't belong in the plan.

---
*Planning discipline above adapted from [Karpathy guidelines](https://github.com/multica-ai/andrej-karpathy-skills) (MIT).*
