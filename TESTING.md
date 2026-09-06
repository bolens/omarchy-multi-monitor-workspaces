# Testing

[Documentation](DOCUMENTATION.md)

Run `npm test`. On a live Wayland session, the command launches short-lived,
path-specific QML harnesses. It then verifies that the persistent Quickshell
inventory did not change. Set `MMW_QML_TESTS=never` for static checks or
`MMW_QML_TESTS=always` to require runtime coverage.

Runtime harnesses are killed by their exact temporary config path; they never use global Quickshell termination.

After deploying, run `npm run verify:live` for panel, topology, allocation-snapshot, bank, and IPC health checks. Run `npm run verify:stress` for a reversible live test of glyph persistence, 100 alternating monitor-panel cycles, exact settings restoration, and persistent Quickshell process identity. The stress verifier always closes the panel and attempts restoration through an exit trap.

Pure tests exercise attach-order permutations with 1, 2, 3, 8, 16, 32, 64,
and 100 outputs. Those cases cover the full bounded bank range. The QML service
harness adds 32 presentations, removes alternating outputs, checks for overlap,
and verifies exact topology invalidation. It also retains the current widget
when a stale widget tears down.

The service harness also covers rapid cross-monitor panel ownership, detached-widget routing rejection, queued writes racing an entry removal, retained intent, and recovery against a newer reappeared entry without overwriting its unrelated fields.

Replacement tests use distinct old and new widget objects, require the displaced panel to close, and verify that stale teardown cannot remove the successor. Error-lifetime tests require successful IPC to preserve an unresolved persistence failure and unhealthy status until a real commit succeeds.

CI validates against Omarchy v4.0.1. A weekly compatibility workflow also runs
against the current `quattro` branch. CI runs ShellCheck, Actionlint, link
checks, HTML and XML validation, and requires a Lighthouse accessibility score
of 1.00.

## Capture visual evidence

Run the reversible visual check against the existing shell:

```sh
scripts/capture-screenshots --verify
```

To retain the evidence, pass an empty directory below `/tmp`:

```sh
audit_dir=$(mktemp -d /tmp/mmw-audit.XXXXXX)
scripts/capture-screenshots --audit-dir "$audit_dir" --report "$audit_dir/report.json"
```

The script captures number, hybrid, and glyph modes on every attached monitor.
It also captures the top and bottom of the selected monitor's settings panel.
The exit trap restores the exact settings object and the prior open panel. The
script fails if restoration or Quickshell process identity changes.

## Portable development gate

Run `bash tests/run_all.sh --portable` for deterministic Node and container-adapter tests without a desktop installation. This explicit mode reports the omitted Qt, plugin archive, and QML runtime checks. The default `npm test` gate retains those checks. Live topology, IPC, and stress verification remain explicit host operations.
