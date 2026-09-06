# Requirement coverage

| Requirement | Source and acceptance evidence |
| --- | --- |
| FR-001 | `Model.js:assignedBankMap`, `bankIndex`, and `workspaceIds`; randomized tests exercise 1–100 outputs, overrides, ordering, and bounded counts. |
| FR-002 | `registerWidget`, `unregisterWidget`, and topologySerial; contracts and RuntimeServiceTest.qml. |
| FR-003 | `updateSettings`, `configure`, and commit path in Service.qml; RuntimeServiceTest.qml entry-removal/recovery cases. |
| FR-004 | Separate persistenceError and requestError in Service.qml; runtime failure/recovery cases. |
| FR-005 | `isRegisteredInstance`, `openSettingsFor`, and replacement closure; runtime panel ownership cases. |
| FR-006 | Model sanitization/labels/scroll targets, SettingsPanel.qml, manifest and contracts tests. |

## Verification receipt

On 2026-09-05: The portable gate passed JavaScript model/property/contracts, QML lint, and clean-archive plugin validation. Live controls and graphical runtime harnesses were not run. A separate self-review traced the listed source owners, mutation/observation boundaries, failure paths, and test assertions. No corrective runtime gap was established within this retrospective contract; real-engine and live operational evidence remain explicitly separate. Hosted delivery evidence belongs to the PR.
