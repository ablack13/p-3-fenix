# Module auditor rules

Behavioral rules for the `module-auditor` subagent.

---

## Stub detection — strong indicators

A doc IS a stub if any of these are present:

- Placeholder text in angle brackets: `<2-4 sentences on...>`, `<facts>`, `<placeholder>`, `<ComponentName>`, `<purpose, behavior>`, `<one-line summary — fill in>`, `<TypeName>`, `<verbatim public API: signatures only>`.
- Frontmatter `documents:` is empty (`[]`) or points at a folder rather than specific files.
- Wing README has all sections present but each section is a single placeholder line.

If a doc is a stub, prioritize fill BEFORE checking staleness.

## Stub-fill content generation

For each stub, you generate real prose by reading actual source. Section by section:

### Overview section (2-4 sentences)

Name what the subsystem does in *this specific module*, with actual class names. Don't write generic descriptions like "DI for the practice module" — write "The PracticeModule registers Koin dependencies for the practice screen, including PracticeViewModel, PracticeDataStore, and PracticeOperator."

### Components section

List actual public types from source, with real signatures verbatim:

```kotlin
class PracticeModule : Module() {
    override fun loadModule(builder: KoinDefinitionBuilder)
}

interface PracticeDataStore {
    fun observeCards(): Flow<List<Card>>
    suspend fun submitAnswer(cardId: CardId, answer: Answer): Result<Unit>
}
```

Don't simplify. Don't paraphrase. Verbatim.

### Wiring section

Describe how components are connected based on actual code:
- For DI rooms: which classes are bound to which interfaces, in what scope, with what dependencies.
- For persistence rooms: how the DAO is constructed, when migrations run.
- For network rooms: how the HTTP client is initialized, what plugins are registered.

Don't speculate. If the wiring is non-obvious from a quick read, say "see `<file>:<line>` for full wiring."

### Gotchas section

Extract from:
- `// TODO`, `// FIXME`, `// HACK` comments.
- `@Deprecated` annotations.
- `// NOTE:` or `// IMPORTANT:` comments.
- Non-obvious patterns (e.g., a manual lifecycle handoff, an order-dependent registration).

If none found, write `(none currently identified)` rather than fabricating.

## Project-specific signal detection

Read `<module-path>/build.gradle.kts` to identify the actual stack. Don't assume defaults.

| Build dep contains | DI room uses |
|---|---|
| `koin-core`, `koin-android`, `koin-compose` | Koin terminology: Module, factoryOf, singleOf, scopes |
| `dagger-hilt-android`, `hilt-compiler` | Hilt terminology: @InstallIn, @Module, components |
| Neither | Manual constructor injection notes |

| Build dep contains | Persistence room uses |
|---|---|
| `sqldelight-*` | SQLDelight terminology: .sq files, generated DAOs, transactions |
| `androidx.room` | Room terminology: @Entity, @Dao, migrations |
| `realm-kotlin` | Realm terminology |
| `androidx.datastore` | DataStore terminology: Preferences, Proto |

| Build dep contains | UI room uses |
|---|---|
| `androidx.compose.*` | Compose terminology: @Composable, state hoisting, recomposition |
| `androidx.fragment` | Fragment terminology |
| Neither (older) | View / Activity terminology |

For ANY signal, verify by grepping source for actual usage. A `koin-core` declaration in build.gradle without any `Module` declarations in source means the dep was added but not used — note in proposal.

## Stale doc severity classification

For non-stub docs that have stale frontmatter:

- `rewrite` — major prose changes; large source refactor or behavior shift.
- `minor-update` — small additions or naming adjustments needed but core prose still applies.
- `xref-only` — prose unchanged but cross-references need adjustment.
- `restamp-only` — source touched but prose still accurate (formatting, internal refactor, test-only, comment updates).

When ambiguous, choose the more conservative (higher severity).

## Drawer suggestions

A class warrants a drawer when:

- It's a DI module/component declaration.
- It's a Database class (SQLDelight Database, Room Database, etc.).
- It's a public API entry point with stable contract.
- It's a large coordinator, state machine, or screen factory with non-obvious lifecycle.

Don't suggest drawers for every public class. Be selective. The proposal lists them as suggestions for the developer to approve.

## Pre-existing rot

Worth flagging if you encounter it. Don't go hunting; flag what you naturally notice while reading. Examples:
- Room mentions deprecated types.
- Drawer references a removed file.
- Frontmatter cites paths that no longer exist.

## Cross-wing impact

Audit one wing at a time. But when this wing's changes affect another wing's docs (e.g., changes to a public API consumed by other modules), note in `Index changes needed`.

## What NOT to do

- DO NOT edit any actual doc files. All proposed content goes into the proposal file. The orchestrator applies after approval.
- DO NOT fabricate source files in `documents:`. Only list verified paths.
- DO NOT default to common framework names without checking the build file. The Hilt-vs-Koin error came from this.
- DO NOT propose stub fills based on the stub itself — read the source.
- DO NOT skip the stub check. Stubs are the priority.
