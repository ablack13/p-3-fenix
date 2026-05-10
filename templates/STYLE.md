# Documentation style — P-3 (Fenix) v3.0.0

Conventions for this repo's documentation. Runbook reads this file. So does any contributor opening a doc PR.

## Topology — wings/rooms/drawers, decentralized

```
<module>/docs/                ← per-module wing
├── README.md                 ← wing root
├── rooms/                    ← subsystem docs
│   ├── di.md
│   ├── persistence.md
│   ├── network.md
│   ├── ui-android.md
│   └── ui-ios.md
└── drawers/                  ← single-concern leaves
    └── <ClassName>.md

docs/                         ← thin shell at repo root
├── hint_index_map.md         ← wayfinding, source of truth
├── info.md                   ← user-owned setup notes
└── STYLE.md                  ← this file
```

- **Wing** = one module's docs.
- **Room** = subsystem inside a module (di, persistence, network, ui-android, ui-ios, public-api).
- **Drawer** = one class, one config, one migration. Single concern, loadable standalone.

Cross-wing references go in `hint_index_map.md`, not inline in wing READMEs.

## When does a module get docs?

Any module with public surface (anything other modules import) MUST have at least `docs/README.md`. Internal-only utility modules can skip docs entirely.

## Style — plain prose

| Surface | Style |
|---|---|
| Descriptions, "why" sections | Plain prose, terse |
| Section headers | Greppable English |
| Code blocks | Verbatim |
| Type signatures, error messages | Verbatim |
| Gradle / Koin / SQLDelight / Ktor config | Verbatim |
| Cross-ref links | Standard markdown |

Rules:

- Short sentences. State fact. Stop.
- No marketing tone. No hedging ("might", "could potentially").
- No emojis.
- Technical terms exact: `PracticeModule` stays `PracticeModule`.
- Code, types, errors: never paraphrase.

## Frontmatter on rooms and drawers

Every room and drawer must have YAML frontmatter:

```yaml
---
documents:
  - <repo-relative source path>
  - <another source path if applicable>
last_reviewed_commit: <short SHA>
last_reviewed_date: <YYYY-MM-DD>
---
```

`documents:` lists the source files this doc covers. Used by the freshness check.

## Freshness rule

When a listed source file changes, the doc must be either:

1. **Updated** (prose changed to reflect the new behavior), then re-stamped, OR
2. **Re-stamped only** (`last_reviewed_commit` bumped to current HEAD) — explicit signal that "I read the diff, prose is still accurate."

Leaving an old hash on a doc whose source has moved is staleness and gets flagged.

**Re-stamp authority:** anyone touching the module can re-stamp.

## Drawer creation policy

Drawers grow organically, not in bulk. Create one when:

- A class has non-obvious lifecycle, wiring, or gotchas worth documenting separately.
- A class is referenced from multiple wings (its docs become a coordination point).
- A migration, schema, or config is complex enough to warrant its own page.

Don't create a drawer for every public class. Most belong in their room.

## Cross-wing references

Always go through `hint_index_map.md`. Inline cross-wing links in a wing README couples wings to each other; the index keeps that coupling explicit.

In rooms and drawers, cross-references to other modules use the absolute-from-root path:

```markdown
See [core's DI room](/<module-path>/core/docs/rooms/di.md).
```

## File templates

See the runbook for canonical templates. Each file type (wing README, room, drawer, hint_index_map entry) has a fixed shape.
