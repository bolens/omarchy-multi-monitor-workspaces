# Development environments

Provide a locked devenv shell and source-free development image for workspace allocation, stable monitor identity, model, manifest, site, and adapter tests. Add an explicit portable mode that requires no Qt, Omarchy installation, or Wayland session. Preserve the full test default and its plugin/QML validation.

Acceptance: all deterministic Node and adapter tests run on Linux and macOS; invalid runner options fail. Docker, Podman, and Apple adapters preserve command arguments and caller ownership. Development-only files remain excluded from plugin archives. No live topology is changed.
