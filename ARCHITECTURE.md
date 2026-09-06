# Architecture

[Documentation](DOCUMENTATION.md)

`Model.js` owns pure sanitization, stable monitor-to-bank mapping, workspace numbering, navigation, labels, and legacy migration. It has no QML or host dependencies.

`Service.qml` is the sole mutable owner, monitor-topology authority, workspace-bank allocator, and IPC endpoint. It losslessly coalesces settings writes, keeps failed writes retryable, and registers one current presentation per monitor with monotonically increasing generations so stale QML destruction cannot remove replacements. A separate topology serial invalidates every presentation atomically on both attach and detach. Its revision floor comes from the current inline `shell.shellConfig` entry, so reconstruction cannot accept an older presentation snapshot.

Settings commits merge field intent against the latest inline entry. If that entry disappears between queueing and commit, the service does not recreate it; intent remains pending and is retried only after a current entry reappears. Settings routing accepts only currently registered monitor presentations, preventing a detached widget from reopening a stale panel.

Persistence and request failures have separate lifetimes. Successful IPC cannot hide an unresolved settings commit, and service health remains degraded until persistence recovers. Replacing a live presentation for the same screen closes the displaced panel before publishing its successor without treating the replacement as a topology change.

`BarWidget.qml` is a monitor-local projection. It reads workspace activity from Hyprland but obtains its bank from the service's shared registered-monitor snapshot, renders that bank, performs actions through the stock bar runner, and owns one settings panel. It never owns IPC or global allocation policy.

`SettingsPanel.qml` is a bounded, fully scrollable editor. All helper text wraps within the content width and mutations go through the service.
