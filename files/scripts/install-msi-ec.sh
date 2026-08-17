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
#
# Fedora 44 prevents akmodsbuild from running as root.  The stock
# akmods-ostree-post helper therefore cannot be used during image composition:
# it calls akmodsbuild as root.  Build as the unprivileged account supplied by
# the akmods package, then unpack the generated kmod RPMs as root.  Unpacking
# mirrors the successful half of akmods-ostree-post.
MSI_EC_AKMOD_SRPM="$(rpm -ql akmod-msi-ec | awk '/\.src\.rpm$/ { print; exit }')"
if [[ -z "$MSI_EC_AKMOD_SRPM" ]]; then
  echo 'Could not locate the MSI EC akmod source RPM.' >&2
  exit 1
fi

if ! id akmods >/dev/null 2>&1; then
  echo 'The akmods build user is unavailable.' >&2
  exit 1
fi

mapfile -t IMAGE_KERNELS < <(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
if [[ "${#IMAGE_KERNELS[@]}" -eq 0 ]]; then
  echo 'Could not locate an image kernel to build MSI EC for.' >&2
  exit 1
fi

BUILD_DIR="$(mktemp -d /var/tmp/msi-ec-kmod-build.XXXXXX)"
readonly BUILD_DIR
trap 'rm -rf -- "$BUILD_DIR"' EXIT
chown akmods:akmods "$BUILD_DIR"

echo 'Building the MSI EC module for the image kernel(s)...'
for kernel in "${IMAGE_KERNELS[@]}"; do
  runuser -u akmods -- akmodsbuild --kernels "$kernel" --outputdir "$BUILD_DIR" "$MSI_EC_AKMOD_SRPM"
done

shopt -s nullglob
KMOD_RPMS=("$BUILD_DIR"/*.rpm)
if [[ "${#KMOD_RPMS[@]}" -eq 0 ]]; then
  echo 'MSI EC akmods build did not produce a kernel-module RPM.' >&2
  exit 1
fi

echo 'Installing the built MSI EC kernel module(s)...'
for kmod_rpm in "${KMOD_RPMS[@]}"; do
  rpm2cpio "$kmod_rpm" | cpio --quiet -D / -id
done

for kernel in "${IMAGE_KERNELS[@]}"; do
  depmod "$kernel"
done

# The package produces a module named `msi_ec` (underscore), while the
# userspace application checks for the platform device created by that module.
# Keep an explicit module-load rule even though the package also supplies one.
echo 'Configuring the MSI EC module to load at boot...'
sudo install -d -m 0755 /etc/modules-load.d
printf '%s\n' msi_ec | sudo tee /etc/modules-load.d/msi_ec.conf >/dev/null
