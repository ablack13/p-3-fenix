# P-3 (Fenix) v3.2.0 — Wings/Rooms/Drawers Documentation + Dev Team Kit

Drop-in starter kit for any multi-module project. Wings/rooms/drawers decentralized docs, task routing, dev-team workflow, cross-cutting reference layer.

## Contents

```
p3-fenix-3.2.0/
├── README.md                    ← this file
├── runbook.md                   ← main runbook (full operational details)
├── LICENSE
├── P-3 (Fenix)- READ BEFORE FIRST.md  ← full reference for commands/agents/workflows
├── scripts/
│   ├── setup.sh                 ← installer (manifest-driven, idempotent)
│   ├── install-online.sh        ← one-command online installer
│   └── upgrades/                ← pairwise <from>-to-<to>.json upgrade configs
├── claude-commands/
│   ├── fx-init.md               ← /fx-init
│   ├── fx-info.md               ← /fx-info
│   ├── fx-doc.md                ← /fx-doc audit | update | freshness
│   ├── fx-task.md               ← /fx-task <description> | new <description>
│   ├── fx-agent.md              ← /fx-agent rules | list
│   └── fx-uninstall.md          ← /fx-uninstall (manifest-driven removal)
├── claude-agents/
│   ├── architect.md             ← designs implementation plans (read-only on code)
│   ├── architect-rules.md       ← architect behavioral rules
│   ├── worker.md                ← executes plans (only writer of project code)
│   ├── worker-rules.md          ← worker behavioral rules
│   ├── tester.md                ← reviews worker output (read-only on code)
│   ├── tester-rules.md          ← tester behavioral rules
│   ├── module-auditor.md        ← per-module stub-fill + staleness (used by /fx-doc)
│   ├── module-auditor-rules.md  ← auditor behavioral rules
│   ├── module-discoverer.md     ← per-module structure proposal (used by /fx-init)
│   ├── module-discoverer-rules.md ← discoverer behavioral rules
│   ├── freshness-scanner.md     ← frontmatter staleness check
│   ├── freshness-scanner-rules.md ← scanner behavioral rules
│   ├── reference-linker.md      ← auto-links new reference/ files
│   ├── reference-linker-rules.md ← linker behavioral rules
│   └── _topology.md             ← shared vocabulary reference (not auto-loaded)
└── templates/
    ├── CLAUDE.md                ← repo-root file with bootstrap + routing rule
    ├── DISCLAIMER.md            ← docs/DISCLAIMER.md (editable bootstrap ritual)
    ├── info.md                  ← docs/info.md template
    ├── STYLE.md                 ← docs/STYLE.md (conventions)
    ├── hint_index_map.md        ← docs/hint_index_map.md (with Reference docs section)
    ├── task-router.md           ← docs/task-router.md stub
    ├── wing-README.md           ← per-module wing template
    ├── room.md                  ← room template
    ├── drawer.md                ← drawer template
    ├── reference.md             ← reference doc template (with extended frontmatter)
    └── task.md, architect-plan.md, worker-log.md, tester-review.md, outcome.md, doc-audit.md
                                  ← dev-workflow artifact templates
```

## What's new in v3.2.0

- **Delta-gated audits** — `/fx-doc audit` / `update` now spawn a `module-auditor` only for modules whose documented sources actually changed, or that still hold unfilled stubs. Unchanged modules are settled from a cheap cache with no subagent. On a stabilized codebase this turns "N auditors every run" into "0–2 per PR."
- **`docs-meta/.fenix-cache.json`** — a derived index of every doc's frontmatter (`documents:`, `last_reviewed_commit`, `is_stub`). The orchestrator decides who to audit from one cheap per-doc `git log` pass (each doc against its own `last_reviewed_commit`) instead of reading wings. Re-sync any time with `/fx-doc audit --rebuild-cache`.
- **Diff-scoped staleness** — when a doc is stale, the auditor reads `git diff <last_reviewed_commit>..HEAD -- <documents:>` instead of re-reading the whole module.
- **Cheaper defaults** — `/fx-doc freshness` is the routine, code-free "what's stale" check; `/fx-doc update --only <module>` is the targeted expensive path; `--all` forces a full re-audit; `--suggest-drawers` gates the unconditional `src/` walk.
- **Reliable manifest writes** — `setup.sh`'s manifest append passes values through the environment (no fragile string interpolation) and fails loudly instead of swallowing errors, so `/fx-uninstall` never skips files it should have recorded.

## What's new in v3.1.0

