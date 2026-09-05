# Agent guidance

Before Spec Kit planning or implementation, read
`.specify/memory/project-guide.md` with the project constitution. It maps
requirements to this repository's source, acceptance evidence, and validation.

Read `.specify/memory/constitution.md`, `ARCHITECTURE.md`, `TESTING.md`, and `CONTRIBUTING.md` when present.

- Use stable monitor identity; do not rely on transient connector enumeration or object order.
- Preserve unrelated shell settings and route owned saves, normalization, and reloads through the established service.
- Update QML metadata, defaults, settings UI, IPC, docs, and tests together.
- Test reordered, added, removed, and ambiguous monitors with isolated HOME/XDG/Quickshell roots; do not alter the live compositor session.

## Spec-driven changes

Use Spec Kit for new capabilities, architecture, security-sensitive behavior,
migrations, and coordinated multi-file changes. Keep narrow fixes, dependency
updates, prose edits, and release housekeeping in the normal repository
workflow unless their risk warrants a written specification. Keep completed
feature directories under `specs/` as decision history; do not backfill them for
finished work.
