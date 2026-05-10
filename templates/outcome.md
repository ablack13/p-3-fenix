---
task_id: <YYYYMMDD-HHMM-slug>
agent: orchestrator
created: <YYYY-MM-DD HH:MM>
status: closed
disposition: <accepted | re-dispatched | cancelled>
doc_audit: <skipped | pending | complete>
---

# Outcome: <one-line task summary>

## Final disposition

<accepted clean | accepted with findings | re-dispatched | cancelled>

## Summary

| Phase | Result | Artifact |
|---|---|---|
| Routing | matched <N> categories, scope <wings> | task.md |
| Architect | plan with <N> items, <K> open questions resolved | architect-plan.md |
| Worker | <N> created, <M> modified, <K> deleted | worker-log.md |
| Tester | verdict=<verdict>, <X> findings | tester-review.md |
| Doc audit | <skipped / completed / N stubs filled / N stale flagged> | doc-audit.md |

## Files changed (final)

<copied from worker-log.md "Files actually touched" — the canonical list>

## Findings disposition

| Finding | Severity | Action taken |
|---|---|---|
| <from tester-review.md> | major / minor / info | fixed / accepted / deferred |

## Follow-up items

- <anything carried into a future task>

## Closed at

<YYYY-MM-DD HH:MM>
