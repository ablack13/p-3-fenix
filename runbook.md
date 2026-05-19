# Docs Runbook — P-3 (Fenix) 3.1.0

Codename: **Fenix**

Single self-contained runbook. Paste the whole file into Claude Code after a multi-module change has landed, or trigger specific commands (`/init`, `/info`) when needed.

---

## Before you post — fill these

- `BASE_REF` = <git ref before the change — tag, branch, or `main~N`>
- `HEAD_REF` = <usually `HEAD`>
- `INDEX_FILE` = `docs/hint_index_map.md`
- `INFO_FILE` = `docs/info.md`

---

## Mission

Maintain project documentation in wings/rooms/drawers decentralized topology. Three top-level operations:

- **`/init`** — bootstrap structure when missing or partial. Idempotent.
- **`/info`** — read-only status check.
- **Audit + update sweep** — the default flow when you paste this runbook after a change.

All three share the same three-phase shape: Discover/Audit → Plan → Execute. Hard stop between phases for human review.

---

## Upgrades

Three entry points, all converging on the same upgrade logic:

- `/fx-init upgrade [version]` — from inside Claude Code. Reads the manifest, resolves the latest release tag (or accepts a pinned version), shows a plan, and invokes `install-online.sh` on approval. The simplest path on 3.1.0+ installs.
- `curl -fsSL …/install-online.sh | bash` — from a shell.
- `./scripts/setup.sh` from a manually-extracted kit zip — equivalent.

All three detect an existing install from `.fenix-manifest.json` and apply the matching `scripts/upgrades/<from>-to-<to>.json`.

- **replace**: kit-owned files overwritten with the target version. Pre-change copy goes to `_claude_backup/<to>-upgrade/<path>` and is recorded as `upgrade-replace` in the manifest.
- **preserve**: user content (`CLAUDE.md`, `docs/info.md`, `docs/task-router.md`, `docs/hint_index_map.md`) left untouched.
- **create_if_missing**: new files added in the target version, installed only if absent.
- **remove**: files dropped in the target version, moved to the same backup folder and recorded as `upgrade-remove`.

If no upgrade JSON exists for the transition, the installer stops rather than silently merging. Downgrades are refused. `/fx-uninstall` removes Fenix entirely and does not revert upgrades — manually copy from `_claude_backup/<version>-upgrade/` if you need pre-upgrade content.

---

## Topology (wings/rooms/drawers, decentralized)

```
modules/<name>/                  ← module owns its docs
├── src/
├── build.gradle.kts
└── docs/
    ├── README.md                ← wing root
    ├── rooms/                   ← subsystem docs
    └── drawers/                 ← single-concern leaves

docs/                            ← thin shell at repo root
├── hint_index_map.md            ← wayfinding, source of truth for structure
├── info.md                      ← user-owned setup notes
├── STYLE.md                     ← conventions
├── _pending/                    ← audit reports awaiting approval
└── _history/                    ← archived audit reports
```

**Module path prefix** is **not hardcoded**. Modules may live at `modules/<name>/`, repo root, or grouped (`shared/`, `composeApp/`, `iosApp/`). The runbook discovers actual paths from `settings.gradle.kts` `include(":...")` entries.

**Convention:** any module with public surface MUST have at least `docs/README.md`. Internal-only utility modules can skip docs entirely.

---

## Style — AI-optimized

Docs are consumed by AI agents on tasks. Density and scannability over narrative prose.

| Surface | Style |
|---|---|
| Overview | One line: `<Name> — <what>; <key components>` |
| Components / Surface | Verbatim signatures only, no paraphrase |
| Wiring | Bullets, one fact per line, cite `<file>:<line>` when non-obvious |
| Gotchas | Bullets from `// TODO`, `// FIXME`, `// HACK`, `// NOTE:`, `// IMPORTANT:`, `@Deprecated`. Cite source. `(none)` if empty |
| Section headers | Greppable English |
| Cross-ref links | Standard markdown |

No narrative paragraphs in wing READMEs, rooms, or drawers. No emojis. No drive-by rewrites. Minimum-diff edits.

**File size — hard cap 70 lines** per wing README, room, or drawer (counting frontmatter and code blocks). Over cap → wing README becomes a thin index; per-component drawers absorb detail. See `templates/STYLE.md` for the full split policy.

---

## Frontmatter on every room and drawer

```yaml
---
documents:
  - <repo-relative path to source file 1>
  - <repo-relative path to source file 2>
last_reviewed_commit: <short SHA>
last_reviewed_date: <YYYY-MM-DD>
---
```

