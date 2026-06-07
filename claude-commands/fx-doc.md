# /fx-doc — Documentation operations

Action requested: $ARGUMENTS

Dispatch based on the first word of $ARGUMENTS.

The `audit` and `update` flows are **delta-gated**: they spawn a `module-auditor`
only for modules whose documented sources actually changed since the docs were last
reviewed, or that still hold unfilled stubs. Every other module is settled from a
cheap cache — a single `git log` pass over recorded source lists — without reading
any wing prose or source code. See **The cache and the delta gate** below; both
`audit` and `update` begin there.

---

## The cache and the delta gate

`docs-meta/.fenix-cache.json` is a derived index of every room/drawer/wing-README
frontmatter. It exists for one reason: let the orchestrator decide *which modules to
audit* from one cheap pass, instead of spawning a per-module subagent that each reads
a whole wing just to conclude "nothing changed."

Schema:

```json
{
  "generated_at": "<timestamp>",
  "head_commit": "<sha>",
  "docs": {
    "modules/feature/practice/docs/rooms/persistence.md": {
      "documents": ["modules/feature/practice/src/.../Db.kt"],
      "last_reviewed_commit": "ab12cd3",
      "is_stub": false
    }
  }
}
```

### Step C1 — Load or build the cache (cheap, read-only)

1. If `docs-meta/.fenix-cache.json` is missing, or `--rebuild-cache` was passed:
   **build it inline** — no subagents, no source reads:
   - `Glob` every `**/docs/rooms/*.md`, `**/docs/drawers/*.md`, `**/docs/README.md`
     (for modules in `settings.gradle.kts`), and `reference/**/*.md`.
   - For each, read **frontmatter only** (`documents:`, `last_reviewed_commit:`) and
     `Grep` the body for strong stub markers (`<2-4 sentences on...>`, `<facts>`,
     `<ComponentName>`, `<purpose, behavior>`, `<verbatim public API`, empty/folder
     `documents:`). Set `is_stub` accordingly.
   - Record `head_commit` = `git rev-parse --short HEAD` and `generated_at`.
   - Write the file. **The first time you create it, add a manifest entry**
     `{action: "create", path: "docs-meta/.fenix-cache.json"}` so `/fx-uninstall`
     removes it.
   This pass reads frontmatter + greps — never prose or code. It is the only
   doc-touching work the orchestrator does, and it is cheap.
2. Otherwise load the existing cache.

### Step C2 — Compute the delta gate (per-doc, against each doc's own commit)

For each cached doc, ask the one cheap question the metadata exists to answer:

- `git log <doc.last_reviewed_commit>..<HEAD_REF> --oneline -- <doc.documents:>`
  (default `<HEAD_REF>` is `HEAD`). If it returns ANY commit, the doc is **delta-stale**
  — its sources moved since *it* was last reviewed. The gate is per doc, against that
  doc's own `last_reviewed_commit` — **not** a single global PR range. Only `git log`
  over recorded source paths runs; no prose or code is read.
- A doc **absent from the cache** (e.g. a module just added by `/fx-init`) is treated
  as unknown → its module is in scope, and the doc is added on the next build.
- A module is **in scope** when it owns at least one delta-stale doc OR a doc with
  `is_stub: true`. Everything else is **out of scope** and gets no auditor.
- `--stubs-only` gates on `is_stub` alone and skips the staleness `git log` pass.

> Why per-doc and not `git diff main..HEAD`: a doc can be stale because its sources
> changed in a commit that is *already on main* (before the current range) — a global
> range would miss it. Each doc's `last_reviewed_commit` is the only correct base.

### Step C3 — Escape hatches (override the gate)

- `--all` — ignore the gate; audit every module in `settings.gradle.kts` (the old
  pre-3.2.0 behavior). Use for a full re-audit after large refactors.
- `--only <module>` — restrict scope to exactly one module, gate or not.
- `--rebuild-cache` — re-sync the cache to current on-disk frontmatter before gating
  (refreshes `is_stub` / `last_reviewed_commit` / `documents:` from each doc). It does
  **not** invent sources a `documents:` list omits — it only mirrors what the
  frontmatter says.

