# /fx-info — Status check

Read-only. Don't trigger an audit. Don't load full docs. Cheap status output.

## Steps

1. Check existence of:
   - `CLAUDE.md` at repo root
   - `_claude_backup/` at repo root (pre-install backup, restored on uninstall)
   - `docs/`, `docs/hint_index_map.md`, `docs/info.md`, `docs/STYLE.md`, `docs/task-router.md`
   - `reference/`
   - `tasks/`
   - `.fenix-manifest.json`

2. If `docs/info.md` exists, extract the first blockquote after the H1 title — that's the summary.

3. Check `CLAUDE.md` for unfilled placeholders (lines containing `<!-- Filled in by /fx-init` or empty `## Stack` section).

4. Count `### ` category headers in `docs/task-router.md`.

5. Count modules from `settings.gradle.kts`. Count how many have `<module>/docs/README.md`.

6. **Stub detection (lightweight).** Walk `<module>/docs/rooms/*.md` and `<module>/docs/drawers/*.md`. Count files containing common stub markers (`<2-4 sentences on...>`, `<facts>`, `<ComponentName>`, `<purpose, behavior>`). Don't read full content; just grep.

7. Walk `tasks/`. Count: open tasks (status:open or status:in-progress), closed tasks, blocked tasks.

8. Find latest file in `docs/_history/` for "Last audit" date.

9. If `.fenix-manifest.json` exists, count entries by action type.

## Output — fully initialized repo

```
P-3 (Fenix) v3.1.0

<summary line from docs/info.md>

Topology:    wings/rooms/drawers decentralized (per-module docs/)
Freshness:   enabled
CLAUDE.md:   populated
Index:       docs/hint_index_map.md
Setup notes: docs/info.md
Style guide: docs/STYLE.md
Disclaimer:  docs/DISCLAIMER.md (bootstrap messages, editable)
Task router: docs/task-router.md (N categories)
Audit log:   docs/_history/

Modules:     N total, M documented (M/N)
Stubs:       K rooms/drawers still contain template placeholders
             Run /fx-doc update to have the auditor fill them.

Tasks:       J open, L closed, X blocked (in tasks/)
Last audit:  <YYYY-MM-DD> | (none yet)

Backup:      _claude_backup/ present (pre-install CLAUDE.md/.claude — restored on /fx-uninstall)
Manifest:    .fenix-manifest.json (N actions recorded)
```

## Output — uninitialized repo

```
P-3 (Fenix) v3.1.0

⚠ Repo not initialized. Run /fx-init to bootstrap wings/rooms/drawers structure.

Detected:
  CLAUDE.md             missing
  docs/                 missing
  hint_index_map.md     missing
  info.md               missing
  task-router.md        missing
  reference/            missing
  tasks/                missing
  Manifest              missing
  Per-module docs       0 / N modules
```

## Output — partially initialized

```
P-3 (Fenix) v3.1.0

⚠ Partial setup. Run /fx-init to fill gaps.

Detected:
  CLAUDE.md             ✓ (placeholders pending)
  docs/                 ✓
  hint_index_map.md     ✓
  info.md               missing
  task-router.md        missing
  reference/            ✓
  tasks/                missing
  Manifest              missing
  Per-module docs       12 / 18 modules
  Stubs:                12 rooms/drawers still contain template placeholders
```

## Stub line — display rules

If stub count > 0, always include the line "Stubs: K rooms/drawers still contain template placeholders" with a hint to run `/fx-doc update`. This makes the unfilled stubs visible — the developer sees there's work to fill them.

If stub count is 0, the line says "Stubs: none — all docs have real content."

## Constraints

- Read-only. Don't trigger anything.
- Existence checks + grep only. Don't read full doc contents.
- Maximum ~10 file reads + a few greps total. Stay cheap.
