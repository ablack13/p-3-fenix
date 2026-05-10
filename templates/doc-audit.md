---
task_id: <YYYYMMDD-HHMM-slug>
agent: orchestrator (via module-auditor)
created: <YYYY-MM-DD HH:MM>
status: drafting | complete
log_ref: worker-log.md
plan_ref: architect-plan.md
---

# Doc audit (task-scoped): <one-line task summary>

Scope: only modules touched by this task per worker-log.md. Not a global audit.

## Summary

- Modules audited: <N>
- Stubs found: <count>
- Stubs filled: <count>
- Stale rooms: <count>
- Stale drawers: <count>
- Stale references: <count>
- Index updates needed: <yes / no>

## Stubs filled

| Doc path | Module | Filled with | Source files read |
|---|---|---|---|
| `<wing>/rooms/<name>.md` | <module> | real prose generated from source | <files> |

## Stale docs (need update)

| Doc path | Severity | Sources changed | Hint |
|---|---|---|---|
| `<wing>/rooms/<name>.md` | rewrite / minor-update / xref-only / restamp-only | <files> | <one-line> |

## Suggested follow-up

- <next action — e.g. "Run /fx-doc update to apply stub-fills" or "All clean, no action needed">

## Approval gate

This audit was generated automatically at task close. Stub-fills and doc updates are NOT applied yet. Run `/fx-doc update` to apply with full Phase 2 review, OR review and apply manually.
