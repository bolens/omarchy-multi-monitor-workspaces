# Tasks

- [x] Implement locked environment, explicit portable mode, adapters, and regression coverage.
- [x] Pass native devenv and actual Podman validation.
- [ ] Verify archive exclusions and current-head Linux Docker/macOS CI.
- [ ] Complete protected merge, post-merge CI, and cleanup.

Native devenv and actual rootless Podman passed all Node suites and five adapter regressions. Linux Docker and native macOS CI remain pending; Apple runtime execution is unavailable on this host.
