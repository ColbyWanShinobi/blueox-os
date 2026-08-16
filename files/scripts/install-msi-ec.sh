#!/usr/bin/env bash

set -euo pipefail

MSI_EC_COMMON_RPM='https://github.com/ColbyWanShinobi/msi-ec/releases/download/v0.13/msi-ec-kmod-common-0.13-2.fc44.noarch.rpm'
AKMOD_MSI_EC_RPM='https://github.com/ColbyWanShinobi/msi-ec/releases/download/v0.13/akmod-msi-ec-0.13-2.fc44.x86_64.rpm'

if ! command -v dnf >/dev/null 2>&1; then
  echo 'This installer requires dnf.' >&2
  exit 1
fi

echo 'Installing MSI EC kernel-module packages...'
sudo dnf install -y "$MSI_EC_COMMON_RPM" "$AKMOD_MSI_EC_RPM"
