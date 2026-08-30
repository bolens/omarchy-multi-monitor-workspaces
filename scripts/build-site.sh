#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
output_dir="$repo_root/_site"
version=$(jq -er '.version | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))' "$repo_root/manifest.json")
rm -rf -- "$output_dir"
cp -R -- "$repo_root/docs" "$output_dir"
cp -- "$repo_root/preview.png" "$output_dir/preview.png"
cp -- "$repo_root/manifest.json" "$output_dir/manifest.json"
sed -i "s/{{VERSION}}/$version/g" "$output_dir/index.html"
