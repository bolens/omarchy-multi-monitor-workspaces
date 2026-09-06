# Plan: Workspace banks and serialized monitor settings

The [specification](spec.md) preserves existing behavior. Use the project guide
and constitution for implementation constraints. Keep upstream-managed templates,
helpers, and integration manifests unchanged.

## Source ownership

- `Model.js`
- `Service.qml`
- `BarWidget.qml`
- `SettingsPanel.qml`
- `manifest.json`
- `tests/property.test.js`
- `tests/model.test.js`
- `tests/qml`

## Constitution check

Preserve stock-shell compatibility, explicit mutation authority, deterministic ownership, private data boundaries, and isolated verification. This retrospective documentation change adds no runtime behavior, deployment, or release tag.

## Validation

```sh
MMW_QML_TESTS=never npm test
```

Run checks in an isolated checkout. Commands are instructions, not evidence of
a pass. Record results in `coverage.md`, keep incomplete work in `tasks.md`, and
follow `RELEASING.md` for reviewed delivery. No live operation is required solely
to create this retrospective baseline.
