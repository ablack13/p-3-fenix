# P-3 (Fenix) — READ BEFORE FIRST

P-3 (Fenix) v4.0.0 — comprehensive reference for the repo map, rules layer, and file-based dev workflow installed in this repo.

This file is the front door. Read it once before doing anything else.

---

## What this is

P-3 (Fenix) is a kit that gives Claude Code:

1. **A repo map** — a compact navigation index inside `CLAUDE.md` (modules, entry points, cross-cutting facts, "when you need X, look here"). Code is the source of truth; the map only points into it. No per-module prose docs, by design.
2. **A rules layer** — `.claude/rules/`: always-on git and kit conventions, plus per-module invariants that auto-load when matching files are read.
3. **A file-based dev workflow** — architect → worker → tester delegation, all artifacts written to disk in `tasks/<task_id>/`.
4. **A manifest-driven uninstall** — clean removal that restores any pre-existing files.

Five slash commands, three subagents, file conventions for `.claude/rules/` and `tasks/`. That's the whole surface.

### What changed in 4.0.0

v3's wings/rooms/drawers documentation system — per-module `docs/` trees, `/fx-doc`, the auditor/discoverer/freshness/linker agents, the hint index, the task router — is **removed**, not optimized. Generated prose docs had no privileged status in Claude Code's context: they loaded only on the happy path, went stale as code moved, and were bypassed by ad-hoc requests and post-compaction sessions. The map now lives in the memoized `CLAUDE.md` layer and git rules in always-on `.claude/rules/`, so both survive compaction and apply even to requests that never read a source file. If your team needs human-facing prose docs, keep them in a wiki — out of the agent's context path.

---

## How the pieces fit

```
your-project/
├── CLAUDE.md                 ← read every session: bootstrap, REPO MAP, navigation rule
├── _claude_backup/           ← (pre-install backup + upgrade archives — IGNORED)
├── .fenix-manifest.json      ← install record, used by /fx-uninstall
├── .claude/
│   ├── commands/             ← /fx-* slash commands
│   ├── agents/               ← architect, worker, tester + per-agent rules files
│   └── rules/
│       ├── git-workflow.md       ← always-on (no paths: — on purpose)
│       ├── fenix-conventions.md  ← always-on (no paths: — on purpose)
│       └── <module>.md           ← paths:-scoped, created by /fx-init on your approval
├── docs/
│   ├── info.md               ← authoritative project context (yours)
│   └── DISCLAIMER.md         ← session bootstrap messages (yours)
├── tasks/                    ← file-based dev workflow artifacts
│   └── <task_id>/
│       ├── task.md           ← task metadata + navigation
│       ├── architect-plan.md ← Phase 2 output
│       ├── worker-log.md     ← Phase 3 output (live status)
│       ├── tester-review.md  ← Phase 4 output
│       └── outcome.md        ← Phase 5/6 result
└── docs-meta/                ← runbook + templates (operational reference)
```

Claude reads `CLAUDE.md` automatically every session — the map rides along and is re-read after compaction. Always-on rules load at session start. Path-scoped rules load when matching files are read. Everything else loads on demand.

---

## Slash commands — full reference

### `/fx-init`

Generate or refresh the repo map + scaffold rules. Idempotent.

**What it does (in phases):**

1. **Pre-flight** — locates the `FENIX:MAP` markers in `CLAUDE.md`, checks rules files, `docs/info.md`, `tasks/`, manifest.
2. **Discover** — one repo-scan subagent builds the four map sections from the project manifest and top-level structure (HARD RULE: via Task subagent, not inline — keeps the main context clean).
3. **Plan** — shows the full generated map, suggested per-module rules files, and what else will be touched. Awaits approval.
4. **Write** — replaces map content between the markers (appends the section if markers are missing), creates approved rules files from `docs-meta/templates/rules-module.md`, never overwrites existing ones.
5. **Top-level files** — drafts `info.md` if missing, fills `CLAUDE.md` placeholders (`Stack`, `Local environment`), creates `tasks/`, updates `.fenix-manifest.json`.

Re-run any time the structure changes — only the text between the markers is regenerated; everything else in `CLAUDE.md` is yours.

### `/fx-init upgrade [version]`

Update the installed kit from inside Claude Code. Reads the manifest, resolves the target release, shows a plan, runs `install-online.sh` on approval. See "Upgrading" in `README.md` / `docs-meta/runbook.md`.

### `/fx-info`

Read-only status check. Cheap, fast, doesn't trigger anything.

Reports: map status (modules mapped, or EMPTY → run `/fx-init`), rules counts (always-on vs path-scoped), `CLAUDE.md` placeholder state, open/closed tasks, manifest version and action count.

