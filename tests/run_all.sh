#!/usr/bin/env bash
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$plugin_dir"
quickshell_bin=${QUICKSHELL_BIN:-$(command -v quickshell || command -v qs || true)}

persistent_shell_inventory() {
  [[ -n $quickshell_bin ]] || return 0
  "$quickshell_bin" list --all 2>/dev/null | awk '
    /^Process ID:/ { pid=$3 }
    /^Config path:/ {
      sub(/^[[:space:]]+/, "")
      path=$0
      sub(/^Config path: /, "", path)
      if (index(path, "/tmp/") != 1) {
        print "Process ID: " pid
        print "Config path: " path
      }
    }
  ' | sort
}
for test_file in tests/*.test.js; do
  node "$test_file"
done
omarchy_path=${OMARCHY_PATH:-/home/panda/.local/share/omarchy-overlay}
qmllint_bin=${QMLLINT:-/usr/lib/qt6/bin/qmllint}
[[ -x "$qmllint_bin" ]] || { printf 'Qt 6 qmllint not found: %s\n' "$qmllint_bin" >&2; exit 1; }
"$qmllint_bin" -I "$omarchy_path/shell" -i "$plugin_dir/qmldir" \
  -i "$omarchy_path/shell/Commons/qmldir" -i "$omarchy_path/shell/Ui/qmldir" \
  Button.qml WidgetButton.qml BarWidget.qml SettingsPanel.qml Service.qml
if [[ ${OMARCHY_SKIP_VALIDATE:-0} != 1 ]]; then
  validation_dir=$(mktemp -d)
  trap 'rm -rf -- "$validation_dir"' EXIT
  git archive HEAD | tar -x -C "$validation_dir"
  omarchy plugin validate "$validation_dir"
  rm -rf -- "$validation_dir"
  trap - EXIT
fi
if [[ ${MMW_QML_TESTS:-auto} == always ]] || { [[ ${MMW_QML_TESTS:-auto} == auto ]] && [[ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/wayland-1" ]] && shell_pid=$(quickshell list --all 2>/dev/null | awk '/Process ID:/{pid=$3}/omarchy-overlay/{print pid}') && [[ -n $shell_pid ]] && [[ $(quickshell ipc --pid "$shell_pid" call shell ping 2>/dev/null || true) == ok ]]; }; then
  before=$(persistent_shell_inventory)
  tests/run_qml_runtime.sh
  after=$(persistent_shell_inventory)
  [[ $before == "$after" ]] || { printf 'Persistent Quickshell inventory changed during tests.\n' >&2; exit 1; }
fi
