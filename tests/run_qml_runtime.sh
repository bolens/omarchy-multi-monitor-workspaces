#!/usr/bin/env bash
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
runtime_dir=$(mktemp -d)
quickshell_bin=${QUICKSHELL_BIN:-$(command -v quickshell || command -v qs)}
shell_root=${OMARCHY_SHELL_ROOT:-/home/panda/.local/share/omarchy-overlay/shell}
active_harness=""
cleanup() { if [[ -n $active_harness ]]; then "$quickshell_bin" kill --path "$active_harness" --any-display >/dev/null 2>&1 || true; fi; rm -rf -- "$runtime_dir"; }
trap cleanup EXIT INT TERM
leaked_runtime_processes() {
  "$quickshell_bin" list --all 2>/dev/null | awk -v root="$runtime_dir/" '
    /^Process ID:/ { pid=$3 }
    /^Config path:/ {
      sub(/^[[:space:]]+/, "")
      path=$0
      sub(/^Config path: /, "", path)
      if (index(path, root) == 1) print pid "\t" path
    }
  '
}

wait_for_runtime_teardown() {
  local leaks
  for _attempt in {1..100}; do
    leaks=$(leaked_runtime_processes || true)
    [[ -z $leaks ]] && return 0
    sleep 0.02
  done
  printf '%s\n' "$leaks"
  return 1
}
find "$plugin_dir" -maxdepth 1 -type f \( -name '*.qml' -o -name '*.js' \) -exec ln -s -- '{}' "$runtime_dir/" \;
find "$plugin_dir/tests/qml" -type f -name 'Runtime*Test.qml' -exec ln -s -- '{}' "$runtime_dir/" \;
ln -s -- "$shell_root/Commons" "$runtime_dir/Commons"
ln -s -- "$shell_root/Ui" "$runtime_dir/Ui"
run_test() {
  local file=$1 marker=$2 output status leaks
  active_harness="$runtime_dir/$file"; set +e; output=$(timeout 8 "$quickshell_bin" --no-color --path "$active_harness" 2>&1); status=$?; set -e
  "$quickshell_bin" kill --path "$active_harness" --any-display >/dev/null 2>&1 || true; active_harness=""
  leaks=$(wait_for_runtime_teardown || true)
  [[ -z $leaks ]] || { printf 'Leaked Quickshell runtime harnesses after %s:\n%s\n' "$file" "$leaks" >&2; return 1; }
  [[ $status -eq 0 ]] || { printf '%s\n' "$output" >&2; return "$status"; }
  grep -q "$marker" <<<"$output" || { printf '%s\n' "$output" >&2; return 1; }
  ! grep -Eq 'Binding loop|TypeError:|ReferenceError:|Cannot assign|Unable to assign' <<<"$output" || { printf '%s\n' "$output" >&2; return 1; }
}
run_test RuntimeModelTest.qml MMW_QML_MODEL_OK
run_test RuntimeServiceTest.qml MMW_QML_SERVICE_OK
run_test RuntimeSettingsTest.qml MMW_QML_SETTINGS_OK
run_test RuntimeAccessibilityTest.qml MMW_QML_ACCESSIBILITY_OK
runtime_leaks=$(leaked_runtime_processes || true)
[[ -z $runtime_leaks ]] || { printf 'Leaked Quickshell runtime harnesses:\n%s\n' "$runtime_leaks" >&2; exit 1; }
