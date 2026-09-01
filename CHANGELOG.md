# Changelog

All notable changes to Multi-Monitor Workspaces are documented here. The
project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- Delegate `pull-requests: read` to the reusable validation workflow so
  future tag-triggered releases can start after CI path filtering was introduced.

## [2.2.4] - 2026-09-01

### Fixed

- Preserve QML-backed monitor-priority lists across settings save,
  serialization, and reload while rejecting malformed or oversized array-like
  values with a single bounded length snapshot.
- Replace comma-expression dependency bindings surfaced by Qt 6 linting.
- Require Qt 6 QML tooling, publish plugin module metadata, and gate reliable
  semantic lint errors in local and CI validation.

## [2.2.3] - 2026-08-31

### Changed

- Align CI, release, dependency, runtime, and archive policies with the
  maintained plugin suite.
- Route Quickshell inventory and leak checks through the configured executable.
- Validate the tracked release payload locally and run staged-tree checks from
  the repository pre-commit hook.

### Fixed

- Isolate every recorded monitor on a verified empty workspace during visual
  capture and restore each monitor independently.

## [2.2.2] - 2026-08-30

### Added

- Add deterministic monitor-bank allocation, per-workspace glyphs, appearance
  settings, guarded IPC, and compact monitor-aware settings.
- Add pure, randomized, real-QML, topology, persistence-race, and live stress
  coverage through the full bounded monitor-bank range.
- Add a distinct GitHub Pages guide for allocation, hotplug behavior,
  appearance, IPC, and installation.
- Add pinned CI, release automation, governance documents, and repository
  validation for the maintained hard fork.
- Add reversible multi-monitor visual capture for number, hybrid, glyph, and
  settings layouts.
- Add supported-release and weekly upstream Omarchy compatibility checks.
- Add release artifact attestations and a 1.00 accessibility gate.

### Changed

- Centralize settings, topology, allocation, and IPC ownership in one service.
- Preserve the hybrid active-glyph and occupied/empty number presentation.

[Unreleased]: https://github.com/bolens/omarchy-multi-monitor-workspaces/compare/v2.2.4...HEAD
[2.2.4]: https://github.com/bolens/omarchy-multi-monitor-workspaces/compare/v2.2.3...v2.2.4
[2.2.3]: https://github.com/bolens/omarchy-multi-monitor-workspaces/compare/v2.2.2...v2.2.3
[2.2.2]: https://github.com/bolens/omarchy-multi-monitor-workspaces/releases/tag/v2.2.2
