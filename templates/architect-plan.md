---
task_id: <YYYYMMDD-HHMM-slug>
agent: architect
created: <YYYY-MM-DD HH:MM>
updated: <YYYY-MM-DD HH:MM>
status: drafting | proposed | approved | rejected | superseded
---

# Architect plan: <one-line task summary>

## Module scope

<module-1>, <module-2>

## Sources of truth consulted

- Briefs: [list with paths, or "none"]
- Code entry points: [list with paths]
- Source files read: [list with paths]

## Verified facts

| Fact | Verification method | Source |
|---|---|---|
| <fact stated in plan> | grep / read / bash | <file or command> |

## Assumptions (unverified)

| Assumption | Why not verified | Risk if wrong |
|---|---|---|
| <fact> | <no network / no gradle / etc.> | <consequence> |

## Files to create

| Path | Purpose | Key types/contents | Status |
|---|---|---|---|
| `<path>` | <one-line> | <key types> | pending |

## Files to modify

| Path | What changes | Why | Status |
|---|---|---|---|
| `<path>` | <structural change> | <reason> | pending |

## Files to delete

| Path | Reason | Status |
|---|---|---|
| `<path>` | <one-line> | pending |

## Patterns to follow

| Pattern | Source (file / rule) | Application |
|---|---|---|
| <name> | `<path>` | <how it applies> |

## Risks

- <risk description>

## Open questions for the developer

- <question>

## Status row values

- `pending` — not started.
- `in-progress` — worker is currently on this item.
- `done` — completed and verified by tester.
- `blocked` — worker stopped, needs developer input.
- `skipped` — explicitly skipped by developer during disposition.

The worker updates the Status column in worker-log.md, not here. This file is the architect's contract; the worker's log is the live execution record.
