# Multi-Monitor Workspaces for Omarchy

A hard fork of `derluke/omarchy-dual-monitor-workspaces` with deterministic
workspace banks for any number of monitors. It keeps the existing Omarchy bar
UI and adds guarded settings persistence, per-monitor routing, appearance
controls, wheel navigation, and one service-owned IPC interface.

[User guide](https://bolens.github.io/omarchy-multi-monitor-workspaces/) · [Report an issue](https://github.com/bolens/omarchy-multi-monitor-workspaces/issues/new/choose) · [Security policy](SECURITY.md)

## Behavior

- Each output receives a non-overlapping workspace bank (10 workspaces by default).
- Explicit `monitorBanks` overrides win, followed by `monitorPriority` and
  connected output names in alphabetical order. The allocator resolves
  duplicate overrides without overlap. It does not use Hyprland monitor IDs
  because those IDs can change after a reconnect.
- Monitor presentations register with one shared topology owner. Attach,
  detach, replacement, and reordered enumeration recalculate all banks from
  the monitors with live bars. A stale teardown cannot remove a replacement.
- Label modes include local numbers, global IDs, state glyphs, and hybrid (active glyph, accent-colored occupied numbers, inactive empty numbers).
- Left click follows the configured action; middle click moves silently; right click opens settings; the wheel navigates within the current monitor bank.
- Empty workspaces remain visible by default, preserving persistent workspace access.

The widget only reads Quickshell's Hyprland model and uses the existing bar command runner for workspace actions. It does not launch processes, shells, or extra Quickshell instances.

## Install

```sh
omarchy plugin add https://github.com/bolens/omarchy-multi-monitor-workspaces.git --enable
omarchy plugin disable omarchy.workspaces
omarchy bar move io.github.bolens.multi-monitor-workspaces --section left --after omarchy.menu
```

The local repository retains upstream history and its remote so a GitHub fork can be attached later. The active hard-fork identity is `io.github.bolens.multi-monitor-workspaces`.

## Settings

Right-click any workspace entry to open settings. The scrollable panel controls
bank size, per-output bank overrides, label and click modes, empty workspaces,
tooltips, wheel behavior, glyphs, sizing, theme roles, and opacity. Optional
glyphs use global workspace IDs, so gaming, social, music, and coding markers
stay attached to the same workspaces.

Settings are sanitized, bounded, losslessly coalesced for 75 ms, and persisted through Omarchy's inline-entry API. Failed writes retain their pending field intent while the persisted last-known-good entry remains unchanged. A queued write cannot resurrect a concurrently removed plugin entry; it retries against the latest entry only if one reappears. Revisions are anchored in `shell.json`, preventing stale monitor presentations from winning during hot reload or service reconstruction.

Persistence failures remain visible and keep service health degraded even if unrelated IPC succeeds. Same-screen widget replacement closes the displaced panel before the new presentation becomes authoritative.

## IPC

The service target is `multi-monitor-workspaces`:

```sh
qs ipc call multi-monitor-workspaces status
qs ipc call multi-monitor-workspaces registeredMonitors
qs ipc call multi-monitor-workspaces workspaceIds DP-1
qs ipc call multi-monitor-workspaces activate DP-1 4 focus
qs ipc call multi-monitor-workspaces openMonitorAppearance DP-1
qs ipc call multi-monitor-workspaces closeSettings
qs ipc call multi-monitor-workspaces setSettings '{"count":10,"labelMode":"number"}'
qs ipc call multi-monitor-workspaces resetSettings
```

## Development and tests

Run `npm test`, or `MMW_QML_TESTS=always npm test` to require live QML coverage. The suite covers pure model boundaries, malformed settings, deterministic mappings, migration idempotence, manifest/runtime contracts, QML behavior, registration generations, stale teardown, targeted settings, persistence, IPC, linting, validation, and persistent Quickshell inventory preservation. Deployed builds also provide `npm run verify:live` and the reversible `npm run verify:stress` live-runtime checks.

Run `scripts/capture-screenshots --verify` to exercise number, hybrid, glyph,
and settings layouts without retaining files. Pass an empty directory below
`/tmp` with `--audit-dir` to review the PNGs. The script captures every attached
monitor, restores the exact settings object and open panel, and checks that the
Quickshell process inventory does not change.

## Credits and license

This is a modified hard fork of [Omarchy Dual Monitor Workspaces](https://github.com/derluke/omarchy-dual-monitor-workspaces), originally created by Lukas Innig and derived from Omarchy's workspace widget by 37signals LLC. Hard-fork architecture and expanded behavior are by bolens. The upstream notices are preserved under the MIT license in [LICENSE](LICENSE); see [NOTICE](NOTICE) for provenance.
