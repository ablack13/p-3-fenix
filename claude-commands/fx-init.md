# /fx-init — Bootstrap P-3 structure

Bootstrap wings/rooms/drawers documentation when missing or partial. Idempotent — safe to re-run. Forces per-module subagent dispatch (no inline shortcut).

## Modes

- `/fx-init` — bootstrap (default). Scaffolds wings, drafts `info.md`, populates `CLAUDE.md`, generates `task-router.md`. Phases 0–4 below.
- `/fx-init upgrade [version]` — update the installed Fenix kit. Reads `.fenix-manifest.json`, queries GitHub for the latest release (or uses the pinned version), and runs `install-online.sh` to apply the upgrade JSON. See "Upgrade mode" at the end of this file.

If the first argument is `upgrade`, jump straight to "Upgrade mode" and skip the bootstrap phases below.

## Phase 0 — Pre-flight (read-only)

1. Verify `CLAUDE.md` exists at repo root. If missing, abort and tell the user to run `scripts/setup.sh` (from the unzipped `p3-fenix-<version>/` distribution) first.

2. Check `CLAUDE.md`:
   - Has placeholder sections (`<!-- Filled in by /fx-init` or empty `## Stack`, `## Project layout`, `## Local environment`) → flag for population in Phase 4.
   - Fully populated → leave alone.

3. Check `docs/info.md`:
   - Missing → flag for first-time draft in Phase 4.
   - Present and customized → leave alone.
   - Present but matches the template (still has `<one-line summary...>` placeholder) → flag for first-time draft.

4. Check `reference/` folder:
   - Missing → flag for creation in Phase 4.
   - Present → list any `.md` files lacking frontmatter or not in `hint_index_map.md`. These will be linked during the next `/fx-doc update`, not during `/fx-init`. Note in Phase 1 status.

5. Check `tasks/` folder:
   - Missing → flag for creation in Phase 4.

6. Check `.fenix-manifest.json`:
   - Missing → first-time install or pre-manifest install. Will be created in Phase 4 listing all files Fenix manages.
   - Present → read it. Phase 4 will only update entries, not regenerate from scratch.

## Phase 1 — Discover

1. Print current state from Phase 0 detection.

2. Read `docs/info.md` if customized (authoritative context).

3. Discover modules from `settings.gradle.kts` (or equivalent for non-Gradle projects). Run:
   ```
   grep -E "^include" settings.gradle.kts
   ```
   This is canonical. Don't directory-scan.

4. **Spawn `module-discoverer` per module via the Task tool.** Use `subagent_type=module-discoverer`. Pass `{ module_name, module_path }`. Each subagent inspects build dependencies, scans source for public surface, returns a structure proposal.

   **HARD RULE:** This MUST be done via Task subagent dispatch. The main agent is forbidden from doing module discovery inline. If the main agent finds itself reading `build.gradle.kts` files directly during Phase 1, it has violated this rule — STOP, restart by dispatching subagents.

   Reasoning: inline discovery loses parallelism, pollutes the main agent's context with N modules of detail, and the discoverer's specialized rules don't apply. Subagent dispatch keeps the main agent's context clean for synthesis and ensures consistent discovery behavior.

5. Synthesize structure plan from subagent returns:

   | Module | Path | Action | Rooms | Drawers suggested |

   Action values: `NEW WING`, `SKIP (internal only)`, `ALREADY HAS DOCS`, `PARTIAL (add rooms)`.

## Phase 2 — Plan

Output the plan. Stop. Wait for human approval.

Include:
- Wing/room structure (from Phase 1).
- Whether `docs/info.md` will be drafted.
- Whether `CLAUDE.md` placeholders will be populated.
- Whether `docs/task-router.md` will be generated.
- Whether `reference/`, `tasks/` folders will be created.

## Phase 3 — Generate wings

For each file in approved plan:

1. Use templates from `docs-meta/templates/`.
2. Frontmatter `documents:` initially empty `[]` or pointing at the module folder. **Real source-file lists are filled later by `module-auditor` during the first `/fx-doc audit`.** Wings are scaffolded with stubs intentionally — fills happen incrementally.
3. `last_reviewed_commit` = `git rev-parse --short HEAD`.
4. `last_reviewed_date` = today.
5. Add to manifest: `{action: "create", path: <path>, phase: "init"}`.

Build `docs/hint_index_map.md` from discovered structure.

