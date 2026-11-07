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
ShellCheck, behavior, strict QML controls and complete canonical headless runtime
suite on pull requests and pushes to `main`. Its pinned toolchain and v4.0.1
imports also serve retained GitHub callers. Preparation runs
`bash scripts/woodpecker-plugin.sh --prepare` to fetch only immutable public
imports. The required `--offline` phase runs as container user 10042 with
networking disabled; test dependencies are already in the image. Neither phase
receives publishing secrets.

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

## Strict QML import preparation

Inside the qualified CI toolchain, use the same preparation entry point as the
native and retained hosted gates:

```sh
bash scripts/with-qml-imports.sh "$OMARCHY_PATH/shell" bash tests/run_all.sh
```

Use the clean `shell` subtree from Omarchy commit
`13f18b2cb7286fb54f87daf571a031aa6af3d8f0`. The source profile checks every one of
its 175 files, including Git blob hashes and executable modes, before copying it
into an owned temporary directory. It backports the upstream
[`b83d3df` palette qualification](https://github.com/omacom/omarchy/commit/b83d3df0840504299d3099ebf391eb8110527edd)
and gives the eleven existing anonymous token objects named component types.
Every field body and readonly slot is preserved. The installed shell is unchanged.
Unknown source contents fail preparation; the experimental compatibility canary
reports that gap rather than silently adapting an unreviewed upstream revision.

The tooling helper verifies the exact Quickshell/Qt package versions and all 72
Quickshell import files. Its private metadata copy resolves source-backed core
Margins, PopupAnchor, ObjectModel and flag typedefs; installed package files remain unchanged.
`QML_TOOLING_IMPORT_ROOT` selects that copy first with `qmllint --bare` and explicit
system imports. Runtime engines use the real installed package metadata.

The policy rejects warnings. Real-linter controls must accept a supported nested
font field and reject an invalid property, nested field and type with the expected
diagnostic. A successful subprocess with the wrong diagnostic does not pass.
Preparation, source lint and these controls are separate from the explicit QML
runtime suite; a static pass does not prove live desktop behavior. Run runtime
harnesses only with owned HOME/XDG roots and an isolated display appropriate to
the harnesses. Window tests require a real layer-shell compositor, not the
offscreen backend. See the QML warning validation feature's
[acceptance plan](specs/005-qml-warning-validation/plan.md).

If Qt 6.12 `qmllint` fails with empty text output, repeat its exact command with
`--json -` to read the structured diagnostics. Keep the same inputs, policy and
import arguments. Loop-analysis diagnostics can remain in the structured result
when Qt's text output is empty; an empty log never overrides a failing exit code.
Acceptance requires the complete target inventory and zero structured diagnostics.

## Required native QML validation

Woodpecker prepares only the immutable public Omarchy source in its first step.
The required plugin step then runs as container user 10042 with networking
disabled. It validates the source and tooling profiles, portable checks, strict
QML lint and real invalid controls before running every harness registered in
`tests/run_qml_runtime.sh` through `scripts/qml-runtime-fixture.py`. Optional
desktop-test selection variables do not skip this owned runtime gate.

The fixture uses private HOME/XDG roots, canonical default typography and the
packaged font resolver. Window tests use a software headless compositor; Privacy
tests also use an isolated PipeWire registry without hardware nodes. Protocol
roundtrips establish readiness. Existing harness deadlines and natural exits
remain required; Privacy shutdown also checks the owned configuration is absent.
No host display, audio socket, device, Docker socket or privilege is required.

Each result retains its raw output in CI logs. Only exact, source-bound warnings
from explicitly asserted negative tests may pass; additional Qt, binding, type
or deprecation warnings fail. The palette contract checks all 87 declared token
fields plus eleven inherited object names, stable identities, readonly owners,
permitted child writes and reactive restoration. A missing harness, marker or
cleanup result fails validation.
