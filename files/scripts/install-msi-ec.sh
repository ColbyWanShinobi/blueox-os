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

# On an OSTree system akmods.service does not run after boot, so an akmod
# installed into the image would otherwise never produce its kernel module.
# Build and unpack the kmod while the image is composed instead.
MSI_EC_AKMOD_SRPM="$(rpm -ql akmod-msi-ec | awk '/\.src\.rpm$/ { print; exit }')"
if [[ -z "$MSI_EC_AKMOD_SRPM" ]]; then
  echo 'Could not locate the MSI EC akmod source RPM.' >&2
  exit 1
fi

echo 'Building the MSI EC module for the image kernel...'
sudo /usr/sbin/akmods-ostree-post msi-ec "$MSI_EC_AKMOD_SRPM"

# The package produces a module named `msi_ec` (underscore), while the
# userspace application checks for the platform device created by that module.
# Keep an explicit module-load rule even though the package also supplies one.
echo 'Configuring the MSI EC module to load at boot...'
sudo install -d -m 0755 /etc/modules-load.d
printf '%s\n' msi_ec | sudo tee /etc/modules-load.d/msi_ec.conf >/dev/null