### `/fx-task <description>`

Explicit navigation — see the classification before work begins.

Prints which map sections matched, the module scope, and which code entry points will be opened. Optional override before proceeding. No subagents involved.

### `/fx-task new <description> [briefs:<path>]`

File-based dev-team workflow. Six phases:

1. **Create task folder** at `tasks/<task_id>/` with `task.md`.
2. **Navigation** — match against the in-context repo map → `map_sections`, `code_entry_points`, `module_scope`. Aborts to `/fx-init` if the map is empty.
3. **Architecture** — `architect` writes `architect-plan.md`. Approval gate.
4. **Implementation** — `worker` writes `worker-log.md` with live status updates. Pre-review gate.
5. **Review** — `tester` writes `tester-review.md`. Verdict: pass / minor-issues / major-issues / blocked.
6. **Disposition + outcome** — human chooses: close / re-dispatch worker / cancel. `outcome.md` written. If the task changed repo structure, the close prints a **map-refresh hint** (`run /fx-init`).

All artifacts persist in the task folder. Chat output is brief pointers to files.

Optional `briefs:<path>` attaches external specs/mockups/logs. Can also reference paths inline.

### `/fx-agent rules`

List all agent rules files for editing.

### `/fx-agent list`

List all agents with tool access.

### `/fx-uninstall`

Manifest-driven removal of every file Fenix created.

- Reads `.fenix-manifest.json`, walks entries in reverse order.
- Removes Fenix-created files (commands, agents, rules, templates, `CLAUDE.md`).
- Restores `_claude_backup/CLAUDE.md` and `_claude_backup/.claude/` to their original locations, then removes the empty backup folder.
- Warns about user content before deleting: edited `.claude/rules/` files, open tasks. Legacy 3.x manifests: stub-filled docs and Fenix-linked reference files are handled by their legacy branches.
- Provides explicit instructions for git-stashing before uninstall if needed.

Flags: `--dry-run`, `--keep <path>`, `--force`.

---

## Subagents — full reference

Each agent is a small specialized worker. Spawned by the main agent via the Task tool. Runs in fresh context with constrained tools.

Every agent has a sibling `<name>-rules.md` file for editable behavior. Run `/fx-agent rules` to see them all.

#### `architect`
- **Tools:** Read, Edit, Write, Grep, Glob, Bash.
- **Writes to:** `<task_dir>/architect-plan.md` ONLY.
- **Used by:** `/fx-task new` Phase 3.
- Receives `map_sections`, `code_entry_points`, `module_scope`, `briefs`. Reads entry points, follows code on demand; treats map lines as hints and confirms them against code.
- **Verifies developer-stated facts before pinning them in the plan** (versions, library availability, paths, API surfaces). Logs verifications in a "Verified facts" table; lists unverifiable claims under "Assumptions" with risk notes.

#### `worker`
- **Tools:** Read, Edit, Write, Bash, Grep, Glob.
- **Writes to:** project code per the plan, plus `<task_dir>/worker-log.md` with live status.
- **The only Fenix agent that writes project code.** Never edits `CLAUDE.md`, `.claude/rules/`, or `docs/`.
- Reads every file before editing it — which also auto-loads that file's path-scoped rules.
- Updates `worker-log.md` after EACH plan item (start, completion, blocker). Real-time log, not batch.

#### `tester`
- **Tools:** Read, Edit, Write, Grep, Glob, Bash.
- **Writes to:** `<task_dir>/tester-review.md` ONLY.
- **Used by:** `/fx-task new` Phase 5.
- Compares plan vs. actual execution; pattern compliance is judged against the sources the plan's "Patterns to follow" table cites (files and rules). Flags scope creep, pattern violations, missing items.

---

## File conventions

### Rules (`.claude/rules/`)

```
.claude/rules/
├── git-workflow.md          ← always-on: commit/PR/branch conventions (edit the placeholders!)
├── fenix-conventions.md     ← always-on: kit-wide agent behavior
└── <module>.md              ← per-module invariants, loads on matching READ
```

Per-module rules carry `paths:` frontmatter:

```yaml
---
paths:
  - "modules/feature/practice/**"
---
```

Keep scoped files under ~40 lines — invariants, not documentation. `/fx-init` suggests candidates and creates only what you approve; it never overwrites an existing rules file. **Do not add `paths:` to the two always-on files** — unscoped is what makes git rules apply to "prepare a PR description".

### Tasks (file-based dev workflow)

```
tasks/<YYYYMMDD-HHMM-slug>/
├── task.md            ← description, briefs, navigation, phase status
├── architect-plan.md  ← architect output (the contract)
├── worker-log.md      ← worker output (live execution record)
├── tester-review.md   ← tester output
└── outcome.md         ← final disposition
```

