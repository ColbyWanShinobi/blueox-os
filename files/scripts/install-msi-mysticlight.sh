#!/usr/bin/env bash

# Install the MSI Mystic Light utility from its pinned Fedora 44 release.
set -euo pipefail

readonly RPM_URL='https://github.com/ColbyWanShinobi/msi-delta15-mysticlight-1564/releases/download/v1.0.0/msi-mysticlight-1.0.0-1.fc44.noarch.rpm'
RPM_PATH="$(mktemp --suffix=.rpm)"
readonly RPM_PATH

cleanup() {
  rm -f "$RPM_PATH"
}
trap cleanup EXIT

command -v curl >/dev/null 2>&1 || {
  echo 'curl is required to install MSI Mystic Light.' >&2
  exit 1
}
command -v dnf >/dev/null 2>&1 || {
  echo 'dnf is required to install MSI Mystic Light.' >&2
  exit 1
}

echo 'Downloading MSI Mystic Light RPM...'
curl --fail --location --show-error --silent --output "$RPM_PATH" "$RPM_URL"

echo 'Installing MSI Mystic Light...'
dnf install -y "$RPM_PATH"