**IMPORTANT:** Generated rooms WILL contain template placeholders (`<2-4 sentences on...>`, etc.). This is by design. The `module-auditor` is responsible for filling them on the next `/fx-doc audit` or task-close audit. Do NOT attempt to fill them inline during init — that's the auditor's job.

## Phase 4 — Generate top-level files

### `docs/info.md`

If flagged in Phase 0:
1. Inspect: `settings.gradle.kts`, `gradle/libs.versions.toml`, `build.gradle.kts` files, root `README.md`.
2. Draft `docs/info.md` matching the template structure.
3. Show the draft to the user. Apply edits if requested. Save.
4. Add to manifest: `{action: "create", path: "docs/info.md", phase: "init"}`.

### `CLAUDE.md` placeholders

If flagged:
1. Populate `## Stack` from discovered toolchain.
2. Populate `## Project layout` from `settings.gradle.kts` modules.
3. Populate `## Local environment` with sensible defaults.
4. Show the diff. Apply edits if requested. Save.
5. Manifest entry: `{action: "modify", path: "CLAUDE.md", phase: "init", changes: "populated placeholders"}`.

DO NOT replace bootstrap protocol, task routing rule, slash commands list, or subagents list.

### `docs/task-router.md`

ALWAYS generate or refresh.

1. Walk every `<wing>/rooms/*.md`.
2. Collect unique room names. Build category sections per name.
3. Description hints from standard templates (di, persistence, etc.). Custom names → generic description.
4. Preserve `## Custom categories` section.
5. Update timestamps.
6. Manifest entry.

### `reference/` folder

If flagged:
1. Create `reference/`.
2. Create `reference/README.md` with index pointer.
3. Manifest entry.

DO NOT auto-link existing reference files. That's `/fx-doc update`'s job.

### `tasks/` folder

If flagged:
1. Create `tasks/`.
2. Create `tasks/.gitkeep` (empty file, ensures the folder is committable).
3. Manifest entry.

### `.fenix-manifest.json`

If missing, create it. Otherwise, append entries from this run.

Format:
```json
{
  "fenix_version": "3.2.0",
  "installed_at": "<timestamp>",
  "actions": [
    {"action": "create", "path": "CLAUDE.md", "phase": "install"},
    {"action": "backup-move", "path": "CLAUDE.md", "to": "_claude_backup/CLAUDE.md", "phase": "install"},
    {"action": "backup-move", "path": ".claude",   "to": "_claude_backup/.claude",   "phase": "install"},
    {"action": "create", "path": "docs/info.md", "phase": "init", "timestamp": "..."},
    {"action": "create", "path": "modules/foo/docs/", "phase": "init", "timestamp": "..."},
    ...
  ]
}
```

## Non-destructive guarantees

- `hint_index_map.md` exists → only add new wing entries.
- Wing README exists → never overwrite.
- Rooms or drawers exist → never overwrite.
- `info.md` customized → never touch.
- `CLAUDE.md` populated → only fill remaining placeholders.
- `task-router.md` Custom categories preserved.
- `tasks/` content untouched on re-run.
- Manifest never deletes entries; only appends.

## Drawer policy

DO NOT auto-generate drawers. `module-discoverer` SUGGESTS them in Phase 2; create only if developer approves.

## Final output

```
/fx-init complete

Wings created: N
Rooms generated: M (with stubs — auditor will fill on first /fx-doc audit)
Drawers suggested but NOT created: K

CLAUDE.md placeholders populated: yes/no
info.md: drafted / left untouched
hint_index_map.md: created / new wings added only
task-router.md: <category-count> categories generated
reference/: created / already present
tasks/: created / already present
Manifest: .fenix-manifest.json (<entry-count> entries total)

⚠ Generated rooms contain template placeholders. Run /fx-doc audit to have
the auditor read source and fill them with real content. The audit phase
proposes content for review; nothing is written without approval.

Next: review generated structure, then run /fx-doc audit to start filling stubs.
```

---

## Upgrade mode — `/fx-init upgrade [version]`

Reached only when the first argument is `upgrade`. Updates the installed Fenix kit by invoking `install-online.sh` from inside this Claude Code session. No need to leave the chat.

### Phase A — Pre-flight

