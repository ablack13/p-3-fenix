# /fx-init — Generate the repo map + scaffold rules

Bootstrap or refresh the P-3 v4 context system: the repo map inside `CLAUDE.md`, the `.claude/rules/` files, and `docs/info.md`. Idempotent — safe to re-run; a re-run refreshes the map and fills gaps, never overwrites user content.

## Modes

- `/fx-init` — bootstrap or refresh (default). Phases 0–4 below.
- `/fx-init upgrade [version]` — update the installed Fenix kit. Reads `.fenix-manifest.json`, queries GitHub for the latest release (or uses the pinned version), and runs `install-online.sh` to apply the upgrade JSON. See "Upgrade mode" at the end of this file.

If the first argument is `upgrade`, jump straight to "Upgrade mode" and skip the bootstrap phases below.

## Phase 0 — Pre-flight (read-only)

1. Verify `CLAUDE.md` exists at repo root. If missing, abort and tell the user to run `scripts/setup.sh` (from the unzipped `p3-fenix-<version>/` distribution) first.

2. Check `CLAUDE.md`:
   - Locate the `<!-- FENIX:MAP:START` / `<!-- FENIX:MAP:END -->` markers.
     - Both present → map will be regenerated between them (refresh).
     - Missing (hand-edited or pre-4.0.0 file) → flag: the whole `## Repo map` section (with markers) will be appended; nothing else in the file is touched.
   - Has placeholder sections (`<!-- Filled in by /fx-init`, empty `## Stack` / `## Local environment`) → flag for population in Phase 4.

3. Check `.claude/rules/`:
   - `git-workflow.md` / `fenix-conventions.md` missing → flag (they ship with setup.sh; recreate from `docs-meta/templates/` copies if absent).
   - Note which per-module rules files already exist — existing ones are NEVER touched.

4. Check `docs/info.md`:
   - Missing → flag for first-time draft in Phase 4.
   - Present and customized → leave alone.
   - Present but matches the template (still has `<one-line summary...>` placeholder) → flag for first-time draft.

5. Check `tasks/` folder: missing → flag for creation in Phase 4.

6. Check `.fenix-manifest.json`:
   - Missing → first-time install or pre-manifest install. Will be created in Phase 4 listing all files Fenix manages.
   - Present → read it. Phase 4 will only append entries, not regenerate from scratch.

## Phase 1 — Discover

1. Print current state from Phase 0 detection.

2. Read `docs/info.md` if customized (authoritative context).

3. Discover modules from `settings.gradle.kts` (or equivalent manifest for non-Gradle projects). Run:
   ```
   grep -E "^include" settings.gradle.kts
   ```
   This is canonical. Don't directory-scan.

4. **Spawn ONE repo-scan subagent via the Task tool** (`subagent_type=general-purpose`). Pass the module list and this instruction:

   > For each module, inspect its build file and top-level source packages only — do NOT read implementation code. Return four markdown sections, total under 120 lines:
   > `### Modules` — one line per module: name, path, one-phrase purpose.
   > `### Entry points (where to start reading)` — subsystem → folder/file to open first (DI modules, DB schema, network clients, UI roots).
   > `### Cross-cutting facts` — the few always-true facts: DI framework, DB, networking, threading rules, analytics/crash tooling. Facts, not prose.
   > `### When you need X, look here` — 6–12 task-type → path lines covering the likely work areas.

   **HARD RULE:** the scan runs in a subagent. If the main agent finds itself reading `build.gradle.kts` files during Phase 1, it has violated this rule — STOP, restart via subagent dispatch. Reasoning: the scan pollutes the main context with N modules of detail; only the distilled map should come back.

5. Sanity-check the returned map: every module from step 3 appears; no invented paths (spot-check 2–3 with `ls`); under ~120 lines.

## Phase 2 — Plan

Output the plan. Stop. Wait for human approval.

