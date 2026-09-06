# Tasks

- [x] Implement locked environment, explicit portable mode, adapters, and regression coverage.
- [x] Pass native devenv and actual Podman validation.
- [x] Verify native Linux/macOS and Linux Docker checks on the recorded main revision.
- [x] Verify merged source delivery and the applicable main-revision workflows.

Historical pre-merge observation (superseded by the receipt below):
Native devenv and actual rootless Podman passed all Node suites and five adapter regressions. Linux Docker and native macOS CI remain pending; Apple runtime execution is unavailable on this host.

## Delivery verification — 2026-09-06

The [development workflow](https://github.com/bolens/omarchy-multi-monitor-workspaces/actions/runs/34030918200) passed on
`2f09f59f48460bb6174164bd3047063a7836e592`. Both native platform jobs ran successfully;
the Linux job also executed and passed the Docker development-image check. All
applicable workflows observed for that main revision completed successfully.

Actual Apple container-engine execution remains unverified. Native macOS devenv
validation does not establish that engine's runtime behavior. Existing live-host
and optional dependency limits still apply. Checkout cleanup remains part of each
task's delivery procedure and is not inferred from CI success.
