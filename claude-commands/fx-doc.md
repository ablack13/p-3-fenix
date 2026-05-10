# /fx-doc — Documentation operations

Action requested: $ARGUMENTS

Dispatch based on the first word of $ARGUMENTS.

---

## If $ARGUMENTS starts with `audit`

Run **Phase 1 audit only** — read-only, produces a report. No writes to docs.

Steps:

1. Read `docs/info.md` (authoritative context).
2. Read `docs/hint_index_map.md` (current topology).
3. Determine `BASE_REF` and `HEAD_REF`. Default `main..HEAD`. If user passed args (`/fx-doc audit develop..HEAD`), parse them. Confirm with user if ambiguous.
4. Run `git diff <BASE_REF>..<HEAD_REF> --stat` and group by module.
5. For each module — whether touched by the diff OR existing in settings.gradle.kts (to catch stubs in untouched modules) — spawn the **`module-auditor`** subagent in parallel via Task with `subagent_type=module-auditor`. Pass:
   ```
   {
     module_name: <name>,
     module_path: <path>,
     proposal_path: "docs/_pending/audit-<timestamp>/<module-name>.md",
     BASE_REF, HEAD_REF
   }
   ```
   Each auditor detects stubs AND stale docs in one pass. Writes a proposal file.

6. **Scan `reference/` for unlinked files.** For each `.md` file under `reference/` (recursive) lacking frontmatter or not in `hint_index_map.md`, spawn **`reference-linker`** via Task. Pass file path, current index, current task-router. Linker writes proposals to `docs/_pending/audit-<timestamp>/references/<filename>.md`.

7. Synthesize the audit report. Save to `docs/_pending/audit-<timestamp>.md` with sections:
   - Summary: stubs found, stale rooms, stale drawers, stale references, new drawers warranted, unlinked references.
   - Per-module proposals (paths to per-module proposal files).
   - Reference linkage proposals (paths).
   - Index changes needed.

8. Print summary, point to the report, stop. Wait for human approval.

---

## If $ARGUMENTS starts with `update`

Full sweep: Phase 1 audit + Phase 2 plan + Phase 3 update.

1. Run audit phase as above. Includes stub detection, staleness, and reference linker proposals.
2. Stop and wait for `approved` or corrections.
3. On approval, finalize plan to `docs/_pending/plan-<timestamp>.md` reflecting any human edits.
4. Execute Phase 3 serially:
   - `TodoWrite` one todo per stub-fill + per affected module + per stale doc + per unlinked reference.
   - **For each stub-fill proposed:**
     - Read the proposed content from the auditor's proposal file.
     - Apply to the actual room/drawer/wing-README.
     - Update frontmatter `documents:` with the auditor's proposed source list.
     - Bump `last_reviewed_commit` to current HEAD, update date.
     - Add manifest entry: `{action: "stub-fill", path, source_proposal, timestamp}`.
   - **For each module's stale-doc updates:**
     - Re-read wing fresh.
     - Apply edits per auditor proposal.
     - Bump frontmatter timestamps.
     - Update `hint_index_map.md` if structural changes occurred.
   - **For each stale-only doc** (no PR-driven change, just freshness): re-stamp or update per proposal.
   - **For each unlinked reference being linked:**
     - Stamp proposed frontmatter on the file.
     - Add entry to `hint_index_map.md` `## Reference docs` section.
     - Update `task-router.md` for each `applies_to_categories`.
     - Add manifest entry: `{action: "reference-link", path, timestamp}`.
   - Re-validate `hint_index_map.md` integrity.
5. Refresh `docs/task-router.md` if room set changed.
6. Move audit + plan reports from `docs/_pending/` to `docs/_history/`.
7. Print summary:
   ```
   /fx-doc update complete
   
     Stubs filled:        N
     Stale docs updated:  N (rooms: N, drawers: N, references: N)
     References linked:   N
     Index updates:       N
     task-router.md:      refreshed (N categories) | unchanged
   ```

---

## If $ARGUMENTS starts with `freshness`

Standalone staleness scan. Spawns **`freshness-scanner`** via Task. No PR-driven delta. No stub fills.

Output the scanner's report directly to the user. Don't save to `docs/_pending/` (informational only).

---

## If $ARGUMENTS is empty or unrecognized

Print:

```
Usage: /fx-doc <action> [args]

Actions:
  audit [base..head]    Phase 1 audit. Read-only. Detects stubs + staleness +
                        unlinked references. Default: main..HEAD.
  update [base..head]   Full audit + plan + update sweep. Fills stubs, updates
                        stale docs, auto-links references — all gated by Phase 2.
  freshness             Global staleness check only.

Flags:
  --skip-freshness      Skip the global staleness pass during audit/update
                        (still does stub detection).
  --stubs-only          Only detect/fill stubs; skip staleness check.

See docs-meta/runbook.md for full details.
```
