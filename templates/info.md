# Setup info

> {{PROJECT_NAME}} — <one-line description>. <stack/platforms>. <toolchain versions>.

<!--
The blockquote line above is what /info shows. Keep it to one line.
Update everything else freely.
-->

## Toolchain

- Kotlin: <version>
- Gradle: <version>
- AGP: <version>
- Xcode: <version>
- Ruby (fastlane): <version>

## Modules

| Module | Purpose |
|---|---|
| <name> | <one-line purpose> |

## Local conventions

<!-- Conventions not captured in code. The runbook treats these as authoritative. -->

- Koin scopes: <how scopes work in this repo>
- DI module load order: <if non-obvious>
- Database migrations: <how handled>
- Other: <...>

## Environment quirks

<!-- Things Claude Code should know but aren't in CLAUDE.md. -->

- iOS Simulator: clear caches after KMP version bumps (`xcrun simctl erase all`).
- KMP incremental compilation: set `kotlin.incremental.native=false` if cache corruption.
- <other quirks>

## Build / CI

- Branches: <main, develop, ...>
- CI: <GitLab pipeline / GitHub Actions / ...>
- Release process: <one-line summary or pointer>

## External services

- <e.g. push notifications service>
- <e.g. analytics service>
- <e.g. translations / localization service>
- <others>
