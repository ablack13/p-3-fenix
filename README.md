# P-3 (Fenix) v4.0.0 — Repo Map + Rules + Dev Team Kit

Drop-in starter kit for any multi-module project. A repo map in `CLAUDE.md`, behavior rules in `.claude/rules/`, and a file-based dev-team workflow. Code is the source of truth — no per-module prose docs.

## Contents

```
p3-fenix-4.0.0/
├── README.md                    ← this file
├── runbook.md                   ← main runbook (full operational details)
├── LICENSE
├── P-3 (Fenix)- READ BEFORE FIRST.md  ← full reference for commands/agents/workflows
├── scripts/
│   ├── setup.sh                 ← installer (manifest-driven, idempotent)
│   ├── install-online.sh        ← one-command online installer
│   └── upgrades/                ← pairwise <from>-to-<to>.json upgrade configs
├── claude-commands/
│   ├── fx-init.md               ← /fx-init (repo map + rules scaffolding; upgrade mode)
│   ├── fx-info.md               ← /fx-info
│   ├── fx-task.md               ← /fx-task <description> | new <description>
│   ├── fx-agent.md              ← /fx-agent rules | list
│   └── fx-uninstall.md          ← /fx-uninstall (manifest-driven removal)
├── claude-agents/
│   ├── architect.md             ← designs implementation plans (read-only on code)
│   ├── architect-rules.md       ← architect behavioral rules
│   ├── worker.md                ← executes plans (only writer of project code)
│   ├── worker-rules.md          ← worker behavioral rules
│   ├── tester.md                ← reviews worker output (read-only on code)
│   └── tester-rules.md          ← tester behavioral rules
└── templates/
    ├── CLAUDE.md                ← repo-root file: bootstrap, inline repo map, navigation rule
    ├── DISCLAIMER.md            ← docs/DISCLAIMER.md (editable bootstrap ritual)
    ├── info.md                  ← docs/info.md template
    ├── rules-git-workflow.md    ← .claude/rules/git-workflow.md (always-on)
    ├── rules-fenix-conventions.md ← .claude/rules/fenix-conventions.md (always-on)
    ├── rules-module.md          ← per-module rules template (paths:-scoped)
    └── task.md, architect-plan.md, worker-log.md, tester-review.md, outcome.md
                                  ← dev-workflow artifact templates
```

## What's new in v4.0.0

**v4 removes the documentation system.** Wings/rooms/drawers, `/fx-doc`, the module-auditor, module-discoverer, freshness-scanner, reference-linker, the hint index, the task router, and the doc cache are gone — not optimized, removed. The v3 product was a docs layer; the v4 product is **navigation + rules + workflow**.

Why: generated prose docs had no privileged status in Claude Code's context — they loaded only when the happy path explicitly read them, went stale the moment code moved, and were bypassed entirely by ad-hoc requests and post-compaction sessions. Meanwhile the two layers that *do* have privileged status were underused. v4 moves everything there:

- **Repo map in `CLAUDE.md`** — a ~120-line navigation index (modules, entry points, cross-cutting facts, "when you need X, look here") between `FENIX:MAP` markers, generated and refreshed by `/fx-init`. `CLAUDE.md` is re-read after compaction, so the map survives where read-once docs didn't.
- **`.claude/rules/`** — `git-workflow.md` and `fenix-conventions.md` ship **always-on** (no `paths:` frontmatter on purpose), so git conventions apply even to requests that never read a source file ("prepare a PR description"). Per-module rules are `paths:`-scoped and auto-load when matching files are read. Requires Claude Code ≥ 2.0.64.
- **The architect → worker → tester workflow stays** — now driven by matched map sections and code entry points instead of rooms and wings. Agents read code on demand; the map is a hint, the code is the truth.
- **Manifest-driven upgrade sweep** — upgrading a 3.2.0 install moves every generated doc (wings, rooms, drawers, reference scaffolding) into `_claude_backup/4.0.0-upgrade/`. Auditor-filled prose is human-approved content: archived, never hard-deleted.

Human-facing prose documentation, if your team needs it, belongs in a wiki — not in the agent's context path.

## What's new in v3.2.0

- **Delta-gated audits** — `/fx-doc audit` / `update` spawned a `module-auditor` only for modules whose documented sources actually changed, or that still held unfilled stubs, decided from a cheap per-doc `git log` gate over `docs-meta/.fenix-cache.json`.
- **Reliable manifest writes** — `setup.sh`'s manifest append passes values through the environment and fails loudly instead of swallowing errors.

*(3.2.0 docs-system features are removed in 4.0.0 — kept here as release history.)*

## What's new in v3.1.0

