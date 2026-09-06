# Contributing

Keep changes focused, deterministic, and compatible with Omarchy Shell.

Before opening a pull request, review [ARCHITECTURE.md](ARCHITECTURE.md), update
tests for behavior changes, and run the validation documented in
[TESTING.md](TESTING.md). Use an issue first for substantial interface,
persistence, security, or compatibility changes.

```sh
git clone https://github.com/bolens/omarchy-multi-monitor-workspaces.git
cd omarchy-multi-monitor-workspaces
MMW_QML_TESTS=never npm test
npm run hooks:install
```

The pre-commit hook validates the staged release payload and runs the
deterministic suite. Graphical and live IPC checks remain explicit.

Pull requests should explain the problem, chosen behavior, user-visible impact,
and exact validation performed. Update `CHANGELOG.md` and documentation for
user-facing changes. Include visual evidence for layout changes. Never include
secrets, private paths, personal monitor names, or unrelated logs.

By contributing, you agree that your contribution is licensed under the MIT
license in [LICENSE](LICENSE) while existing upstream notices remain intact.

## Reproducible tools

See the [development environment guide](docs/development-environments.md) for devenv and local Docker, Podman, or Apple container validation.
