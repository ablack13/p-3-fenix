# /fx-task — Task navigation and dev workflow

$ARGUMENTS

Two modes based on the first word:

- **`new <description> [briefs:<path>]`** — file-based dev-team workflow.
- **`<description>` (anything else)** — explicit navigation with visible classification, then proceed via main agent.

---

## Mode 1 — `new <description>` (dev-team workflow, file-based)

The task description is everything after `new`. Optional `briefs:<path>` (folder or file) attaches external context. The path can also be mentioned naturally in the description ("per 2105/spec.md", "see briefs/PM-1234/").

### Phase 0 — Create task folder

1. Generate `task_id` = `<YYYYMMDD-HHMM>-<short-slug-from-description>`.
2. Create folder `tasks/<task_id>/`.
3. Read `docs-meta/templates/task.md`. Write `tasks/<task_id>/task.md` populated with:
   - Description as provided.
   - Briefs paths if any.
   - Created timestamp.
   - `status: open`, `phase: created`.
   - All phase rows in the status table set to `pending`.
4. Add manifest entry: `{action: "create-task", task_id, path: "tasks/<task_id>/", timestamp: "..."}`.

### Phase 1 — Navigation

The repo map lives in `CLAUDE.md` (between the `FENIX:MAP` markers) and is already in context — no file read needed.

1. If the map sections are empty (fresh install, `/fx-init` never ran), abort with "run /fx-init first".
2. Match the description against `When you need X, look here` and `Entry points`. Pick the relevant lines.
3. Identify module scope from the map's `Modules` list. If ambiguous, list candidates and ask the developer once before proceeding. Don't guess.
4. Identify code entry points — the paths the matched map lines point to.
5. Identify briefs (from `briefs:<path>` arg or inline mentions).
6. Update `tasks/<task_id>/task.md` with the Navigation section filled in.
7. Set task.md frontmatter `phase: architect`.

Print navigation summary referencing the task file:

```
Task created: tasks/<task_id>/task.md

Map sections matched: <list of matched "When you need X" / entry-point lines>
Module scope: <list>
Code entry points: <paths>
Briefs: <path or "none">
```

### Phase 2 — Architecture

Spawn the **`architect`** subagent via Task with `subagent_type=architect`. Pass:

```
{
  task_dir: "tasks/<task_id>/",
  task: "<description>",
  map_sections: [<matched map lines, verbatim>],
  code_entry_points: [...],
  module_scope: [...],
  briefs: [...]
}
```

The architect writes to `tasks/<task_id>/architect-plan.md` and returns a brief summary.

After the architect completes, read the plan file and check for:
- Open questions → surface them to the developer first; resolve before approval.
- Status `proposed` → present approval gate.

Approval prompt:

```
Architect plan ready: tasks/<task_id>/architect-plan.md

Summary:
  - Files to create: <N>
  - Files to modify: <N>
  - Files to delete: <N>
  - Verified facts: <N>
  - Assumptions: <N>

Approve to proceed to implementation?

  1. Approve — dispatch worker.
  2. Edit — make corrections to the plan file, then dispatch.
  3. Re-architect — give the architect different guidance, regenerate plan.
  4. Cancel — write outcome.md as cancelled, close task.
```

On approve: update plan frontmatter `status: approved`. Update task.md `phase: worker`.

### Phase 3 — Implementation

Spawn **`worker`** via Task with `subagent_type=worker`. Pass:

```
{
  task_dir: "tasks/<task_id>/",
  plan_path: "tasks/<task_id>/architect-plan.md",
  map_sections: [...],
  code_entry_points: [...],
  briefs: [...]
}
```

The worker writes to `tasks/<task_id>/worker-log.md`, updating per plan item in real time. Returns brief summary.

After worker completes:
- Read worker-log.md.
- If any items are `blocked`, surface immediately to developer.
- Otherwise, present pre-review gate:

```
Implementation complete: tasks/<task_id>/worker-log.md

Summary:
  - Plan items done: <N> / <total>
  - Blocked: <N>
  - Files created: <N>
  - Files modified: <N>
  - Files deleted: <N>

Proceed to review?
  1. Yes — dispatch tester (recommended).
  2. Skip review — accept as-is, jump to disposition.
  3. Cancel — revert worker changes (developer must run git operations).
```

