#!/usr/bin/env bash
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$plugin_dir"
node tests/model.test.js
node tests/property.test.js
node tests/manifest.test.js
node tests/contracts.test.js
node tests/release.test.js
node tests/site.test.js
omarchy_path=${OMARCHY_PATH:-/home/panda/.local/share/omarchy-overlay}
qmllint_bin=${QMLLINT:-qmllint}
"$qmllint_bin" -I "$omarchy_path/shell" BarWidget.qml SettingsPanel.qml Service.qml
if [[ ${OMARCHY_SKIP_VALIDATE:-0} != 1 ]]; then omarchy plugin validate "$plugin_dir"; fi
if [[ ${MMW_QML_TESTS:-auto} == always ]] || { [[ ${MMW_QML_TESTS:-auto} == auto ]] && [[ -S ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/wayland-1 ]] && shell_pid=$(quickshell list --all 2>/dev/null | awk '/Process ID:/{pid=$3}/omarchy-overlay/{print pid}') && [[ -n $shell_pid ]] && [[ $(quickshell ipc --pid "$shell_pid" call shell ping 2>/dev/null || true) == ok ]]; }; then
  before=$(quickshell list --all 2>/dev/null | awk '/Process ID:|Config path:/{sub(/^[[:space:]]+/,"");print}' | sort)
  tests/run_qml_runtime.sh
  after=$(quickshell list --all 2>/dev/null | awk '/Process ID:|Config path:/{sub(/^[[:space:]]+/,"");print}' | sort)
  [[ $before == "$after" ]] || { printf 'Persistent Quickshell inventory changed during tests.\n' >&2; exit 1; }
fi
