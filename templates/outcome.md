---
task_id: <YYYYMMDD-HHMM-slug>
agent: orchestrator
created: <YYYY-MM-DD HH:MM>
status: closed
disposition: <accepted | re-dispatched | cancelled>
---

# Outcome: <one-line task summary>

## Final disposition

<accepted clean | accepted with findings | re-dispatched | cancelled>

## Summary

| Phase | Result | Artifact |
|---|---|---|
| Navigation | matched <N> map sections, scope <modules> | task.md |
| Architect | plan with <N> items, <K> open questions resolved | architect-plan.md |
| Worker | <N> created, <M> modified, <K> deleted | worker-log.md |
| Tester | verdict=<verdict>, <X> findings | tester-review.md |

## Files changed (final)

<copied from worker-log.md "Files actually touched" — the canonical list>

## Findings disposition

| Finding | Severity | Action taken |
|---|---|---|
| <from tester-review.md> | major / minor / info | fixed / accepted / deferred |

## Follow-up items

- <anything carried into a future task>
- <if repo structure changed: "run /fx-init to refresh the repo map">

## Closed at

<YYYY-MM-DD HH:MM>
