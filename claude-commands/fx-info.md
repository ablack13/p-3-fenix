# /fx-info — Status check

Read-only. Don't trigger anything. Cheap status output.

## Steps

1. Check existence of:
   - `CLAUDE.md` at repo root
   - `_claude_backup/` at repo root (pre-install backup, restored on uninstall)
   - `docs/`, `docs/info.md`, `docs/DISCLAIMER.md`
   - `.claude/rules/git-workflow.md`, `.claude/rules/fenix-conventions.md`
   - `tasks/`
   - `.fenix-manifest.json`

2. Check the repo map in `CLAUDE.md`: locate `FENIX:MAP:START`/`END` markers. Count non-comment content lines between them. Empty → map not generated yet. Count `### Modules` entries if present.

3. If `docs/info.md` exists, extract the first blockquote after the H1 title — that's the summary.

4. Check `CLAUDE.md` for unfilled placeholders (lines containing `<!-- Filled in by /fx-init` or empty `## Stack` section).

5. Count `.claude/rules/*.md` files: always-on (no `paths:` in frontmatter) vs path-scoped.

6. Count modules from `settings.gradle.kts` (or equivalent manifest).

7. Walk `tasks/`. Count: open tasks (status:open or status:in-progress), closed tasks, blocked tasks.

8. If `.fenix-manifest.json` exists, count entries by action type and read `fenix_version`.

## Output — fully initialized repo

```
P-3 (Fenix) v4.0.0

<summary line from docs/info.md>

Context:     repo map in CLAUDE.md (code is the source of truth — no per-module docs)
Repo map:    <N> modules mapped, <M> map lines
Rules:       <A> always-on, <S> path-scoped (.claude/rules/)
CLAUDE.md:   populated
Setup notes: docs/info.md
Disclaimer:  docs/DISCLAIMER.md (bootstrap messages, editable)

Modules:     <N> in project manifest
Tasks:       <J> open, <L> closed, <X> blocked (in tasks/)

Backup:      _claude_backup/ present (pre-install CLAUDE.md/.claude — restored on /fx-uninstall)
Manifest:    .fenix-manifest.json (v<fenix_version>, <N> actions recorded)
```

## Output — uninitialized repo

```
P-3 (Fenix) v4.0.0

⚠ Repo not initialized. Run /fx-init to generate the repo map and scaffold rules.

Detected:
  CLAUDE.md             missing
  Repo map              missing
  .claude/rules/        missing
  info.md               missing
  tasks/                missing
  Manifest              missing
```

## Output — partially initialized

```
P-3 (Fenix) v4.0.0

⚠ Partial setup. Run /fx-init to fill gaps.

Detected:
  CLAUDE.md             ✓ (placeholders pending)
  Repo map              markers present, EMPTY — run /fx-init
  .claude/rules/        ✓ (git-workflow.md, fenix-conventions.md; 0 path-scoped)
  info.md               missing
  tasks/                ✓
  Manifest              ✓
```

## Map line — display rules

If the map markers exist but hold no content, always include "Repo map: EMPTY — run /fx-init". If markers are missing entirely (pre-4.0.0 CLAUDE.md), say "Repo map: markers missing — run /fx-init to append the map section".

## Constraints

- Read-only. Don't trigger anything.
- Existence checks + grep only. Don't read full doc contents.
- Maximum ~10 file reads + a few greps total. Stay cheap.
