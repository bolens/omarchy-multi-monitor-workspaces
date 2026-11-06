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

## Woodpecker plugin validation

[Woodpecker](https://woodpecker.bolens.dev/repos) runs the plugin archive,
ShellCheck, behavior and QML lint checks on pull requests and pushes to `main`.
It uses the same immutable Omarchy toolchain image and v4.0.1 imports as
GitHub CI. The entry point is `bash scripts/woodpecker-plugin.sh` inside that
image. It requires network access only to fetch the pinned public imports
and any lockfile-based test dependencies; it receives no publishing secrets.

The required plugin check is `ci/woodpecker/pr/plugin`. Ordinary GitHub PR
and main runs skip the duplicate plugin jobs. Reusable callers retain hosted
plugin validation by default; signed release validation explicitly enables
`release_validation: true` before publication. Use Woodpecker for manual plugin
validation. Repository links, HTML/XML, workflow security,
compatibility canaries, macOS, development-image builds, Pages and signed release
publication retain their GitHub workflows. Native success does not replace those
checks or prove live desktop behavior. No release is created by validation CI.

Editor image changes select a real hosted Docker build and post-create smoke
under a non-root user with a read-only image and no host Docker socket. Review
native workflow image pins monthly and after security releases; Dependabot's
Dockerfile coverage does not discover `.woodpecker/` image references.

The pre-push hook defaults graphical runtime checks to `never`. Set
`MMW_QML_TESTS=always` for an explicitly owned graphical check; `npm test`
retains its documented auto-detection behavior.

## Woodpecker site accessibility

The native `site` workflow builds the existing Pages payload, runs its structure
tests, then runs `node scripts/audit-site.mjs` in the pinned official
Puppeteer/Chrome image. It requires an accessibility score exactly 1. The helper
awaits its own loopback HTTP listener and Chrome DevTools readiness, uses ephemeral
ports, and closes only its owned browser, profile, and server. It receives no
secrets or extra host capabilities.

Require `ci/woodpecker/pr/site` alongside the native plugin and existing hosted
checks. Ordinary PR and main runs use the pinned native browser audit; GitHub
continues the site build, structure, HTML/XML, link, and workflow-security checks.
Reusable callers retain hosted browser validation through `release_validation`
with its default `true`; signed releases explicitly enable it. Manual GitHub
workflow dispatch also retains the hosted audit, and Woodpecker supports a manual
site run. Forks still require native approval and receive no publishing secrets.

Publishing and platform checks retain their current workflows. Review the manual
browser-image digest pin alongside the other native image pins; Dependabot does
not update Woodpecker YAML.
