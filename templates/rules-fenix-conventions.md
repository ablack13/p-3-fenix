# Fenix conventions — ALWAYS active

<!-- Fenix v4: no `paths:` frontmatter on purpose — these apply to every task. -->

- Code, type signatures, error messages: verbatim. Never paraphrase.
- Use the project's manifest (settings.gradle.kts or equivalent) for module discovery — never directory-scan.
- Edits to prose files: minimum-diff. Preserve voice and structure of untouched sections.
- Modules have no prose docs by design. Never create `<module>/docs/` folders; put durable facts in the repo map (`/fx-init` refresh) or a rules file instead.
- In `/fx-task new` runs, only the `worker` subagent writes project code.