- **Karpathy-aligned agent rules** — architect surfaces assumptions and resists scope creep, worker resists overcomplication, tester demands verifiable success criteria. Adapted from the [Karpathy guidelines skill](https://github.com/multica-ai/andrej-karpathy-skills) (MIT). *(Still present in 4.0.0.)*
- **`/clear` nudge on task close** — `/fx-task new` ends with a prompt to clear context. *(Still present.)*
- AI-optimized doc output and the 70-line doc cap. *(Removed with the docs system in 4.0.0.)*

## What's new in v3.0.0

- **All commands prefixed with `fenix-`** — no collision with built-ins, consistent namespace.
- **Dev-team agents** — `architect`, `worker`, `tester` for the architect → worker → tester workflow via `/fx-task new`. *(The surviving core of the kit.)*
- **Per-agent rules files** — every agent has a `<name>-rules.md` sibling for editable behavior. Run `/fx-agent rules` to see them.

## Install

> **Run from the root directory of your project** — the same directory where you launch Claude Code (`claude`). The installer writes into `$(pwd)`.

### One-command install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ablack13/p-3-fenix/main/scripts/install-online.sh | bash
```

This downloads the latest release zip into a temp dir, extracts it, runs the installer against your repo root, and cleans up after itself.

Pin a specific version:

```bash
FENIX_VERSION=4.0.0 bash -c "$(curl -fsSL https://raw.githubusercontent.com/ablack13/p-3-fenix/main/scripts/install-online.sh)"
```

Want to inspect the installer before running? Read it at <https://github.com/ablack13/p-3-fenix/blob/main/scripts/install-online.sh>.

### Manual install (download → unzip → run)

```bash
curl -LO https://github.com/ablack13/p-3-fenix/releases/download/4.0.0/p3-fenix-4.0.0.zip
unzip p3-fenix-4.0.0.zip
./p3-fenix-4.0.0/scripts/setup.sh
rm -rf p3-fenix-4.0.0 p3-fenix-4.0.0.zip
```

### After install

Open Claude Code in this project and run:

```
/fx-init
```

It scans the repo via a single subagent, generates the repo map inside `CLAUDE.md` (between the `FENIX:MAP` markers), drafts `docs/info.md`, and suggests per-module rules files — you approve what gets created.

### What the installer does

- Copies the kit into `.claude/` (commands, agents, rules), `docs/`, `docs-meta/`, `tasks/` and writes a fresh `CLAUDE.md`.
- If your project already has a `CLAUDE.md` or `.claude/` folder, it moves them aside into `_claude_backup/` (with an `IGNORE_THIS_FOLDER.md` disclaimer so Claude leaves the backup alone).
- Records every action in `.fenix-manifest.json` so `/fx-uninstall` can reverse the install cleanly.

### Upgrading an existing install

Two ways:

**From inside Claude Code (recommended):**

```
/fx-init upgrade
```

Reads `.fenix-manifest.json`, queries GitHub for the latest release, shows a plan, and runs the installer on approval. Pin a target version with `/fx-init upgrade 4.0.0`.

**From the shell** — re-run the installer (one-command or manual) and it auto-detects the upgrade:

- The installer reads `.fenix-manifest.json` to detect your current version.
- It loads `scripts/upgrades/<from>-to-<to>.json` for the transition (e.g. `3.2.0-to-4.0.0.json`).
- Files marked `replace` are overwritten with the new version. The previous copy is moved to `_claude_backup/<new-version>-upgrade/<path>` so you can diff or recover.
- Files marked `remove` are moved to the same backup folder.
- **4.0.0 specifics:** `CLAUDE.md` **is replaced** (unlike 3.x upgrades) — the v4 repo map and navigation rules live there. Your pre-upgrade copy lands in `_claude_backup/4.0.0-upgrade/CLAUDE.md`; copy custom sections back by hand, then run `/fx-init`. Every generated doc recorded in your manifest (wings, rooms, drawers, reference scaffolding) is **swept into the same backup folder** — archived, never hard-deleted. `docs/info.md` and `docs/DISCLAIMER.md` are preserved.
- Upgrades from 3.0.0 or 3.1.0 must go through the 3.2.0 kit first — no direct JSON to 4.0.0 is shipped.

If no upgrade path exists between your installed version and the kit's version, the installer stops with an error rather than silently merging.

### Uninstall

`/fx-uninstall` walks the manifest, removes everything Fenix installed, restores `_claude_backup/` contents to their original locations, and deletes the manifest. Uninstall does **not** revert an upgrade to the previous version — it removes Fenix entirely. To restore pre-upgrade copies of replaced files, look under `_claude_backup/<version>-upgrade/`.

### Prerequisites

- `unzip`, `python3` (manifest writes), bash 4+ or zsh.
- Claude Code ≥ 2.0.64 (`.claude/rules/` support). Check with `claude --version`.

### Recommended `.gitignore` additions in your project

If you keep the zip / unzipped folder in your project root briefly during install, make sure they don't get committed:

```
# P-3 (Fenix) distribution artifacts (clean up after install)
p3-fenix-*.zip
p3-fenix-*/

# Per-install backup (only present after install on a non-empty repo)
_claude_backup/

# Per-user Claude Code settings
.claude/settings.local.json
```

## Defaults baked in

| Question | Default |
|---|---|
| Module discovery | From the project manifest (`settings.gradle.kts` or equivalent) — never directory-scan |
| Repo map location | Inline in `CLAUDE.md` between `FENIX:MAP:START/END` markers |
| Map size budget | ~120 lines of map; keep the whole `CLAUDE.md` under ~200 |
| Map refresh | Re-run `/fx-init` after structure changes; `/fx-task new` hints at close when needed |
| Always-on rules | `git-workflow.md`, `fenix-conventions.md` — no `paths:` frontmatter, on purpose |
| Per-module rules | Suggested by `/fx-init`, created only on approval; never overwritten once created |
| Per-module prose docs | None, by design — code is the source of truth |
| Worker write authority | Worker only — architect and tester are read-only on project code |
| Tester escalation | Human-only — no auto-retry |

To change a default, edit `runbook.md` or the relevant agent rules file.

---

## License

MIT — see [LICENSE](LICENSE).

Copyright © 2026 Dumb Quokka. You may use, copy, modify, and redistribute this kit, provided the copyright notice and license text are preserved. Original repository: <https://github.com/ablack13/p-3-fenix>.

## Acknowledgments

Per-agent behavioral rules (architect, worker, tester) include guidance adapted from the [Karpathy guidelines skill](https://github.com/multica-ai/andrej-karpathy-skills) by multica-ai (MIT licensed). Inline attribution is preserved in each `claude-agents/*-rules.md` file. The original skill derives from [Andrej Karpathy's observations on LLM coding pitfalls](https://x.com/karpathy/status/2015883857489522876).

---

*Last updated for: 4.0.0*
