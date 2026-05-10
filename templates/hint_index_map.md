# hint_index_map

Palace wayfinding. Source of truth for documentation topology.

Last index review: <short SHA>
Last index date: <YYYY-MM-DD>

---

<!--
One section per documented module (wing). Order alphabetically.

Each section:
- Module path (from settings.gradle.kts)
- Docs root
- List of rooms with relative paths
- List of notable drawers
- Cross-wing dependencies
-->

## <module-name>

Module path: `<path-from-settings.gradle>`
Docs root: `<path>/docs/`

Rooms:
- di → `<path>/docs/rooms/di.md`
- persistence → `<path>/docs/rooms/persistence.md`
- network → `<path>/docs/rooms/network.md`
- ui-android → `<path>/docs/rooms/ui-android.md`
- ui-ios → `<path>/docs/rooms/ui-ios.md`

Drawers (notable):
- `<ClassName>` → `<path>/docs/drawers/<ClassName>.md`

Cross-wing:
- depends on → <module-a>, <module-b>
- consumed by → <module-c>, <module-d>

---

## <next-module>

...

---

## Reference docs

<!--
Cross-cutting documentation that applies to multiple wings or the project as a whole.
Auto-managed by /fx-doc update via the reference-linker subagent.
Order alphabetically by filename.
-->

- `reference/<filename>.md` — <one-line topic description>
- `reference/decisions/<filename>.md` — <one-line topic description>