Include:
- The generated map content (full text — it's short).
- Whether markers exist (refresh in place) or the section will be appended.
- Suggested per-module rules files (only for modules with real invariants worth stating — suggest, don't spam). Existing rules files listed as "kept as-is".
- Whether `docs/info.md` will be drafted.
- Whether `CLAUDE.md` placeholders (`Stack`, `Local environment`) will be populated.
- Whether `tasks/` will be created.

## Phase 3 — Write the map + rules

On approval:

1. **Map:** replace everything between `FENIX:MAP:START` and `FENIX:MAP:END` in `CLAUDE.md` with the approved content. If markers are missing, append the full `## Repo map — ALWAYS navigate from here` section (markers included) at the end of `CLAUDE.md`. Never touch content outside the markers.
   Manifest entry: `{action: "modify", path: "CLAUDE.md", phase: "init", changes: "repo map refresh"}`.
2. **Always-on rules:** if `git-workflow.md` or `fenix-conventions.md` is missing from `.claude/rules/`, copy it from `docs-meta/templates/rules-*.md`. Manifest entry per created file. Never overwrite existing ones.
3. **Per-module rules:** for each APPROVED suggestion, instantiate `docs-meta/templates/rules-module.md` as `.claude/rules/<module-name>.md` with real `paths:` globs and 3–5 real invariants (from the scan). Manifest entry per file. Skip modules the developer rejected.

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
2. Populate `## Local environment` with sensible defaults.
3. Show the diff. Apply edits if requested. Save.
4. Manifest entry: `{action: "modify", path: "CLAUDE.md", phase: "init", changes: "populated placeholders"}`.

DO NOT replace the bootstrap protocol, task navigation rule, slash commands list, or subagents list.

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
  "fenix_version": "4.0.0",
  "installed_at": "<timestamp>",
  "actions": [
    {"action": "create", "path": "CLAUDE.md", "phase": "install"},
    {"action": "backup-move", "path": "CLAUDE.md", "to": "_claude_backup/CLAUDE.md", "phase": "install"},
    {"action": "create", "path": ".claude/rules/git-workflow.md", "phase": "install"},
    {"action": "modify", "path": "CLAUDE.md", "phase": "init", "changes": "repo map refresh", "timestamp": "..."},
    {"action": "create", "path": ".claude/rules/shared-core.md", "phase": "init", "timestamp": "..."},
    ...
  ]
}
```

## Non-destructive guarantees

- Map regeneration touches ONLY the text between `FENIX:MAP:START` and `FENIX:MAP:END`.
- Content outside the markers is user-owned — never rewritten (placeholder fills excepted).
- Existing `.claude/rules/*.md` files are never overwritten or deleted.
- `info.md` customized → never touch.
- `tasks/` content untouched on re-run.
- Manifest never deletes entries; only appends.

## Rules policy

DO NOT auto-generate a rules file per module. Suggest candidates in Phase 2; create only what the developer approves. A rules file with nothing real to say is context noise.

## Final output

```
/fx-init complete

Repo map: refreshed in place / appended (markers were missing) — <N> modules, <M> map lines
Always-on rules: git-workflow.md, fenix-conventions.md — present / created
Per-module rules created: <list or "none">   (existing files kept as-is: <list>)

CLAUDE.md placeholders populated: yes/no
info.md: drafted / left untouched
tasks/: created / already present
Manifest: .fenix-manifest.json (<entry-count> entries total)

Next: skim the map section in CLAUDE.md and the generated rules — edit freely,
/fx-init never overwrites your edits. Re-run /fx-init after big structure
changes to refresh the map.
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

3. If a target version was passed (`/fx-init upgrade 4.0.0`), use it as `target_version`. Otherwise resolve the latest release tag:
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
   git status --porcelain -- .claude/ docs-meta/ CLAUDE.md "P-3 (Fenix)- READ BEFORE FIRST.md" 2>/dev/null
   ```
   If output is non-empty, surface it and ask the developer to either commit, stash, or explicitly confirm before continuing — `upgrade-replace` will back up the current copies but overwriting uncommitted work is irreversible without `git stash`.

### Phase B — Plan

Print the upgrade plan:

```
Fenix upgrade plan

Current: <installed_version>
Target:  <target_version>

Strategy:
  - Replace kit-owned files (agent definitions, slash commands, runbook, workflow templates).
  - Preserve user content (CLAUDE.md outside managed markers, docs/info.md,
    your edits to .claude/rules/ — see the upgrade JSON for exceptions).
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
  1. Review docs-meta/runbook.md and any *-rules.md files you had customized.
     Diff against _claude_backup/<target_version>-upgrade/ to see what was overwritten.
  2. If CLAUDE.md is preserved, manually sync any wanted changes from the new template
     (visible at https://github.com/ablack13/p-3-fenix/blob/main/templates/CLAUDE.md).
  3. Run /clear to drop the old context. The next session will load the upgraded
     commands and agents.
```

### Notes

- The upgrade overwrites `.claude/commands/fx-init.md` itself during execution. The in-flight invocation is unaffected (its instructions are already in context), but subsequent `/fx-init upgrade` calls will use the new version's behavior.
- If the kit ships no `scripts/upgrades/<installed>-to-<target>.json`, the installer fails fast rather than silently merging. Multi-step upgrades (e.g. 3.1.0 → 4.0.0) require upgrading through an intermediate kit first, unless a direct upgrade JSON is shipped.
- `/fx-uninstall` removes Fenix entirely after an upgrade — it does not revert to the previous version. Manually copy from `_claude_backup/<version>-upgrade/` if you need pre-upgrade content.
