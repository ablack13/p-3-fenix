# /fx-uninstall — Remove all Fenix files

Manifest-driven removal of every file Fenix created in this repo. Restores any pre-existing files that were moved into `_claude_backup/` during install.

## Steps

### Step 1: Read the manifest

Read `.fenix-manifest.json` at repo root.

If missing, abort with:
```
⚠ No .fenix-manifest.json found.

Either:
- Fenix was never installed in this repo.
- The manifest was deleted manually.
- A pre-manifest install (very early Fenix versions).

For pre-manifest installs, manual cleanup is required. The typical v4 paths to remove are:
  - .claude/commands/fx-*.md
  - .claude/agents/{architect,worker,tester}*.md
  - .claude/rules/{git-workflow,fenix-conventions}.md (+ generated per-module rules)
  - docs/info.md, docs/DISCLAIMER.md
  - tasks/
  - docs-meta/
  - CLAUDE.md (only the Fenix one)
  - "P-3 (Fenix)- READ BEFORE FIRST.md"
  - .fenix-manifest.json
  (Legacy 3.x installs additionally: .claude/agents/{module-*,freshness-*,reference-*}*.md,
   _topology.md, docs/STYLE.md, docs/hint_index_map.md, docs/task-router.md,
   docs/_pending/, docs/_history/, reference/, <module>/docs/ wings.)

If `_claude_backup/` exists, manually move its contents back:
  mv _claude_backup/CLAUDE.md ./CLAUDE.md
  mv _claude_backup/.claude   ./.claude
  rm -rf _claude_backup
```

### Step 2: Walk the manifest in reverse order

For each entry in `.fenix-manifest.json` `actions` array, processed in REVERSE order:

#### action: `create`
File or folder Fenix created. Mark for removal.

#### action: `create-dir`
Directory Fenix created. Mark for removal (only if empty after `create` removals).

#### action: `modify`
File Fenix modified (e.g., CLAUDE.md placeholders populated). For uninstall:
- If a `backup-move` entry restores the pre-Fenix version → that restore handles it.
- Otherwise, mark for removal too (Fenix created it from scratch, modified later).

#### action: `backup-move`
A pre-existing user file/folder was moved into `_claude_backup/` during install. Mark for **restore**: at execution time, move `_claude_backup/<to>` back to `<path>` (the original repo-relative location).

If the destination already exists when restore runs (e.g. Fenix-managed `.claude/` was not fully removed yet), abort with a clear error — restore must run *after* Fenix `create` entries have been removed in this same run (see Step 4 ordering).

#### action: `rename-on-install` *(legacy, pre-3.0.0 installs only)*
Old quarantine flow that renamed `CLAUDE.md` → `CLAUDE.md.old` with a disclaimer. For these legacy manifests:
- Read the `.old` file, strip the disclaimer header (everything from start through the `# IGNORE-FROM-HERE-DOWN` marker line), write back to original path.
- Delete the `.old` file.
This branch is kept for backward compatibility only; new installs (3.0.0+) use `backup-move`.

#### action: `upgrade-replace` *(3.1.0+)*
A kit-owned file was overwritten during an upgrade. The pre-upgrade copy was moved to `backup_path` (under `_claude_backup/<version>-upgrade/`). For uninstall:
- Mark the live file for removal (same as `create`).
- Leave the backup copy in place. Do **not** auto-restore — uninstall removes Fenix entirely; users wanting pre-upgrade state should restore manually from `_claude_backup/<version>-upgrade/` before running uninstall, or copy out specific files after.

#### action: `upgrade-remove` *(3.1.0+)*
A file removed during an upgrade. The file was moved to `backup_path`. For uninstall:
- Nothing to remove (already gone from live tree).
- Leave the backup in place. Same manual-recovery note as `upgrade-replace`.

#### action: `stub-fill` *(legacy — 3.x manifests only)*
Auditor wrote real prose into a stub. The stub-filled doc is preserved (it has user value). Don't mark for removal — those are scaffold files Fenix created. (In repos upgraded to 4.0.0, these docs were already swept into `_claude_backup/4.0.0-upgrade/`.)

#### action: `reference-link` *(legacy — 3.x manifests only)*
Reference file was linked. The reference file itself was created by the user; Fenix only added frontmatter and an index entry. On uninstall:
- Don't delete the reference file.
- Strip the Fenix frontmatter from it (revert to plain markdown).
- Note in the report.

#### action: `create-task`
Task folder was created in `tasks/`. These contain user work — preserve by default, warn user.

### Step 3: Preflight — preview and warn

Before deleting anything, build a report:

