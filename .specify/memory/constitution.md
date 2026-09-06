# Multi-Monitor Workspaces Constitution

[Documentation](../../DOCUMENTATION.md)

## Core Principles

### I. Stable Workspace Ownership

Monitor and workspace mappings MUST remain deterministic across startup, reload, hotplug, and display-order changes. Stable monitor identity takes precedence over transient enumeration order.

### II. Preserve User State

Settings saves and migrations MUST preserve unrelated shell configuration and normalize only owned fields. Reloads MUST reproduce the last successful persisted state.

### III. Stock-Shell Compatibility

The plugin MUST use documented Omarchy and Quickshell extension points without launching duplicate shell processes or assuming private host state.

### IV. Synchronized QML Contracts

Module metadata, properties, defaults, settings UI, IPC, documentation, and tests MUST remain aligned. Optional capabilities degrade cleanly.

### V. Isolated Verification

Tests MUST isolate HOME, XDG, compositor, and Quickshell state. Topology cases cover reordered, missing, added, and ambiguous displays without mutating the live session.

## Governance

Architecture and testing documentation define detailed behavior. Mapping or persistence exceptions require rationale, regression coverage, and a constitution version update.

**Version**: 1.0.0 | **Ratified**: 2026-09-02 | **Last Amended**: 2026-09-02