> The gate is only as accurate as each doc's `documents:` list. A source file missing
> from `documents:` will not register as a change, and `--rebuild-cache` won't recover
> it (it re-reads the same incomplete list). Fix the doc's `documents:`, then rebuild —
> or use `--all` to audit regardless of the gate.

---

## If $ARGUMENTS starts with `audit`

Run **Phase 1 audit only** — read-only, produces a report. No writes to docs (the
cache is the only file written, and only when missing/rebuilt).

Steps:

1. Read `docs/info.md` (authoritative context).
2. Read `docs/hint_index_map.md` (current topology).
3. Determine `HEAD_REF` — the staleness upper bound. Default `HEAD`. If the user passed
   a range (`/fx-doc audit develop..HEAD`), use its right side as `HEAD_REF` and keep
   the left as `BASE_REF` for the report; the staleness gate itself is per-doc (each
   doc's own `last_reviewed_commit`), not the range.
4. **Run the cache + delta gate** (Steps C1–C3). This yields the in-scope module set
   and, per module, the list of delta-stale docs and stub docs.
5. For **each in-scope module only**, spawn the **`module-auditor`** subagent in
   parallel via Task with `subagent_type=module-auditor`. Pass:
   ```
   {
     module_name: <name>,
     module_path: <path>,
     proposal_path: "docs/_pending/audit-<timestamp>/<module-name>.md",
     BASE_REF, HEAD_REF,
     stub_docs:  [<wing-relative doc paths flagged is_stub in cache>],
     stale_docs: [{path, documents, last_reviewed_commit}, ...],
     suggest_drawers: <true only if --suggest-drawers was passed; default false>
   }
   ```
   The auditor fills only the listed stubs and, for staleness, reads only
   `git diff <last_reviewed_commit>..HEAD -- <documents:>` — not the whole `src/`.
   It walks `src/` for new drawers only when `suggest_drawers` is true. Writes a
   proposal file.

   Modules gated out get **no auditor**. List them in the report as
   "up to date (cache)".

6. **Scan `reference/` for unlinked files.** For each `.md` file under `reference/`
   (recursive) lacking frontmatter or not in `hint_index_map.md`, spawn
   **`reference-linker`** via Task. Pass file path, current index, current
   task-router. Linker writes proposals to
   `docs/_pending/audit-<timestamp>/references/<filename>.md`.

7. Synthesize the audit report. Save to `docs/_pending/audit-<timestamp>.md` with:
   - Summary: modules in scope vs. gated out (cache), stubs found, stale rooms,
     stale drawers, stale references, new drawers warranted, unlinked references.
   - Per-module proposals (paths to per-module proposal files).
   - Reference linkage proposals (paths).
   - Index changes needed.

8. Print summary, point to the report, stop. Wait for human approval.

```
/fx-doc audit complete

  Modules in scope:    K  (delta-stale or holding stubs)
  Gated out (cache):   N-K  (sources unchanged, no stubs)
  Stubs found:         …
  Stale docs:          …  (rooms: …, drawers: …, references: …)
  Unlinked references: …

Report: docs/_pending/audit-<timestamp>.md
Reply 'approved' to apply via /fx-doc update, or send corrections.
```

---

## If $ARGUMENTS starts with `update`

Full sweep: Phase 1 audit (delta-gated, as above) + Phase 2 plan + Phase 3 update.

`update --only <module>` is the **targeted** form: audit + update exactly one module,
regardless of the gate. Reach for it when you knowingly want one doc refreshed. Plain
`update` audits only the in-scope set; it never re-audits the whole repo unless you
pass `--all`.

1. Run the audit phase as above (cache gate, stub detection, staleness, reference
   linker proposals). With `--only <module>`, scope to that module.
2. Stop and wait for `approved` or corrections.
3. On approval, finalize plan to `docs/_pending/plan-<timestamp>.md` reflecting any
   human edits.
4. Execute Phase 3 serially:
   - `TodoWrite` one todo per stub-fill + per stale doc + per unlinked reference.
   - **For each stub-fill proposed:**
     - Read the proposed content from the auditor's proposal file.
     - Apply to the actual room/drawer/wing-README.
     - Update frontmatter `documents:` with the auditor's proposed source list.
     - Bump `last_reviewed_commit` to current HEAD, update date.
     - Add manifest entry: `{action: "stub-fill", path, source_proposal, timestamp}`.
     - **Update the cache**: set this doc's `is_stub: false`, `documents:` to the new
       list, `last_reviewed_commit` to HEAD.
   - **For each stale (non-stub) doc:**
     - Apply edits per auditor proposal (the proposal was built from
       `git diff <last_reviewed_commit>..HEAD`, not a whole-wing re-read).
     - Bump frontmatter `last_reviewed_commit` + date.
     - Update `hint_index_map.md` if structural changes occurred.
     - **Update the cache**: bump this doc's `last_reviewed_commit` to HEAD.
   - **For each unlinked reference being linked:**
     - Stamp proposed frontmatter on the file.
     - Add entry to `hint_index_map.md` `## Reference docs` section.
     - Update `task-router.md` for each `applies_to_categories`.
     - Add manifest entry: `{action: "reference-link", path, timestamp}`.
     - **Update the cache**: add the reference doc entry.
   - Re-validate `hint_index_map.md` integrity.
5. Refresh `docs/task-router.md` if room set changed.
6. Update the cache's `head_commit` + `generated_at` to the post-update HEAD.
7. Move audit + plan reports from `docs/_pending/` to `docs/_history/`.
8. Print summary:
   ```
   /fx-doc update complete

     Modules audited:     K (gated out: N-K)
     Stubs filled:        N
     Stale docs updated:  N (rooms: N, drawers: N, references: N)
     References linked:   N
     Index updates:       N
     task-router.md:      refreshed (N categories) | unchanged
     Cache:               docs-meta/.fenix-cache.json refreshed
   ```

---

## If $ARGUMENTS starts with `freshness`

The **routine "what's stale"** command. Read-only, git-log only — **never reads code
or prose**. This is the cheap default to run often; reach for `update --only <module>`
when you actually want a doc refreshed.

Spawns **`freshness-scanner`** via Task. No diff range, no stub fills — just the
per-doc `git log` staleness check plus index integrity. If a cache is present
(Step C1), pass its path so the scanner can use recorded `documents:` /
`last_reviewed_commit` instead of re-reading every frontmatter.

Output the scanner's report directly to the user. Don't save to `docs/_pending/`
(informational only).

---

## If $ARGUMENTS is empty or unrecognized

Print:

```
Usage: /fx-doc <action> [args]

Actions:
  freshness             Cheap, routine staleness check (git log only — reads no
                        code). Run this often.
  audit [base..head]    Phase 1 audit. Read-only. Delta-gated: audits only modules
                        whose sources changed or that hold stubs. Default: main..HEAD.
  update [base..head]   Full audit + plan + update sweep. Fills stubs, updates stale
                        docs, auto-links references — all gated by Phase 2 approval.

Flags:
  --only <module>       Audit/update exactly one module (the targeted, expensive
                        path). Use when you knowingly want one doc refreshed.
  --all                 Ignore the delta gate; audit every module (full re-audit).
  --rebuild-cache       Re-sync docs-meta/.fenix-cache.json to on-disk frontmatter
                        before gating.
  --suggest-drawers     Let auditors walk src/ for new high-value drawers (off by
                        default — it's the expensive scan).
  --stubs-only          Gate on stubs only; skip the per-doc staleness git-log pass.

Staleness gating (per-doc git log since each doc's last_reviewed_commit) is intrinsic
to the gate and always on — it's cheap. For a standalone read-only staleness report,
use the `freshness` action.

See docs-meta/runbook.md for full details.
```
