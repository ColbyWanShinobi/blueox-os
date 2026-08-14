#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if ! command -v bluebuild >/dev/null 2>&1; then
  command -v podman >/dev/null 2>&1 || { echo 'error: Podman is required to install BlueBuild' >&2; exit 1; }
  command -v sudo >/dev/null 2>&1 || { echo 'error: sudo is required to install BlueBuild' >&2; exit 1; }
  sudo -v
  podman run --pull always --rm ghcr.io/blue-build/cli:v0.9-installer | sudo bash
fi

mkdir -p "$repo_root/.logs"
exec bluebuild --log-out "$repo_root/.logs" validate "$repo_root/recipes/redux.yml"
