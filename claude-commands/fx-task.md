# /fx-task — Task routing and dev workflow

$ARGUMENTS

Two modes based on the first word:

- **`new <description> [briefs:<path>]`** — file-based dev-team workflow.
- **`<description>` (anything else)** — explicit task routing with visible classification, then proceed via main agent.

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

### Phase 1 — Routing

1. Read `docs/task-router.md`. If empty or missing, abort with "run /fx-init first".
2. Classify the description against categories. Pick one or more.
3. Identify wing scope. If ambiguous, list candidates and ask the developer once before proceeding. Don't guess.
4. Identify reference docs the router associates with the matched categories.
5. Identify briefs (from `briefs:<path>` arg or inline mentions).
6. Update `tasks/<task_id>/task.md` with the Routing section filled in.
7. Set task.md frontmatter `phase: architect`.

Print routing summary referencing the task file:

```
Task created: tasks/<task_id>/task.md

Categories matched: <list>
Wing scope: <list>
Rooms loaded: <list>
Wing READMEs: <list>
Reference docs: <list>
Briefs: <path or "none">
```

### Phase 2 — Architecture

Spawn the **`architect`** subagent via Task with `subagent_type=architect`. Pass:

```
{
  task_dir: "tasks/<task_id>/",
  task: "<description>",
  matched_rooms: [...],
  wing_scope: [...],
  reference_docs: [...],
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
  matched_rooms: [...],
  reference_docs: [...],
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
  log_path: "tasks/<task_id>/worker-log.md",
  matched_rooms: [...],
  reference_docs: [...]
}
```

The tester writes to `tasks/<task_id>/tester-review.md`. Returns verdict and brief summary.

Update task.md `phase: disposition`.

### Phase 5 — Disposition (human-only)

Read tester-review.md verdict. Present disposition prompt:

```
Tester verdict: <pass | minor-issues | major-issues | blocked>

Review at: tasks/<task_id>/tester-review.md

Disposition options:

  1. Close clean — accept all findings, no further action.
  2. Close with doc audit — accept, then run task-scoped doc audit.
  3. Re-dispatch worker — open new worker phase with tester findings as input.
  4. Cancel — revert (developer must run git operations).

Recommendation: <option N> based on <reasoning>.
```

Recommendation logic:
- Worker touched files in modules with existing wings → recommend option 2.
- Worker touched only build configs / undocumented areas / pure refactor → recommend option 1.
- Tester flagged pattern violations against rooms/references → strongly recommend option 2.
- Verdict is `major-issues` or `blocked` → recommend option 3 unless developer disagrees.

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

### Phase 7 — Doc audit (only if option 2 was chosen)

If developer chose option 2 in Phase 5:

1. Read `worker-log.md` "Files actually touched". Group by module.
2. For each affected module, spawn `module-auditor` via Task with:
   ```
   {
     module_name: <name>,
     module_path: <path>,
     proposal_path: "tasks/<task_id>/doc-audit-proposals/<module-name>.md",
     task_context: {
       architect_plan_path: "tasks/<task_id>/architect-plan.md",
       worker_log_path: "tasks/<task_id>/worker-log.md"
     }
   }
   ```
   Note: NO `BASE_REF`/`HEAD_REF` — this is task-scoped, not git-diff-driven. Auditor uses task_context to find what changed.

3. Optionally spawn `freshness-scanner` scoped to the touched wings (skip global scan).

4. Synthesize all auditor proposals into `tasks/<task_id>/doc-audit.md` with the structure from `docs-meta/templates/doc-audit.md`.

5. Update task.md frontmatter `doc_audit: complete`. Update outcome.md to mention the audit was run.

6. Print final summary:

```
Task closed: tasks/<task_id>/

Phase summary:
  Architect plan       ✓ (approved)
  Worker log           ✓ (<N> items done)
  Tester review        ✓ (<verdict>)
  Disposition          ✓ (<chosen option>)
  Doc audit            ✓ (<N> stubs found, <K> stale flagged)

Doc audit at: tasks/<task_id>/doc-audit.md

Stub-fills and stale-doc updates are NOT applied yet.
Run /fx-doc update to apply with full Phase 2 review.
```

If option 1 was chosen, skip Phase 7. Print:

```
Task closed: tasks/<task_id>/

Phase summary:
  Architect plan       ✓ (approved)
  Worker log           ✓ (<N> items done)
  Tester review        ✓ (<verdict>)
  Disposition          ✓ (close clean)
  Doc audit            ↷ skipped
```

---

## Mode 2 — `<description>` (explicit routing only)

Used when the developer wants to see how the task router classifies a request without invoking the dev-team workflow.

1. Read `docs/task-router.md`. If missing or empty, direct user to `/fx-init` and stop.
2. Classify $ARGUMENTS. Pick one or more categories.
3. Identify wing scope. Ask if ambiguous.
4. Print:

```
Task: $ARGUMENTS

Categories matched: <list>
Wing scope: <list>
Rooms to load: <list>
Wing READMEs to load: <list>
Reference docs: <list>

Plus: docs/info.md (if not already read this session)
```

5. Wait briefly for override.
6. Read matched files, form a plan, present, proceed after approval.

This mode does NOT invoke architect/worker/tester. Routing preview + normal task execution.

---

## If $ARGUMENTS is empty or unrecognized

Print:

```
Usage:
  /fx-task <description>             Explicit routing — see classification, then form a plan.
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
- If `docs/task-router.md` is empty (no categories), stop and direct to `/fx-init`.
- Even small tasks go through architect → worker → tester in mode 1. The discipline is the value.
- Doc audit at task close is OPT-IN (Phase 5 disposition choice). It's not automatic.