Status fields use these states:
- Plan items: `pending` / `in-progress` / `done` / `blocked` / `skipped`.
- Tester verdict: `pass` / `minor-issues` / `major-issues` / `blocked`.
- Task: `open` / `in-progress` / `blocked` / `closed`.

### Briefs (developer-supplied task context)

No fixed convention. Drop a folder anywhere in the repo (e.g., `2105/`, `briefs/PM-1234/`). Mention the path when you invoke `/fx-task new`.

---

## Task navigation — how it works

The repo map in `CLAUDE.md` is already in context every session. When you make a substantive request:

1. Claude matches it against `When you need X, look here` and `Entry points`.
2. Identifies module scope from the `Modules` list.
3. Reads `docs/info.md` (once per session), any briefs you mentioned, then the matched entry points.
4. Follows code on demand — imports, call sites — as far as the task requires. Reading files auto-loads their path-scoped rules.
5. Forms a plan, proceeds.

Silent for normal tasks. Use `/fx-task <description>` to see the navigation decision.

---

## The repo map — how it works

- `/fx-init` discovers modules from the project manifest (`settings.gradle.kts` or equivalent — never a directory scan) and dispatches ONE repo-scan subagent to draft the four sections.
- You review the full map text before it's written. It replaces only the span between `<!-- FENIX:MAP:START -->` and `<!-- FENIX:MAP:END -->`.
- Budget ~120 map lines; `CLAUDE.md` under ~200 total. A growing map is absorbing documentation — push detail back into code or a scoped rules file.
- The map is a **hint, not truth**: agents confirm its claims against the code it points to. On mismatch, code wins and the task flags "map stale — run `/fx-init`".
- Refresh after structure changes: re-run `/fx-init`. `/fx-task new` reminds you at close when a task moved things around.

---

## Rules — how they load

