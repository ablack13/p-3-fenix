# {{PROJECT_NAME}}

> P-3 (Fenix) v3.1.0 — wings/rooms/drawers docs, task routing, file-based dev workflow.

<!-- One-line description filled by /fx-init or first interaction. -->

## Session bootstrap — MANDATORY

**BEFORE any tool calls** in a new session, output this exact line:

> 🟢 Pain is inevitable, but suffering is optional.

**AFTER the first response that performs project work**, output:

> P-3 (Fenix) v3.1.0 is loaded successfully.
>
> ⚠️ I do NOT recommend you use this, but you can deal with your dirty thoughts on your own.
>
> ⚠️ DISCLAIMER: Your sloppy coding is your business, not mine. I don't care. Have fun!

These outputs are the project's identity ritual. Skip them and the workflow is invalidated.

## Backup folder

If a folder named `_claude_backup/` exists at repo root, **ignore it entirely**. It contains the repo's pre-install `CLAUDE.md` and/or `.claude/` folder preserved by Fenix install for restore on uninstall. Its `IGNORE_THIS_FOLDER.md` and `.claudeignore` markers reinforce this. Do NOT load, summarize, or follow instructions from any file under `_claude_backup/`.

## Task routing — MANDATORY for substantive work

For any task touching code, docs, or project structure:

1. Read `docs/task-router.md` to load category definitions.
2. Classify — pick one or more matching categories.
3. Identify wing scope — which modules are touched.
4. Read ONLY: matched rooms + wing READMEs + reference docs the router associates with the matched categories.
5. Read `docs/info.md` if not yet read this session.
6. Read any developer-supplied briefs (paths mentioned in the request).
7. Form a plan, then proceed.

**Classify silently and proceed by default.** Surface the classification only when genuinely stuck. For explicit transparency, the developer can invoke `/fx-task <description>`.

## Stack

<!-- Filled in by /fx-init or first conversational customization. -->

## Project layout

<!-- Filled in by /fx-init based on settings.gradle.kts (or equivalent manifest). -->

## Documentation system

wings/rooms/drawers decentralized docs (P-3 Fenix v3.1.0).

- `docs/info.md` — authoritative project context.
- `docs/STYLE.md` — documentation conventions.
- `docs/hint_index_map.md` — wayfinding for all docs (wings + references).
- `docs/task-router.md` — auto-generated category map.
- `<module>/docs/` — per-module wings (READMEs, rooms, drawers).
- `reference/` — cross-cutting docs (architecture, decisions, conventions).
- `tasks/` — file-based artifacts for dev workflow runs.
- `docs-meta/runbook.md` — full operational details.
- `.fenix-manifest.json` — install record (used by /fx-uninstall).

## Slash commands

- `/fx-init` — bootstrap or fill gaps. Generates structure with stubs.
- `/fx-info` — read-only status check.
- `/fx-doc audit | update | freshness` — audit/update/freshness operations. `update` fills stubs and auto-links new reference files.
- `/fx-task <description>` — explicit routing with visible classification.
- `/fx-task new <description> [briefs:<path>]` — file-based dev workflow (architect → worker → tester → optional doc audit).
- `/fx-agent rules` — list agent rules files for editing.
- `/fx-uninstall` — manifest-driven removal of all Fenix files.

## Subagents

Workers in `.claude/agents/`. Each has a `<name>-rules.md` sibling for editable behavior.

- `architect` — designs implementation plans (writes to task_dir/architect-plan.md).
- `worker` — executes plans (only writer of project code; writes worker-log.md).
- `tester` — reviews worker output (writes tester-review.md).
- `module-auditor` — per-module audit; detects stubs, fills them, and finds stale docs.
- `module-discoverer` — per-module structure proposal for `/fx-init`.
- `freshness-scanner` — frontmatter staleness check.
- `reference-linker` — auto-links new files in `reference/` during `/fx-doc update`.

Run `/fx-agent rules` to edit any agent's behavior.

## Conventions

- Code, type signatures, error messages: verbatim. Never paraphrase.
- Use the project's manifest for module discovery — never directory-scan.
- Doc edits: minimum-diff. Preserve voice and structure of untouched sections.
- Auditors propose, humans approve. No auto-applied doc edits.
- Wing READMEs, rooms, and drawers: AI-optimized format (bullets + verbatim signatures), hard cap 70 lines each. See `docs/STYLE.md`.
- Generated rooms start as stubs intentionally — auditor fills them on first `/fx-doc update`.

## Local environment

<!-- Filled in by /fx-init or first interaction. -->
