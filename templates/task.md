---
task_id: <YYYYMMDD-HHMM-slug>
created: <YYYY-MM-DD HH:MM>
status: open | in-progress | blocked | closed
phase: created | architect | worker | tester | disposition | closed
---

# Task: <one-line description>

## Description

<full task description as provided by developer>

## Briefs

<paths to external context, if any — e.g., `2105/`, `briefs/PM-1234/`>

## Routing

<filled in during Phase 1 by /fx-task new>

- Categories matched: <list>
- Wing scope: <list>
- Rooms loaded: <list>
- Reference docs: <list>

## Phase status

| Phase | State | Started | Completed | Artifact |
|---|---|---|---|---|
| Routing | pending | — | — | — |
| Architect | pending | — | — | architect-plan.md |
| Worker | pending | — | — | worker-log.md |
| Tester | pending | — | — | tester-review.md |
| Disposition | pending | — | — | outcome.md |
| Doc audit | pending | — | — | doc-audit.md (optional) |

## Notes

<anything the orchestrator records during the task lifecycle>