- **Always-on** (`git-workflow.md`, `fenix-conventions.md`): load at session start, like `CLAUDE.md`. No `paths:` frontmatter — that's the feature.
- **Path-scoped** (`<module>.md`): load when a file matching the glob is READ. They're summarized away at compaction and reload on the next matching read — the worker's read-before-edit discipline covers this.
- Requires Claude Code ≥ 2.0.64. Before relying on the mechanics, run the two live checks in `docs-meta/runbook.md` § "Verify rules mechanics on your CLI version" (read-vs-write trigger, compaction survival). Keep rules at project level — user-level `~/.claude/rules/` with `paths:` were ignored (claude-code#21858).

---

## Backup folder and uninstall

### What happens at install if you already had a CLAUDE.md or .claude/ folder

The setup script moves any pre-existing `CLAUDE.md` and `.claude/` into a sibling `_claude_backup/` folder *before* installing Fenix. Inside that folder it writes:

- `IGNORE_THIS_FOLDER.md` — disclaimer telling Claude (and any agent) the folder is archival data and must not be read or followed.
- `.claudeignore` — defense-in-depth pattern matching everything in the folder.

The fresh Fenix `CLAUDE.md` and `.claude/` then install into a clean slate. The pre-existing content stays untouched in `_claude_backup/` for the lifetime of the install. Upgrade archives (`_claude_backup/<version>-upgrade/`) live alongside it.

Don't edit `_claude_backup/` manually — `/fx-uninstall` reads the manifest to know what to restore.

### What `/fx-uninstall` does

Reads `.fenix-manifest.json`, walks entries in reverse:
1. Removes Fenix-created files and folders (including `.claude/rules/` files it created).
2. Restores `_claude_backup/CLAUDE.md` and `_claude_backup/.claude/` to repo root.
3. Deletes the now-empty `_claude_backup/` along with its disclaimer markers.
4. Deletes `.fenix-manifest.json`.

(Legacy pre-3.0.0 installs that used the old `CLAUDE.md.old` quarantine flow are still handled, as are 3.x manifests with stub-fill / reference-link entries.)

Before deleting anything, the command shows a preflight report flagging user content (rules files you've edited, open tasks) with exact `git stash` commands to back up before proceeding.

User work is never silently destroyed. The command requires explicit confirmation.

---

## Day-to-day workflows

### Quick fix — small task, scoped context

Just describe it normally:

> fix the bug in the wallpaper rendering when device rotates

Claude matches the map silently → opens the relevant entry points → reads only what the task needs. Forms a plan.

### Substantive new feature — full discipline

Use the dev-team workflow:

```
/fx-task new add a "skip card" button to practice screen briefs:2105/
```

Architect designs (with verification of versions, paths, API claims) → you approve → worker implements (with live status log) → tester reviews → you decide disposition.

All artifacts in `tasks/<task_id>/`. Re-runnable, auditable, paper trail.

### After the repo structure changes

```
/fx-init
```

Regenerates the map between the markers. Your `CLAUDE.md` sections outside the markers are untouched. `/fx-task new` reminds you at close when a task changed structure.

### Encoding a module invariant

Add it to that module's `.claude/rules/<module>.md` (or ask `/fx-init` to scaffold one). It'll auto-load whenever the module's files are read.

### Tuning agent behavior

```
/fx-agent rules
```

Lists all agent rules files. Open the one you want to tune in your editor. Save. Next invocation picks up the changes.

### Removing Fenix from the project

```
/fx-uninstall
```

Reviews everything that will be removed, warns about user content, restores `_claude_backup/` contents to their original locations. Manifest-driven, surgical.

---

## Common questions

**What if I add or rename a module?** Re-run `/fx-init` — the map regenerates between the markers; existing rules files are untouched.

**Where do I document a module now?** You don't — the code documents itself. Durable invariants go in the module's rules file; navigation goes in the map; team-facing prose goes in your wiki.

**Claude's plan contradicts the map.** Code wins. The architect notes the mismatch in Risks; re-run `/fx-init` to refresh the map.

**Claude ignores our git conventions on "prepare a PR description".** Check that `.claude/rules/git-workflow.md` exists and has NO `paths:` frontmatter — scoping it is what turns it off for promptless requests. Verify with `/context`.

**The architect picked the wrong version of a library.** Check `tasks/<task_id>/architect-plan.md` "Verified facts" and "Assumptions" sections. If the version is in Assumptions, the architect couldn't verify it — your input was treated as a guess. Architect rules can be tuned in `.claude/agents/architect-rules.md`.

**Worker got blocked mid-execution.** Check `tasks/<task_id>/worker-log.md` "Blockers encountered". Either resolve and re-dispatch, or cancel.

**I upgraded from 3.2.0 — where are my old docs?** In `_claude_backup/4.0.0-upgrade/`, exactly as they were (wings, rooms, drawers, reference scaffolding). Move anything still valuable into rules files or the map; hand-written `reference/` files were left in place.

**My CLI is older than 2.0.64.** `.claude/rules/` won't load. Upgrade Claude Code, or temporarily inline the git rules into `CLAUDE.md`.

---

## File reference table

| Path | Purpose | Edit by hand? |
|---|---|---|
| `CLAUDE.md` | Bootstrap, repo map, navigation rule | Yes — everything OUTSIDE the FENIX:MAP markers is yours |
| `_claude_backup/` | Pre-install backup + upgrade archives | Don't — restored on uninstall |
| `.fenix-manifest.json` | Install record for /fx-uninstall | No (auto-managed) |
| `.claude/rules/git-workflow.md` | Git/PR conventions (always-on) | Yes — fill the placeholders |
| `.claude/rules/fenix-conventions.md` | Kit-wide agent behavior (always-on) | Yes (rarely) |
| `.claude/rules/<module>.md` | Per-module invariants (paths:-scoped) | Yes — the main edit point for module knowledge |
| `docs/info.md` | Authoritative project context | Yes |
| `docs/DISCLAIMER.md` | Session bootstrap messages | Yes |
| `tasks/<id>/*` | Per-task artifacts | Yes (in active tasks) |
| `.claude/commands/*.md` | Slash command definitions | Yes (to customize) |
| `.claude/agents/*.md` | Agent definitions | Yes (to customize) |
| `.claude/agents/*-rules.md` | Per-agent behavioral rules | Yes (the main edit point for agent behavior) |
| `docs-meta/runbook.md` | Full operational reference | Rarely |
| `docs-meta/templates/*` | File shape references | No |

---

## What to do next

If this is your first time:

1. Run `unzip p3-fenix-4.0.0.zip && ./p3-fenix-4.0.0/scripts/setup.sh` if you haven't (or the one-command installer).
2. Run `/fx-init` — generates the repo map, drafts `info.md`, suggests per-module rules.
3. Edit `.claude/rules/git-workflow.md` — fill in your commit/PR/branch conventions (it ships with placeholders).
4. Run `/fx-info` — confirm the map is populated and rules are in place.
5. Run the two live checks in `docs-meta/runbook.md` § "Verify rules mechanics on your CLI version".
6. Try a real task: `/fx-task new <small task>` to feel the file-based workflow.

After a few cycles, the kit fades into the background. The map stays small, rules load themselves, tasks leave a paper trail. Uninstall is surgical when you need it.

---

*Last updated for: 4.0.0*
