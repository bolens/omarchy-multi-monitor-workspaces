# omarchy-multi-monitor-workspaces Spec Kit project guide

A stock-shell workspace plugin with stable monitor identity, deterministic bank
allocation, and owned persistence.

Read this guide with `AGENTS.md` and `.specify/memory/constitution.md` before
specifying, planning, or implementing a substantial change. It is project-owned
guidance, not an upstream-managed template.

## Source and ownership map

- `Model.js`
- `Service.qml`
- `BarWidget.qml`
- `SettingsPanel.qml`
- `TESTING.md`

## Specification and plan decisions

Specify monitor identity, workspace-bank ownership, panel ownership, and persisted
versus pending state. Route normalization and writes through the service. Preserve
unrelated settings and reject stale replacement or detached-widget callbacks.

## Acceptance evidence

Cover attach-order permutations, missing and reappearing displays, ambiguous identity,
bounded allocation, replacement teardown, rapid panel changes, and failed persistence
followed by recovery. Include model and real-engine cases when service ownership
changes.

## Validation and operational limits

```sh
bash tests/run_all.sh --portable
```

Portable mode covers model and contract tests without desktop dependencies. The full `npm test` gate also requires Qt and Omarchy plugin validation. The portable suite does not prove live compositor behavior. Use TESTING.md for
explicitly authorized QML, live, stress, and screenshot checks. Never rearrange
workspaces or modify the persistent shell during routine repository checks.

## Working through Spec Kit

Use Spec Kit for new capabilities, architectural or security-sensitive changes,
migrations, and coordinated changes that need a written contract. Keep narrow fixes,
dependency updates, and prose maintenance in the normal PR workflow.

For a new feature, record observable acceptance criteria in `spec.md`, source ownership
and constitution checks in `plan.md`, and evidence-bearing work in `tasks.md` under the
feature directory created by Spec Kit. Resolve material unknowns before implementation.
Mark tasks complete only after their stated verification, and distinguish completed,
skipped, blocked, and manual checks. Retain completed feature documents as decision
history. Backfill finished work only when explicitly requested. Label those
specifications as retrospective baselines, record the inspected revision, and map
requirements to source and acceptance evidence. Separate observed behavior from
corrective requirements. Never imply the specification preceded its code or mark
unverified checks complete.

Keep `.specify/templates/`, `.specify/scripts/`, and generated Codex skills under their
integration manifests. Use this guide and the constitution for local customization.
Regenerate managed files through Spec Kit and verify that project-owned memory survives
updates. Follow `RELEASING.md` for push, merge, release or delivery, and recovery.

The retrospective specification register is [specs/README.md](../../specs/README.md).