- **Karpathy-aligned agent rules** — architect surfaces assumptions and resists scope creep, worker resists overcomplication, tester demands verifiable success criteria. Adapted from the [Karpathy guidelines skill](https://github.com/multica-ai/andrej-karpathy-skills) (MIT).
- **AI-optimized doc output** — `module-auditor` emits bullets + verbatim signatures instead of prose. Faster for agents to scan; smaller token footprint.
- **70-line cap on doc files** — wing READMEs, rooms, and drawers each capped at 70 lines. Oversize wings split into thin indexes + per-component drawers.
- **`/clear` nudge on task close** — `/fx-task new` ends with a prompt to clear context, so finished tasks don't bleed tokens into the next conversation.
- **Reshaped templates** — `wing-README.md`, `room.md`, `drawer.md`, and `STYLE.md` updated to match the AI-optimized format.

## What's new in v3.0.0

- **All commands prefixed with `fenix-`** — no collision with built-ins, consistent namespace.
- **Dev-team agents** — `architect`, `worker`, `tester` for the architect → worker → tester workflow via `/fx-task new`.
- **Per-agent rules files** — every agent has a `<name>-rules.md` sibling for editable behavior. Run `/fx-agent rules` to see them.
- **Reference docs layer** — `reference/` folder for cross-cutting docs (architecture, decisions, conventions). Auto-linked into the index and router on `/fx-doc update` via the `reference-linker` subagent.
- **Extended frontmatter** — reference files carry `applies_to_categories:` and `applies_to_wings:` to bind them to the task router.

## Install

> **Run from the root directory of your project** — the same directory where you launch Claude Code (`claude`). The installer writes into `$(pwd)`.

### One-command install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ablack13/p-3-fenix/main/scripts/install-online.sh | bash
```

This downloads the latest release zip into a temp dir, extracts it, runs the installer against your repo root, and cleans up after itself.

Pin a specific version:

```bash
FENIX_VERSION=3.2.0 bash -c "$(curl -fsSL https://raw.githubusercontent.com/ablack13/p-3-fenix/main/scripts/install-online.sh)"
```

Want to inspect the installer before running? Read it at <https://github.com/ablack13/p-3-fenix/blob/main/scripts/install-online.sh>.

### Manual install (download → unzip → run)

```bash
curl -LO https://github.com/ablack13/p-3-fenix/releases/download/3.2.0/p3-fenix-3.2.0.zip
unzip p3-fenix-3.2.0.zip
./p3-fenix-3.2.0/scripts/setup.sh
rm -rf p3-fenix-3.2.0 p3-fenix-3.2.0.zip
```

### After install

Open Claude Code in this project and run:

```
/fx-init
```

It scaffolds wings, drafts `info.md`, populates `CLAUDE.md` placeholders, generates `task-router.md`, and creates `reference/`.

### What the installer does

- Copies the kit into `.claude/`, `docs/`, `docs-meta/`, `reference/`, `tasks/` and writes a fresh `CLAUDE.md`.
- If your project already has a `CLAUDE.md` or `.claude/` folder, it moves them aside into `_claude_backup/` (with an `IGNORE_THIS_FOLDER.md` disclaimer so Claude leaves the backup alone).
- Records every action in `.fenix-manifest.json` so `/fx-uninstall` can reverse the install cleanly.

### Upgrading an existing install

Two ways:

**From inside Claude Code (recommended for 3.1.0+):**

```
/fx-init upgrade
```

Reads `.fenix-manifest.json`, queries GitHub for the latest release, shows a plan, and runs the installer on approval. Pin a target version with `/fx-init upgrade 3.2.0`.

**From the shell** — re-run the installer (one-command or manual) and it auto-detects the upgrade:

- The installer reads `.fenix-manifest.json` to detect your current version.
- It loads `scripts/upgrades/<from>-to-<to>.json` for the transition (e.g. `3.1.0-to-3.2.0.json`).
- Files marked `replace` are overwritten with the new version. The previous copy is moved to `_claude_backup/<new-version>-upgrade/<path>` so you can diff or recover.
- Files marked `preserve` (your `CLAUDE.md`, `docs/info.md`, `docs/task-router.md`, `docs/hint_index_map.md`) are left untouched.
- New files added in the target version (e.g. `docs/DISCLAIMER.md` in 3.1.0) are installed only if missing.
- Files removed in the target version are moved to the same backup folder.

If no upgrade path exists between your installed version and the kit's version, the installer stops with an error rather than silently merging.

### Uninstall

`/fx-uninstall` walks the manifest, removes everything Fenix installed, restores `_claude_backup/` contents to their original locations, and deletes the manifest. Uninstall does **not** revert an upgrade to the previous version — it removes Fenix entirely. To restore pre-upgrade copies of replaced files, look under `_claude_backup/<version>-upgrade/`.

### Prerequisites

- `unzip`, `python3` (manifest writes), bash 4+ or zsh.

### Recommended `.gitignore` additions in your project

If you keep the zip / unzipped folder in your project root briefly during install, make sure they don't get committed:

```
# P-3 (Fenix) distribution artifacts (clean up after install)
p3-fenix-*.zip
p3-fenix-*/

# Per-install backup (only present after install on a non-empty repo)
_claude_backup/

# Derived /fx-doc cache (rebuilt on demand) and audit drafts
docs-meta/.fenix-cache.json
docs/_pending/

# Per-user Claude Code settings
.claude/settings.local.json
```

## Defaults baked in

| Question | Default |
|---|---|
| Module path prefix | Auto-detect from manifest |
| Per-module docs folder | `docs/` |
| Auditor scope | Delta-gated — only modules with changed sources or stubs; `--all` for a full re-audit |
| Drawer suggestions | Off — enable per run with `--suggest-drawers` |
| Staleness gate | Per-doc `git log` since each doc's `last_reviewed_commit`, on every audit (cheap, intrinsic); `--stubs-only` to skip. Standalone report: `/fx-doc freshness` |
| Re-stamp authority | Anyone touching the module |
| `/fx-init` on partial repos | Leave existing files, only fill gaps |
| Worker write authority | Worker only — architect and tester are read-only |
| Tester escalation | Human-only — no auto-retry |
| Reference linking | Auto via `/fx-doc update`, gated by Phase 2 approval |

To change a default, edit `runbook.md` or the relevant agent rules file.

---

## License

MIT — see [LICENSE](LICENSE).

Copyright © 2026 Dumb Quokka. You may use, copy, modify, and redistribute this kit, provided the copyright notice and license text are preserved. Original repository: <https://github.com/ablack13/p-3-fenix>.

## Acknowledgments

Per-agent behavioral rules (architect, worker, tester) include guidance adapted from the [Karpathy guidelines skill](https://github.com/multica-ai/andrej-karpathy-skills) by multica-ai (MIT licensed). Inline attribution is preserved in each `claude-agents/*-rules.md` file. The original skill derives from [Andrej Karpathy's observations on LLM coding pitfalls](https://x.com/karpathy/status/2015883857489522876).

---

*Last updated for: 3.2.0*
