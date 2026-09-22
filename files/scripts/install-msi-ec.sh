#!/usr/bin/env bash

set -euo pipefail

MSI_EC_COMMON_RPM='https://github.com/ColbyWanShinobi/msi-ec/releases/download/v0.13/msi-ec-kmod-common-0.13-2.fc44.noarch.rpm'
AKMOD_MSI_EC_RPM='https://github.com/ColbyWanShinobi/msi-ec/releases/download/v0.13/akmod-msi-ec-0.13-2.fc44.x86_64.rpm'

if ! command -v rpm-ostree >/dev/null 2>&1; then
  echo 'This installer requires rpm-ostree.' >&2
  exit 1
fi

mapfile -t IMAGE_KERNELS < <(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
if [[ "${#IMAGE_KERNELS[@]}" -eq 0 ]]; then
  echo 'Could not locate an image kernel to build MSI EC for.' >&2
  exit 1
fi

# UBlue installs and locks its runtime kernel from its own OCI artifact.  Do
# not ask rpm-ostree for unversioned kernel packages here: Fedora repositories
# can advance kernel-devel before that OCI artifact does.  Replace only the
# header pair with packages matching the kernel ABI already in the image.
HEADER_PACKAGES=()
for kernel in "${IMAGE_KERNELS[@]}"; do
  HEADER_PACKAGES+=(
    "kernel-devel-${kernel}"
    "kernel-devel-matched-${kernel}"
  )
done

# Fetch exact NEVRAs first so DNF cannot substitute a newer header from
# another repository while resolving the transaction.  Install both headers
# together: kernel-devel-matched requires the matching kernel-devel package.
HEADER_RPMS_DIR="$(mktemp -d /var/tmp/msi-ec-kernel-headers.XXXXXX)"
readonly HEADER_RPMS_DIR
cleanup() {
  rm -rf -- "$HEADER_RPMS_DIR" "${BUILD_DIR:-}"
}
trap cleanup EXIT

echo 'Downloading headers matching the image kernel(s)...'
dnf download --destdir "$HEADER_RPMS_DIR" "${HEADER_PACKAGES[@]}"

HEADER_RPMS=()
for header_rpm in "$HEADER_RPMS_DIR"/*.rpm; do
  case "$(rpm -qp --qf '%{NAME}' "$header_rpm")" in
    kernel-devel|kernel-devel-matched)
      HEADER_RPMS+=("$header_rpm")
      ;;
  esac
done

if [[ "${#HEADER_RPMS[@]}" -ne "$(( ${#IMAGE_KERNELS[@]} * 2 ))" ]]; then
  echo 'Could not download every required matching kernel header RPM.' >&2
  exit 1
fi

echo 'Installing matching kernel header RPMs...'
dnf install -y --allowerasing "${HEADER_RPMS[@]}"

echo 'Installing MSI EC packages...'
sudo rpm-ostree install "$MSI_EC_COMMON_RPM" "$AKMOD_MSI_EC_RPM"

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

BUILD_DIR="$(mktemp -d /var/tmp/msi-ec-kmod-build.XXXXXX)"
readonly BUILD_DIR
chown akmods:akmods "$BUILD_DIR"

echo 'Building the MSI EC module for the image kernel(s)...'
for kernel in "${IMAGE_KERNELS[@]}"; do
  KERNEL_BUILD_DIR="/usr/lib/modules/${kernel}/build"
  if [[ ! -d "$KERNEL_BUILD_DIR" ]]; then
    echo "Matching headers for image kernel ${kernel} are unavailable." >&2
    exit 1
  fi

  HEADER_RELEASE="$(make -s -C "$KERNEL_BUILD_DIR" kernelrelease)"
  if [[ "$HEADER_RELEASE" != "$kernel" ]]; then
    echo "Header ABI ${HEADER_RELEASE} does not match image kernel ${kernel}." >&2
    exit 1
  fi

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