**Freshness rule:** when any listed source file changes, the doc must be either updated or re-stamped with a new `last_reviewed_commit`. Re-stamping without prose changes is fine — it means "I read the diff, nothing to update." Leaving an old hash on a doc whose source has moved is staleness.

**Re-stamp authority:** anyone touching the module can re-stamp. (Adjust if your team needs stricter rules.)

**Freshness check command:** for each doc with frontmatter, run `git log <last_reviewed_commit>..HEAD -- <file>` for each listed source file. Non-empty output → doc is stale.

---

## `/init` — bootstrap

Trigger: user types `/init`. Use this when a repo has no wings/rooms/drawers structure, partial structure, or new modules without docs.

### Phase 1 — Discover (read-only)

1. Detect current state. Print:
   ```
   docs/                       [present | missing]
   docs/hint_index_map.md      [present | missing]
   docs/info.md                [present | missing]
   docs/STYLE.md               [present | missing]
   Per-module docs             N / M modules documented
   ```
2. Read `INFO_FILE` if present (authoritative context).
3. Discover modules via `cat settings.gradle.kts | grep -E "^include"` — this is canonical. Don't directory-scan.
4. For each module, spawn the **`module-discoverer`** subagent in parallel via `Task` with `subagent_type=module-discoverer`. Pass `{ module_name, module_path }`. The subagent handles dependency signal detection, public surface scanning, and source set detection. See `.claude/agents/module-discoverer.md` for its full contract.
5. Main agent synthesizes structure plan from subagent returns.

### Phase 2 — Plan

Output structure plan as a single markdown document:

```markdown
## Proposed `/init` plan

### Modules detected: N

| Module | Path | Action | Rooms | Drawers suggested |
|---|---|---|---|---|
| core | shared/core/ | NEW WING | di, persistence | CoreModule |
| practice | modules/practice/ | NEW WING | di, ui-android, ui-ios | PracticeModule |
| utils | shared/utils/ | SKIP (internal only) | — | — |
| auth | modules/auth/ | ALREADY HAS DOCS | — | — |

### Files to create

- docs/hint_index_map.md
- docs/info.md (template)
- docs/STYLE.md
- shared/core/docs/README.md
- shared/core/docs/rooms/di.md
- shared/core/docs/rooms/persistence.md
- modules/practice/docs/README.md
- ...

### Files NOT touched (already exist)

- modules/auth/docs/README.md
- ...
```

Stop. Wait for human approval. User can edit the plan inline before approving.

### Phase 3 — Generate

On approval:

1. Create directories.
2. For each file in the approved plan:
   - Use the appropriate template from § Templates below.
   - Fill frontmatter `documents:` with best-guess source files (public surface from Phase 1 discovery).
   - Set `last_reviewed_commit` = `git rev-parse --short HEAD`.
   - Set `last_reviewed_date` = today.
3. Build `hint_index_map.md` from discovered structure with all wings indexed.
4. Generate `info.md` ONLY if it doesn't exist. Use the template — title + summary blockquote + toolchain stub.
5. Print summary:
   ```
   /init complete

   Wings created: N
   Rooms generated: M
   Drawers suggested but NOT created: K (create as needed)
   info.md: created template / left untouched
   hint_index_map.md: created / updated with new wings only
   ```

### Non-destructive guarantees

- `hint_index_map.md` exists → only add new wing entries. Never rewrite existing entries.
- Wing README exists → never overwrite. Mark "already documented" in plan.
- Rooms or drawers exist → never overwrite. Wing with README but no rooms → can offer to add rooms.
- `info.md` exists → never touch. Even if empty.

### Drawer policy

`/init` does NOT auto-generate drawers. They're leaves and grow organically. Phase 2 SUGGESTS high-value drawers (DI entry points, persistence schemas, key public APIs). Creating them is the user's call after init completes.

---

## `/info` — status check

Trigger: user types `/info` or `info`.

Read-only. Doesn't trigger an audit, doesn't load full docs.

Output:

```
P-3 (Fenix) v3.1.0

<summary line from docs/info.md if present>

Topology:    wings/rooms/drawers decentralized (per-module docs/)
Freshness:   enabled
Index:       docs/hint_index_map.md
Setup notes: docs/info.md
Style guide: docs/STYLE.md
Audit log:   docs/_history/

Modules:     N total, M documented (M/N)
Last audit:  <date from latest file in docs/_history/>
```

If repo is uninitialized:

```
P-3 (Fenix) v3.1.0

⚠ Repo not initialized. Run /init to bootstrap wings/rooms/drawers structure.

Detected:
  docs/                 missing
  hint_index_map.md     missing
  info.md               missing
  Per-module docs       0 / N modules
```

If partially initialized, show specifically what's missing.