1. Read `.fenix-manifest.json`. If missing, abort:
   ```
   ⚠ Fenix is not installed in this repo (no .fenix-manifest.json).
   Run the installer first:
     curl -fsSL https://raw.githubusercontent.com/ablack13/p-3-fenix/main/scripts/install-online.sh | bash
   ```

2. Extract `installed_version` from the manifest's `fenix_version` field.

3. If a target version was passed (`/fx-init upgrade 3.2.0`), use it as `target_version`. Otherwise resolve the latest release tag:
   ```bash
   curl -fsSL https://api.github.com/repos/ablack13/p-3-fenix/releases/latest \
     | python3 -c "import json,sys; print(json.load(sys.stdin).get('tag_name','').lstrip('v'))"
   ```
   If the call fails (network, rate limit), abort with the curl error and suggest passing an explicit version.

4. Compare versions:
   - `installed == target` → print "Already on <version>. Nothing to do." Stop.
   - `installed > target` → warn "Installed version (<X>) is newer than target (<Y>). Refusing." Stop.
   - `installed < target` → proceed to Phase B.

5. Check for uncommitted changes in Fenix-managed paths:
   ```bash
   git status --porcelain -- .claude/ docs-meta/ docs/STYLE.md "P-3 (Fenix)- READ BEFORE FIRST.md" 2>/dev/null
   ```
   If output is non-empty, surface it and ask the developer to either commit, stash, or explicitly confirm before continuing — `upgrade-replace` will back up the current copies but overwriting uncommitted work is irreversible without `git stash`.

### Phase B — Plan

Print the upgrade plan:

```
Fenix upgrade plan

Current: <installed_version>
Target:  <target_version>

Strategy:
  - Replace kit-owned files (agent rules, slash commands, runbook, doc templates).
  - Preserve user content (CLAUDE.md, docs/info.md, docs/task-router.md, docs/hint_index_map.md).
  - Create new files added in <target_version> (if any).
  - Pre-change copies → _claude_backup/<target_version>-upgrade/

Uncommitted changes in Fenix-managed paths:
  <list, or "none">

Approve to proceed? (yes / no)
```

Wait for explicit approval. Don't dispatch automatically.

### Phase C — Execute

On approval, run the installer. If no version was pinned:

```bash
curl -fsSL https://raw.githubusercontent.com/ablack13/p-3-fenix/main/scripts/install-online.sh | bash
```

If a version was pinned:

```bash
FENIX_VERSION=<target_version> bash -c "$(curl -fsSL https://raw.githubusercontent.com/ablack13/p-3-fenix/main/scripts/install-online.sh)"
```

Capture stdout/stderr. The installer detects the existing manifest, dispatches `scripts/upgrades/<from>-to-<to>.json` from inside the temp-extracted kit, and writes results back into the repo.

On non-zero exit:
- Surface the installer's last 20 lines of output.
- Common causes: no upgrade JSON for the transition; downgrade attempt; network failure mid-download. The temp dir is auto-cleaned via trap, so the repo is not left with stray artifacts.

### Phase D — Report

On success, print:

```
Fenix upgraded: <installed_version> → <target_version>

Backups: _claude_backup/<target_version>-upgrade/
  - Contains pre-upgrade copies of every file marked `replace` or `remove`.
  - Diff against your current files if you customized any agent rules.

Recommended follow-ups:
  1. Review docs/STYLE.md, docs-meta/runbook.md, and any *-rules.md files you had customized.
     Diff against _claude_backup/<target_version>-upgrade/ to see what was overwritten.
  2. If CLAUDE.md is preserved, manually sync any wanted changes from the new template
     (visible at https://github.com/ablack13/p-3-fenix/blob/main/templates/CLAUDE.md).
  3. Run /clear to drop the old context. The next session will load the upgraded
     commands and agents.
```

### Notes

- The upgrade overwrites `.claude/commands/fx-init.md` itself during execution. The in-flight invocation is unaffected (its instructions are already in context), but subsequent `/fx-init upgrade` calls will use the new version's behavior.
- If the kit ships no `scripts/upgrades/<installed>-to-<target>.json`, the installer fails fast rather than silently merging. Multi-step upgrades (e.g. 3.1.0 → 3.3.0) require the kit author to chain transitions in `install-online.sh` or to ship a direct upgrade JSON.
- `/fx-uninstall` removes Fenix entirely after an upgrade — it does not revert to the previous version. Manually copy from `_claude_backup/<version>-upgrade/` if you need pre-upgrade content.
