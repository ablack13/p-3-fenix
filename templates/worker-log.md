---
task_id: <YYYYMMDD-HHMM-slug>
agent: worker
created: <YYYY-MM-DD HH:MM>
updated: <YYYY-MM-DD HH:MM>
status: drafting | in-progress | complete | blocked
plan_ref: architect-plan.md
---

# Worker log: <one-line task summary>

## Execution status

| Plan item | Type | Status | Started | Completed | Notes |
|---|---|---|---|---|---|
| `<path>` | create / modify / delete | pending / in-progress / done / blocked / skipped | — | — | — |

## Files actually touched

| Path | Lines | Operation | Linked plan item |
|---|---|---|---|
| `<path>` | <count> | created / modified / deleted | row from plan |

## Deviations from plan

| Plan item | What deviated | Reason |
|---|---|---|
| <item> | <how worker's actual change differs from plan> | <reason — usually "blocked, asked developer"> |

## Blockers encountered

| Blocker | When | Resolution |
|---|---|---|
| <description> | <plan item where it surfaced> | <how it was resolved, or "still blocking"> |

## Notes for tester

- <anything the tester should know — specific patterns followed, deliberate choices, areas needing extra scrutiny>

## Worker rules

The worker updates this file in real time — at the start of each plan item (set Status to `in-progress`, fill `Started`), at completion (set Status to `done`, fill `Completed`), and on any blocker (set Status to `blocked`, log in Blockers).

This file is the durable record of what was actually done. Tester reads it as primary input. Outcome.md references it.
