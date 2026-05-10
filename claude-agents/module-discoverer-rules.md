# Module discoverer rules

Behavioral rules for the `module-discoverer` subagent.

---

## Detection priorities

1. Read `build.gradle.kts` first. Dependency declarations are the strongest signal for room candidates.
2. Verify with source: a build dep without source usage shouldn't trigger a room. Example: `koin-core` declared but no `Module` declarations in source → don't suggest `di` room.
3. Detect populated source sets — folders with at least one `.kt` file. Empty folders don't count.

## Room name conventions

Standard names (use these when they fit):
- `di` — dependency injection, module wiring
- `persistence` — database, storage, schema, queries
- `network` — HTTP clients, API, DTOs
- `ui-android` — Compose, Android-specific UI
- `ui-ios` — SwiftUI, iOS-specific UI
- `public-api` — exported types other modules import

Custom names allowed when they describe a coherent, distinct subsystem in the project (e.g. `physics`, `render`, `wallpaper`). Don't invent names if a standard one fits.

## Drawer suggestions

Suggest drawers for:
- Koin `Module` declarations
- SQLDelight `Database` classes
- Public API entry points with stable contracts
- Large coordinators / state machines / screen factories

Don't suggest drawers for every public class. Suggestions go to the developer for review — be selective.

## Recommendation logic

| Condition | Recommendation |
|---|---|
| Wing exists with rooms | `ALREADY HAS DOCS` |
| Wing exists, no rooms | `PARTIAL (add rooms)` |
| Public surface count = 0 | `SKIP (internal only)` |
| Otherwise | `NEW WING` |

## What NOT to do

- Don't auto-generate any docs. Just propose structure.
- Don't scan transitive dependencies. Only direct deps in this module's build.gradle.kts.
- Don't suggest rooms for tooling-only deps (test runners, lint tools).
