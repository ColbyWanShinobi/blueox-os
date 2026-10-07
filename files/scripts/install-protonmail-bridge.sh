#!/usr/bin/env bash

# Layer Proton Mail Bridge's current x86_64 RPM into the image. The stable
# endpoint serves the current upstream release, avoiding a stale version pin.
set -euo pipefail

readonly RPM_URL='https://proton.me/download/bridge/protonmail-bridge.x86_64.rpm'
readonly RPM_PATH="$(mktemp --suffix=.rpm)"

cleanup() {
  rm -f "$RPM_PATH"
}
trap cleanup EXIT

command -v curl >/dev/null 2>&1 || {
  echo 'curl is required to install Proton Mail Bridge.' >&2
  exit 1
}
command -v rpm-ostree >/dev/null 2>&1 || {
  echo 'rpm-ostree is required to install Proton Mail Bridge.' >&2
  exit 1
}

echo 'Downloading Proton Mail Bridge RPM...'
curl --fail --location --show-error --silent --output "$RPM_PATH" "$RPM_URL"

echo 'Installing Proton Mail Bridge...'
rpm-ostree install -y "$RPM_PATH"
