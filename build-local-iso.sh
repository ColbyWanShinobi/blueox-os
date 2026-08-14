#!/usr/bin/env bash
# Build a local BlueBuild recipe and turn that local result into installer media.
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="${0##*/}"
readonly REPOSITORY_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options] [recipe]

Build a local BlueBuild recipe as an OCI archive, then create an installer ISO
from that exact archive. Redux is the default recipe. Nothing is pushed to a
registry.

Options:
  --recipe RECIPE       Recipe path or name in recipes/ (default: redux.yml)
  --output-dir DIR      ISO output directory (default: output/local-iso-<timestamp>)
  --variant VARIANT     Installer variant: kinoite, silverblue, or server
                         (default: kinoite)
  --log PATH            Log file (default: .logs/build-local-iso-<timestamp>.log)
  --installer-image IMAGE
                        Container-installer image
                        (default: ghcr.io/jasonn3/build-container-installer:v1.4.0)
  -h, --help            Show this help

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} blueox.yml
  ${SCRIPT_NAME} --variant silverblue --output-dir output/test-iso

Requires BlueBuild, Podman, and sudo. BlueBuild builds the local OCI archive
rootlessly; the installer stage uses rootful Podman because Lorax must mount
devtmpfs while creating boot media. Complete output is logged and printed.
EOF
}

recipe="redux.yml"
output_dir=""
variant="kinoite"
log_file="${BUILD_LOG:-}"
installer_image="${INSTALLER_IMAGE:-ghcr.io/jasonn3/build-container-installer:v1.4.0}"

while (($#)); do
  case "$1" in
    --recipe)
      (($# >= 2)) || die "--recipe requires a value"
      recipe="$2"
      shift 2
      ;;
    --output-dir)
      (($# >= 2)) || die "--output-dir requires a value"
      output_dir="$2"
      shift 2
      ;;
    --variant)
      (($# >= 2)) || die "--variant requires a value"
      variant="$2"
      shift 2
      ;;
    --log)
      (($# >= 2)) || die "--log requires a value"
      log_file="$2"
      shift 2
      ;;
    --installer-image)
      (($# >= 2)) || die "--installer-image requires a value"
      installer_image="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      recipe="$1"
      shift
      ;;
  esac
done

case "$variant" in
  kinoite|silverblue|server) ;;
  *) die "invalid variant: $variant" ;;
esac

cd -- "$REPOSITORY_ROOT"
if [[ -f "$recipe" ]]; then
  recipe_path="$recipe"
elif [[ -f "recipes/$recipe" ]]; then
  recipe_path="recipes/$recipe"
else
  die "recipe not found: $recipe"
fi

command -v podman >/dev/null 2>&1 || die "Podman is required for the local ISO installer container"
command -v sudo >/dev/null 2>&1 || die "sudo is required for the Lorax installer stage"
if ! command -v bluebuild >/dev/null 2>&1; then
  printf 'BlueBuild is not installed; installing it with the official installer image...\n'
  sudo -v
  podman run --pull always --rm ghcr.io/blue-build/cli:v0.9-installer | sudo bash \
    || die "BlueBuild installation failed"
fi
command -v bluebuild >/dev/null 2>&1 || die "BlueBuild installer completed but bluebuild is not on PATH"

# BlueBuild's combined `generate-iso recipe` command in v0.9.37 builds a
# `.gz` archive but mounts a `.tar.gz` name into its installer container. Build
# the archive explicitly and pass the actual filename to that same installer.
image_version="$(awk '/^image-version:/ { print $2; exit }' "$recipe_path")"
[[ "$image_version" =~ ^[0-9]+$ ]] || die "could not determine a numeric image-version from $recipe_path"

timestamp="$(date +%Y%m%dT%H%M%S%z)"
if [[ -z "$log_file" ]]; then
  log_file="$REPOSITORY_ROOT/.logs/build-local-iso-${timestamp}.log"
elif [[ "$log_file" != /* ]]; then
  log_file="$REPOSITORY_ROOT/$log_file"
fi
mkdir -p -- "$(dirname -- "$log_file")"
touch -- "$log_file" || die "cannot write build log: $log_file"
exec > >(tee -a -- "$log_file") 2>&1

if [[ -z "$output_dir" ]]; then
  output_dir="$REPOSITORY_ROOT/output/local-iso-${timestamp}"
elif [[ "$output_dir" != /* ]]; then
  output_dir="$REPOSITORY_ROOT/$output_dir"
fi
[[ ! -e "$output_dir" ]] || die "output path already exists: $output_dir (choose --output-dir)"
mkdir -p -- "$output_dir"
archive_dir="$output_dir/image-archive"
mkdir -p -- "$archive_dir"

printf 'BlueOx local image and ISO build\n'
printf '  Recipe:  %s\n' "$recipe_path"
printf '  Variant: %s\n' "$variant"
printf '  Fedora:  %s\n' "$image_version"
printf '  Output:  %s\n' "$output_dir"
printf '  Log:     %s\n' "$log_file"
printf 'Sudo may prompt once for the privileged Lorax installer stage.\n'

# This is intentionally a non-pushing build. The OCI archive remains beside
# the ISO so the exact locally tested image is available for inspection.
env -u BB_BUILD_PUSH bluebuild --log-out "$(dirname -- "$log_file")" build \
  --archive "$archive_dir" \
  "$recipe_path"

mapfile -t archive_files < <(find "$archive_dir" -maxdepth 1 -type f -name '*.gz' -print | sort)
((${#archive_files[@]} == 1)) || die "expected one OCI archive under $archive_dir; found ${#archive_files[@]}"
archive_file="${archive_files[0]}"

printf '  OCI archive: %s\n' "$archive_file"
sudo -v
sudo podman pull "$installer_image"
sudo podman run --rm --privileged --network host \
  --volume "$output_dir:/build-container-installer/build:Z" \
  --volume blueox-local-iso-dnf-cache:/cache/dnf/ \
  --volume "$archive_dir:/img_src:ro,Z" \
  "$installer_image" \
  "VARIANT=${variant^}" \
  "ISO_NAME=build/deploy.iso" \
  "DNF_CACHE=/cache/dnf" \
  "SECURE_BOOT_KEY_URL=${BB_GENISO_SECURE_BOOT_URL:-https://github.com/ublue-os/bazzite/raw/main/secure_boot.der}" \
  "ENROLLMENT_PASSWORD=${BB_GENISO_ENROLLMENT_PASSWORD:-universalblue}" \
  "WEB_UI=${BB_GENISO_WEB_UI:-false}" \
  "IMAGE_SRC=oci-archive:/img_src/$(basename -- "$archive_file")" \
  "VERSION=$image_version"

# The rootful installer creates the ISO. The directory was created by this
# script, so returning its ownership to the invoking user is safe and keeps
# the artifact, OCI archive, and checksum readable without sudo.
sudo chown -R "$(id -u):$(id -g)" "$output_dir"

mapfile -t iso_files < <(find "$output_dir" -type f -name '*.iso' -print | sort)
((${#iso_files[@]})) || die "BlueBuild completed but no ISO was found under $output_dir"

checksum_file="$output_dir/SHA256SUMS"
: > "$checksum_file"
for iso_file in "${iso_files[@]}"; do
  sha256sum "$iso_file" | sed "s|  .*|  $(basename -- "$iso_file")|" >> "$checksum_file"
done

printf '\nLocal ISO build completed successfully.\n'
printf 'ISO file(s):\n'
printf '  %s\n' "${iso_files[@]}"
printf 'Checksums: %s\n' "$checksum_file"