```
/fx-uninstall preview

Files to be REMOVED (created by Fenix):
  .claude/commands/fx-init.md
  .claude/commands/fx-task.md
  .claude/rules/git-workflow.md
  ... (full list)

Files to be RESTORED from _claude_backup/:
  CLAUDE.md   ← _claude_backup/CLAUDE.md
  .claude/    ← _claude_backup/.claude/

(Legacy v3.0.0 manifests only:)
Files to be RESTORED from CLAUDE.md.old:
  CLAUDE.md   ← CLAUDE.md.old (disclaimer stripped)

Files Fenix MODIFIED but won't auto-revert (no pre-Fenix backup):
  (none)

User content detected in Fenix-managed locations:

  .claude/rules/practice.md (Fenix-created, then edited by user — N changes)
  tasks/2026-05-08-skip-button/ (active task, status=open)

⚠ Removing the above will lose your work.

To preserve content before uninstall, run one of:

  Option A — Stash with git:
    git stash push -- .claude/rules/practice.md \
                      tasks/2026-05-08-skip-button/

  Option B — Copy to a backup folder:
    mkdir -p ~/fenix-uninstall-backup-$(date +%Y%m%d)
    cp -r .claude/rules/practice.md \
          tasks/2026-05-08-skip-button/ \
          ~/fenix-uninstall-backup-$(date +%Y%m%d)/

  Option C — Selective preservation:
    Just don't list those paths in the next confirmation. Pass them via the
    --keep flag (see usage below).

Restore option (after uninstall, if you stashed):
    git stash pop

⚠ If `_claude_backup/` was modified after install (compare mtimes against the
manifest's installed_at timestamp), warn the user before restoring — their
edits will become the live `CLAUDE.md` / `.claude/`.

Proceed with uninstall?

  1. Yes — proceed.
  2. No, let me back up first.
  3. Cancel.
```

Detection logic for "user content":
- Rules files: check git history. If commits exist for a `.claude/rules/*.md` file AFTER its `create` manifest entry's timestamp, the user has edited it — their invariants live there.
- CLAUDE.md map block: content between the FENIX:MAP markers is regenerable, but content the user added outside the markers is user content (the backup-move restore covers the pre-Fenix file; hand edits since install are flagged via git history).
- Tasks: any task folder where `outcome.md` doesn't exist (or status != closed) is "active." Closed tasks are historical record but still user content.
- Legacy 3.x manifests: stub-filled docs and Fenix-linked reference files follow the legacy sections above.
- `_claude_backup/` edits: best-effort `find _claude_backup -newer .fenix-manifest.json` heuristic.

### Step 4: Execute removal

After developer chooses option 1, **process in this order**:

1. **Remove Fenix-created files first.** Walk manifest in reverse. For each `create` and `modify` (where no later `backup-move` restores it): delete the file. For each `create-dir`: `rmdir` if empty.
2. **Restore backups second.** For each `backup-move` entry: `mv _claude_backup/<to>` back to `<path>`. Order matters — destination paths (`CLAUDE.md`, `.claude/`) must already be free from step 1.
3. **Restore legacy quarantine** (only if `rename-on-install` entries exist): read `CLAUDE.md.old`, strip header through `# IGNORE-FROM-HERE-DOWN`, write to `CLAUDE.md`, delete `.old`.
4. **Strip reference-linker frontmatter** *(legacy 3.x manifests only)*. For each `reference-link`: read the reference file, strip the `---…---` block Fenix added, write back. Don't delete the file itself.
5. **Clean up `_claude_backup/`.** After all `backup-move` restores succeed, delete `_claude_backup/IGNORE_THIS_FOLDER.md` and `_claude_backup/.claudeignore`. `<version>-upgrade/` archives (upgrade backups — after a 4.0.0 upgrade this includes the swept docs) are intentionally kept: leave the folder in place and note it in the report. Only `rmdir _claude_backup/` when it is actually empty.
6. **Update manifest as we go** so partial uninstall can resume.
7. **Last step:** delete `.fenix-manifest.json`.

### Step 5: Final report

```
/fx-uninstall complete

Removed:                N files, K folders
Restored from backup:   J files/folders (CLAUDE.md, .claude/, …)
Frontmatter stripped:   M reference files

_claude_backup/: deleted | kept (<version>-upgrade/ archives remain — delete manually when no longer needed)
Manifest deleted.

If you backed up content before uninstall, restore it now (e.g., git stash pop).

Fenix is fully uninstalled. To re-install, run scripts/setup.sh again.
```

---

## Flags

```
/fx-uninstall                 Interactive — full preflight, confirm before removing.
/fx-uninstall --dry-run       Show preflight, don't actually remove anything.
/fx-uninstall --keep <path>   Exclude a path from removal (can be repeated).
/fx-uninstall --force         Skip preflight warnings. Use with care.
```

---

## Constraints

- Manifest is the source of truth. Don't try to detect Fenix files heuristically. If the manifest is missing or malformed, abort.
- `tasks/` content is always treated as user content. Never auto-delete without explicit confirmation.
- User-edited `.claude/rules/*.md` files are user content — warn before removing.
- Legacy 3.x: stub-filled docs the user edited are user content; reference files are user content, only Fenix frontmatter gets stripped.
- `_claude_backup/` is restored, not deleted-and-lost. If a destination already exists at restore time, abort rather than overwrite.
- Legacy `CLAUDE.md.old` flow: strip the disclaimer header before restoring. Marker line `# IGNORE-FROM-HERE-DOWN` is the cutoff — everything above it is the Fenix-added quarantine notice; everything below is the original file content. Kept for backward compatibility with pre-3.0.0 manifests only.
- Never delete `.git/`, never touch git history.
