#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
output_dir="$repo_root/_site"
python3 "$repo_root/scripts/render-changelog.py" --name "Multi-Monitor Workspaces" --base-url https://bolens.github.io/omarchy-multi-monitor-workspaces/ --accent "#88c0d0" --source "$repo_root/CHANGELOG.md" --output "$repo_root/docs/changelog/index.html"
version=${SITE_RELEASE_VERSION:-$(jq -er '.version | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))' "$repo_root/manifest.json")}
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]] || { echo "invalid site release version: $version" >&2; exit 1; }
rm -rf -- "$output_dir"
cp -R -- "$repo_root/docs" "$output_dir"
cp -- "$repo_root/preview.png" "$output_dir/preview.png"
cp -- "$repo_root/manifest.json" "$output_dir/manifest.json"
sed -i "s/{{VERSION}}/$version/g" "$output_dir/index.html"
