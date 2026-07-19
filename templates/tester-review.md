---
task_id: <YYYYMMDD-HHMM-slug>
agent: tester
created: <YYYY-MM-DD HH:MM>
updated: <YYYY-MM-DD HH:MM>
status: drafting | complete
plan_ref: architect-plan.md
log_ref: worker-log.md
verdict: pending | pass | minor-issues | major-issues | blocked
---

# Tester review: <one-line task summary>

## Verdict

<pass | minor-issues | major-issues | blocked>

## Verdict rationale

<2-3 sentences>

## Plan completion

| Plan item | Status from worker | Tester check | Notes |
|---|---|---|---|
| <item> | done / blocked / skipped | confirmed / mismatch / scope-creep | <one-line> |

## Pattern compliance

| Pattern | Source (file / rule) | Status | Notes |
|---|---|---|---|
| <name> | `<path>` | followed / violated / partial | <one-line> |

## Tests run

| Test | Result | Notes |
|---|---|---|
| <name> | pass / fail / could-not-run | <details> |

## Findings

| Severity | File:line | Issue | Suggested fix |
|---|---|---|---|
| major / minor / info | `<path>:<line>` | <description> | <concrete fix> |

## Scope creep detected

| File | What was added beyond plan | Severity |
|---|---|---|
| `<path>` | <one-line> | minor / scope-creep |

## Verdict thresholds applied

- Any major-issue → `major-issues`
- Multiple minor + scope-creep → `minor-issues`
- Pure scope-creep, no plan items missed → `minor-issues`
- Cannot complete review → `blocked`
- All plan items done, no findings → `pass`
