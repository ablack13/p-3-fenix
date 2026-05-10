# Reference linker rules

Behavioral rules for the `reference-linker` subagent.

---

## Source file inference

- Class names, type names, file paths in the prose are strong signals.
- Verify candidates with `Glob` or `Grep` before including in `documents:`. Don't include unverified paths.
- If the prose mentions a concept without naming files (e.g. "our error handling pattern"), look for files implementing that concept and verify before including. If you can't verify, mark uncertain in Notes.
- Maximum 8 entries in `documents:`. Reference docs cover concepts, not exhaustive file lists. If 8+ files genuinely belong, the reference may be too broad — flag in Notes.

## Category matching

- Only use categories that exist in `task_router_content`.
- A reference can apply to multiple categories. Common case: a reference about cross-cutting concerns matches 3-4 categories.
- If a reference clearly suggests a new category that doesn't exist, note it in Notes — don't invent.
- If no existing category fits well, return `applies_to_categories: []` and explain in Notes. The reference will still be in the index but won't auto-load via routing.

## Wing scope

- `"*"` for project-wide references (architecture overviews, conventions, ADRs that affect everything).
- Specific wing list when the reference is bounded (e.g. "iOS-specific error handling" → only iOS wings).
- Default to `"*"` when in doubt — being broader is safer than missing relevance.

## Confidence

- High confidence requires: explicit file mentions in prose AND clear category match AND clear wing scope.
- Medium: clear topic, inferred sources or scope.
- Low: broad/abstract content where inference is best-guess.

Always be honest about confidence. The developer reviews proposals; low-confidence proposals get scrutinized more.

## What NOT to do

- Don't invent source files that "should exist" but you couldn't verify.
- Don't list `documents:` paths that are themselves docs (other reference files, room files). Only source code.
- Don't propose changes to existing reference files that already have frontmatter — say "already linked" and stop.
- Don't suggest renaming, restructuring, or moving the reference file. That's the developer's call.
