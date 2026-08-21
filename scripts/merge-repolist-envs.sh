#!/bin/bash

set -euo pipefail

repolist_file="${1:-/opt/repolist.txt}"
output_file="${2:-/opt/repolist_merged.yml}"

if [[ ! -f "$repolist_file" ]]; then
    printf 'Error: repolist file not found: %s\n' "$repolist_file" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mapfile -t env_sources < <(grep -vE '^[[:space:]]*(#|$)' "$repolist_file")

if [[ ${#env_sources[@]} -eq 0 ]]; then
    printf 'Error: no environment sources found in %s\n' "$repolist_file" >&2
    exit 1
fi

downloaded_envs=()

for env_source in "${env_sources[@]}"; do
    env_name="$(basename "${env_source%%\?*}")"

    if [[ "$env_name" != *.yml && "$env_name" != *.yaml ]]; then
        env_name="${env_name}.yml"
    fi

    target_file="$tmp_dir/$env_name"

    if [[ "$env_source" == http://* || "$env_source" == https://* ]]; then
        curl --fail --silent --show-error --location --retry 5 --retry-all-errors --retry-delay 2 -o "$target_file" "$env_source"
    elif [[ -f "$env_source" ]]; then
        cp "$env_source" "$target_file"
    else
        printf 'Error: environment source not found: %s\n' "$env_source" >&2
        exit 1
    fi

    downloaded_envs+=("$target_file")
done

pixi run conda-merge "${downloaded_envs[@]}" > "$output_file"