On yes: update task.md `phase: tester`.

### Phase 4 — Review

Spawn **`tester`** via Task with `subagent_type=tester`. Pass:

```
{
  task_dir: "tasks/<task_id>/",
  plan_path: "tasks/<task_id>/architect-plan.md",
  log_path: "tasks/<task_id>/worker-log.md"
}
```

The plan's `Patterns to follow` table carries the pattern sources — the tester reads them from the plan file.

The tester writes to `tasks/<task_id>/tester-review.md`. Returns verdict and brief summary.

Update task.md `phase: disposition`.

### Phase 5 — Disposition (human-only)

Read tester-review.md verdict. Present disposition prompt:

```
Tester verdict: <pass | minor-issues | major-issues | blocked>

Review at: tasks/<task_id>/tester-review.md

Disposition options:

  1. Close — accept findings as noted, no further action.
  2. Re-dispatch worker — open new worker phase with tester findings as input.
  3. Cancel — revert (developer must run git operations).

Recommendation: <option N> based on <reasoning>.
```

Recommendation logic:
- Verdict `pass` or `minor-issues` the developer can live with → recommend option 1.
- Verdict `major-issues` or `blocked` → recommend option 2 unless developer disagrees.

### Phase 6 — Outcome (always runs)

After developer chose disposition:

1. Read `docs-meta/templates/outcome.md`. Write `tasks/<task_id>/outcome.md` filled with:
   - Final disposition.
   - Summary table with results from each phase.
   - Files changed (canonical list from worker-log.md).
   - Findings disposition table.
   - Closed-at timestamp.
2. Update task.md frontmatter:
   - `status: closed`.
   - `phase: closed`.
3. Update task.md phase status table — fill all completed phases.
4. **Map-refresh check:** if the worker created or deleted a module, moved an entry point, or changed the structure the repo map describes — note it in outcome.md `Follow-up items` and include the hint in the final summary.

Print final summary:

```
Task closed: tasks/<task_id>/

Phase summary:
  Architect plan       ✓ (approved)
  Worker log           ✓ (<N> items done)
  Tester review        ✓ (<verdict>)
  Disposition          ✓ (<chosen option>)

<if structure changed:>
⚠ This task changed repo structure the map describes.
Run /fx-init to refresh the repo map in CLAUDE.md.

Next: task is closed. Run /clear to drop this task's context and start fresh.
```

---

## Mode 2 — `<description>` (explicit navigation only)

Used when the developer wants to see how a request maps onto the repo before normal execution.

1. If the repo map in `CLAUDE.md` is empty (markers with no content), direct user to `/fx-init` and stop.
2. Match $ARGUMENTS against the map. Pick relevant lines.
3. Identify module scope. Ask if ambiguous.
4. Print:

```
Task: $ARGUMENTS

Map sections matched: <list>
Module scope: <list>
Code entry points to open: <paths>

Plus: docs/info.md (if not already read this session)
```

5. Wait briefly for override.
6. Read the entry points, follow code on demand, form a plan, present, proceed after approval.

This mode does NOT invoke architect/worker/tester. Navigation preview + normal task execution.

---

## If $ARGUMENTS is empty or unrecognized

Print:

```
Usage:
  /fx-task <description>             Explicit navigation — see classification, then form a plan.
  /fx-task new <description>         Dev-team workflow — architect → worker → tester (file-based).

Examples:
  /fx-task fix the practice screen UI bug
  /fx-task new add a "skip card" button to practice screen briefs:2105/

Pass briefs:<path> to attach external specs, mockups, or logs.
```

Stop.

---

## Constraints

- Mode 1 is file-based throughout. Every agent writes to `tasks/<task_id>/`. Chat output is summary pointers.
- Never auto-accept tester verdicts. Disposition is always developer-decided.
- If the repo map is empty, stop and direct to `/fx-init`.
- Even small tasks go through architect → worker → tester in mode 1. The discipline is the value.
- Nobody in this workflow edits `CLAUDE.md`, `.claude/rules/`, or `docs/` — map refreshes are `/fx-init`'s job, suggested at close when structure changed.
