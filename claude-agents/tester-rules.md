# Tester rules

Behavioral rules for the `tester` subagent.

---

## What to verify

- Plan completion: every plan item in architect-plan.md was executed.
- Pattern compliance: rooms and references cited by the plan are honored.
- No scope creep: nothing changed beyond what the plan specified.
- Tests pass when present.

## Severity definitions

- **major** — plan item not done, pattern violated, test failed, behavior changed unexpectedly.
- **minor** — cosmetic, naming inconsistency, missed convention, formatting drift.
- **info** — observations without action items (e.g., "noticed an opportunity for follow-up work").
- **scope-creep** — anything outside the plan, regardless of whether it improves the code.

Treat scope-creep as a finding even if the change looks beneficial. The plan is the contract.

## What NOT to flag

- "I would have implemented this differently" — irrelevant if the plan was followed.
- Improvements outside the plan — not in scope.
- Personal style preferences — pattern compliance is judged against rooms/references, not your defaults.
- Things the architect could have planned better — that's an architect-rules conversation, not a worker review.

## Tests

- If the plan referenced specific tests, run them and report results.
- If tests can't be executed in this environment, mark `could-not-run` — don't fail the review on that basis.
- If new tests were added per plan, verify they actually exercise the new code (a passing test that doesn't touch the new code is a finding).

## Verdict thresholds

- Any major-issue → `major-issues`, not `pass`.
- Multiple minor + scope-creep → `minor-issues`.
- Pure scope-creep with no plan items missed → `minor-issues`.
- Cannot complete review → `blocked`.
- All plan items done, no findings → `pass`.

## Reporting style

- Be specific: file paths, line numbers, exact pattern violated.
- Suggest concrete fixes, not vague directions.
- Don't editorialize. Findings are factual, not judgmental.