The summary line comes from the first blockquote in `info.md` (right under the H1 title).

---

## Audit + update sweep — default flow

This is what runs when you paste this runbook into Claude Code without a slash command.

### Phase 1 — Audit (read-only)

Engage plan mode (`shift+tab`). **No edits this phase.**

1. Read `INFO_FILE`. Note any conventions or environment quirks. They override inferences from code.
2. Read `INDEX_FILE` end to end. Build mental map of every wing, room, drawer, xref.
3. Run `git diff <BASE_REF>..<HEAD_REF> --stat`. Group by module.
4. Run `git diff <BASE_REF>..<HEAD_REF> -- <module-path>` for each touched module.
5. **PR-driven delta:** for modules with > ~500 changed lines, spawn the **`module-auditor`** subagent in parallel via `Task` with `subagent_type=module-auditor`. Pass `{ module_name, module_path, BASE_REF, HEAD_REF }`. Smaller modules: handle inline. See `.claude/agents/module-auditor.md` for the subagent's contract.
6. **Global staleness scan** (skip if `--skip-freshness` flag in user's invocation): spawn the **`freshness-scanner`** subagent via `Task` with `subagent_type=freshness-scanner`. It walks every `docs/hint_index_map.md` and per-module `<module>/docs/` for frontmatter checks. See `.claude/agents/freshness-scanner.md`.
7. Each `module-auditor` invocation returns:
   ```
   ### Module: <name>
   - Wing path: <module-path>/docs/
   - Change summary: ...
   - Rooms affected: [list]
   - Drawers affected: [list]
   - Drawers needed (new): [list with one-line justification]
   - Xref breaks in hint_index_map: [list]
   - Pre-existing rot found: [list, optional]
   - Severity: trivial | rewrite | new-drawer-needed
   ```
8. Main agent synthesizes:
   - **Top:** summary table (one row per module — name, severity, room count, drawer count, xref breaks).
   - **Middle:** per-module detail blocks.
   - **Stale-docs section:** docs flagged by freshness scan, separate from PR-driven changes.
   - **Bottom:** full `hint_index_map.md` change list (additions, removals, xref edits).
9. Save report to `docs/_pending/audit-<YYYYMMDD-HHMM>.md`.
10. Print: `Audit complete. <N> modules affected, <K> stale docs flagged. Review report at <path>. Reply 'approved' to proceed to Phase 3, or send corrections.`
11. **Stop. Wait for human approval. Do not proceed until human types `approved` or `proceed`.**

### Phase 2 — Plan (review with human)

Trigger: human responds to audit. Possible responses:

- `approved` — proceed to Phase 3 with audit as-is.
- Edits to the audit report (e.g. "skip module X", "drawer Y not needed", "treat stale doc Z as re-stamp only").
- Questions — answer, refine the audit, ask again.

Output a finalized plan in `docs/_pending/plan-<YYYYMMDD-HHMM>.md` reflecting human edits. Get explicit approval before Phase 3.

### Phase 3 — Update (execute, serial not parallel)

1. `TodoWrite`: one todo per affected module + one per stale doc.
2. Process **serially**. Parallel writes race on `hint_index_map.md`.
3. For each module:
   1. Re-read wing docs fresh. Audit told you *what* changed — not current state.
   2. Apply edits to rooms and drawers per plan.
   3. Code, types, errors verbatim.
   4. Add new drawers if plan justified them. Use drawer template.
   5. Update frontmatter: bump `last_reviewed_commit` to `git rev-parse --short HEAD`, `last_reviewed_date` to today.
   6. Update `hint_index_map.md`: wing's section, plus any cross-wing xrefs.
   7. Mark todo done. Print one-line summary: `<module>: <what changed>`.
4. For stale-only docs (no PR-driven change, just freshness):
   1. Read source diff since `last_reviewed_commit`.
   2. If facts still accurate → re-stamp only (bump commit + date).
   3. If facts need update → edit, then re-stamp.
5. After all done:
   - Re-validate `hint_index_map.md`: every link resolves, every wing listed, no orphan rooms or drawers.
   - Update `Last index review` hash.
   - Move audit + plan reports from `docs/_pending/` to `docs/_history/`.
   - Print final summary table.

---

## Templates

These are the canonical shapes. `/init` uses them directly. Manual doc creation should follow them.

### `docs/info.md` template

```markdown
# Setup info

> <one-line summary of project — toolchain + platforms. /info echoes this line.>

## Toolchain

- Kotlin: <version>
- Gradle: <version>
- Xcode: <version>
- AGP: <version>

## Modules

| Module | Purpose |
|---|---|
| <name> | <one-line purpose> |

## Local conventions

- <convention not captured in code>

## Environment quirks

- <quirk Claude Code should know about>
```

### `docs/hint_index_map.md` template

```markdown
# hint_index_map

Palace wayfinding. Source of truth for documentation topology.

Last index review: <short SHA>
Last index date: <YYYY-MM-DD>

---

## <module-name>

Module path: `<path-from-settings.gradle>`
Docs root: `<path>/docs/`

Rooms:
- di → `<path>/docs/rooms/di.md`
- persistence → `<path>/docs/rooms/persistence.md`

Drawers (notable):
- `<ClassName>` → `<path>/docs/drawers/<ClassName>.md`

Cross-wing:
- depends on → <module-a>, <module-b>
- consumed by → <module-c>

---

## <next-module>
...
```

### Wing README template (`<module>/docs/README.md`)

```markdown
# Wing: <module>

<one-line summary>

## Public surface

- `<TypeName>` — <purpose>
- `<TypeName>` — <purpose>

## Rooms

- [DI](rooms/di.md) — <one line>
- [Persistence](rooms/persistence.md) — <one line>

## Load order

<ordering facts, e.g. "after CoreModule, before UiModule">

## Cross-wing deps

See `docs/hint_index_map.md` § <module>.
```

### Room template

```markdown
---
documents:
  - <repo-relative source path>
last_reviewed_commit: <short SHA>
last_reviewed_date: <YYYY-MM-DD>
---

# Room: <subsystem>

## Overview

<Name> — <what this subsystem does in this module>; <key components>.

## Components

\`\`\`kotlin
<verbatim public API: signatures only, no implementation>
\`\`\`

## Wiring

- <binding/registration fact>
- <lifecycle or order fact>
- <`<file>:<line>` for non-obvious wiring>

## Gotchas

- <fact from TODO/FIXME/HACK/NOTE/IMPORTANT/@Deprecated — cite `<file>:<line>`>
- <or `(none)` if empty>

## See also

- [<related>](<relative-path>)
```

### Drawer template

```markdown
---
documents:
  - <repo-relative source path>
last_reviewed_commit: <short SHA>
last_reviewed_date: <YYYY-MM-DD>
---

# <DrawerName>

<one-line: what it is, key role>

## Surface

\`\`\`kotlin
<verbatim public API: signatures only>
\`\`\`

## Wiring

- <where bound/registered/instantiated>
- <`<file>:<line>` for non-obvious>

## Depends on

- <other drawer or room> — <why>

## Used by

- <wing/room/drawer> — <how>

## Gotchas

- <fact — cite `<file>:<line>`>
- <or `(none)` if empty>

## See also

- [<related>](<relative-path>)
```

---

## Constraints

- `info.md` is authoritative. Conflicts with code-inferred behavior → `info.md` wins.
- `hint_index_map.md` is source of truth for topology. Structural changes (rename wing, remove room class) → flag in audit. No silent restructure.
- Diff ambiguous? Read source files. No invent behavior.
- New drawer only if Plan phase justified it. No drive-by creation.
- Pre-existing rot may be flagged by audit. Update may fix it if low-risk. High-risk rot → leave `<!-- TODO: ... -->`, surface in summary.
- Preserve voice and structure of untouched sections. Minimum-diff edits.
- Code, type signatures, error messages, gradle/koin/sqldelight/ktor config: verbatim. No paraphrasing of technical content.
- No emojis. No marketing tone.

---

## Stop conditions

Halt and ask human if:

- Total diff exceeds ~3000 changed lines. Suggest splitting sweep into sub-batches.
- Module has no existing wing AND audit says it now has public surface. New module → use `/init` for that module specifically.
- `hint_index_map.md` not found at `INDEX_FILE` path. Suggest `/init`.
- Wing references a room or drawer file that does not exist. Pre-existing breakage → human call.
- Audit reveals > 5 pre-existing rot items. Suggests separate cleanup pass.
- More than ~30 stale docs flagged in global scan. Suggests dedicated freshness sweep instead of folding into PR sweep.

---

## Output contract

End of Phase 1 (Audit):
- Path to audit report.
- Summary table.
- Explicit "approve to proceed" prompt.

End of Phase 3 (Update):
- Summary table of changes per module.
- List of new drawers added.
- List of pre-existing rot items fixed.
- List of pre-existing rot items deferred (with TODO refs).
- List of stale docs re-stamped vs updated.
- Path to archived audit + plan reports.

End of `/init`:
- Wings created count.
- Rooms generated count.
- Drawers suggested-but-not-created list.
- `info.md` status (created / left untouched).

End of `/info`:
- Status block as specified above.

---

*Last updated for: 3.1.0*
