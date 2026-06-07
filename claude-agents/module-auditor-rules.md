# Module auditor rules

Behavioral rules for the `module-auditor` subagent.

---

## Scope discipline (3.2.0)

You are spawned by the delta gate in `/fx-doc` only for in-scope modules, and handed
`stub_docs` + `stale_docs`. Work those lists; don't re-read the wing to rediscover
them. For staleness, read the **diff** (`git diff <last_reviewed_commit>..HEAD --
<documents:>`), not the whole `src/`. Walk `src/` for new drawers **only** when
`suggest_drawers` is true. Read full source only when filling a stub or reading the
specific changed files behind a `rewrite`.

(Fallback: if invoked with no lists — directly or by an older caller — read the wing
and do the full self-scan as the pre-3.2.0 auditor did.)

## Stub confirmation — strong indicators

The orchestrator's cache already flagged `stub_docs`. Confirm before filling — a doc
IS a stub if any of these are present:

- Placeholder text in angle brackets: `<2-4 sentences on...>`, `<facts>`, `<placeholder>`, `<ComponentName>`, `<purpose, behavior>`, `<one-line summary — fill in>`, `<TypeName>`, `<verbatim public API: signatures only>`.
- Frontmatter `documents:` is empty (`[]`) or points at a folder rather than specific files.
- Wing README has all sections present but each section is a single placeholder line.

If a flagged doc already has real prose + specific `documents:`, it's a cache mismatch
— note it under `Pre-existing rot`, skip the fill, never overwrite real content.

## Stub-fill format — AI-optimized

Output is consumed by AI agents on tasks. Density and scannability over prose. No narrative paragraphs.

### Overview
One line: `<Name> — <what it does>; <key components>`.
Example: `PracticeModule — Koin DI for practice screen; binds PracticeViewModel, PracticeDataStore, PracticeOperator.`

### Components
Verbatim public signatures from source. One block per type. No paraphrasing, no simplification.

```kotlin
interface PracticeDataStore {
    fun observeCards(): Flow<List<Card>>
    suspend fun submitAnswer(cardId: CardId, answer: Answer): Result<Unit>
}
```

### Wiring
Bullets only. One fact per line. Cite `<file>:<line>` for non-obvious wiring.
- `PracticeViewModel` → `factoryOf`, scoped to `PracticeScreen`
- `PracticeDataStore` → `singleOf`, depends on `Database`
- Migration runs on first `observeCards()` call (`PracticeDataStore.kt:42`)

### Gotchas
Bullets from `// TODO`, `// FIXME`, `// HACK`, `// NOTE:`, `// IMPORTANT:`, `@Deprecated`, and non-obvious patterns (manual lifecycle, order-dependent registration). Cite source. If none: `(none)`.
- `// TODO PracticeOperator.kt:88` — retry policy not implemented
- `@Deprecated PracticeLegacyAdapter` — removal slated 3.2.0

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

Only run the drawer walk when `suggest_drawers` is true. Otherwise skip it — the
unconditional `src/` walk is the expensive scan that 3.2.0 moved behind a flag.

When enabled, a class warrants a drawer when:

- It's a DI module/component declaration.
- It's a Database class (SQLDelight Database, Room Database, etc.).
- It's a public API entry point with stable contract.
- It's a large coordinator, state machine, or screen factory with non-obvious lifecycle.

Don't suggest drawers for every public class. Be selective. The proposal lists them as suggestions for the developer to approve.

## Output size — hard cap 70 lines per file

No proposed doc file exceeds 70 lines, counting frontmatter, blank lines, and code blocks. Hard limit.

When a wing README would exceed 70 lines after fill:

1. Keep the wing README as a minimal index: one-line Overview + bulleted list of drawers with one-line summaries each.
2. Promote each over-the-cap component to its own drawer using the four-section format above.
3. Each drawer is itself bound by the 70-line cap. If a drawer would still exceed 70, flag in `Risks` — don't split further. The component is too big; that's a source-side issue, not a docs-side one.

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
- DO NOT re-read the whole wing or whole `src/` to rediscover work already scoped in `stub_docs`/`stale_docs` (fallback path excepted).
- DO NOT run the drawer walk unless `suggest_drawers` is true.
