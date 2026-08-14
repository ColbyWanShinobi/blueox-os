#!/usr/bin/env bash
# Create an installer ISO from a published GHCR image using the same
# bootc-image-builder command as .github/workflows/build-iso.yml.
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
Usage: ${SCRIPT_NAME} [options]

Build a Btrfs Anaconda installer ISO from a published BlueOx GHCR image.
The default image is ghcr.io/<GitHub-owner>/blueox-os:redux.

Options:
  --tag TAG             Published BlueOx image tag (default: redux)
  --image IMAGE         Full OCI image reference; overrides --tag
  --output-dir DIR      ISO output directory (default: output/iso-<tag>-<timestamp>)
  --log PATH            Log file (default: .logs/build-github-iso-<timestamp>.log)
  --builder-image IMAGE bootc-image-builder image
                         (default: quay.io/centos-bootc/bootc-image-builder:latest)
  --network MODE        Podman network mode (default: host)
  -h, --help            Show this help

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --tag latest
  ${SCRIPT_NAME} --image ghcr.io/colbywanshinobi/blueox-os:redux

Requires rootful Podman and sudo. All builder output is logged while printed
to the terminal. Host networking is the default because it avoids local Podman
DNS/CNI issues while downloading Fedora and COPR repositories. This script does
not delete container storage or publish files.
EOF
}

tag="redux"
image_ref=""
output_dir=""
log_file="${BUILD_LOG:-}"
builder_image="${BIB_IMAGE:-quay.io/centos-bootc/bootc-image-builder:latest}"
network_mode="${BIB_NETWORK:-host}"

while (($#)); do
  case "$1" in
    --tag)
      (($# >= 2)) || die "--tag requires a value"
      tag="$2"
      shift 2
      ;;
    --image)
      (($# >= 2)) || die "--image requires a value"
      image_ref="$2"
      shift 2
      ;;
    --output-dir)
      (($# >= 2)) || die "--output-dir requires a value"
      output_dir="$2"
      shift 2
      ;;
    --log)
      (($# >= 2)) || die "--log requires a value"
      log_file="$2"
      shift 2
      ;;
    --builder-image)
      (($# >= 2)) || die "--builder-image requires a value"
      builder_image="$2"
      shift 2
      ;;
    --network)
      (($# >= 2)) || die "--network requires a value"
      network_mode="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[[ "$tag" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]] || die "invalid image tag: $tag"
[[ -n "$network_mode" ]] || die "network mode must not be empty"
cd -- "$REPOSITORY_ROOT"

timestamp="$(date +%Y%m%dT%H%M%S%z)"
if [[ -z "$log_file" ]]; then
  log_file="$REPOSITORY_ROOT/.logs/build-github-iso-${timestamp}.log"
elif [[ "$log_file" != /* ]]; then
  log_file="$REPOSITORY_ROOT/$log_file"
fi
mkdir -p -- "$(dirname -- "$log_file")"
touch -- "$log_file" || die "cannot write build log: $log_file"
exec > >(tee -a -- "$log_file") 2>&1
printf 'Logging all ISO build output to: %s\n' "$log_file"

command -v podman >/dev/null 2>&1 || die "Podman is required; install/configure it first"
command -v sudo >/dev/null 2>&1 || die "sudo is required for the rootful Podman builder"
[[ -f disk_config/iso.toml ]] || die "missing disk_config/iso.toml"

if [[ -z "$image_ref" ]]; then
  remote_url="$(git config --get remote.origin.url 2>/dev/null || true)"
  if [[ "$remote_url" =~ (github.com[:/])([^/]+)/[^/]+(\.git)?$ ]]; then
    owner="${BASH_REMATCH[2],,}"
  else
    die "cannot determine GitHub owner from origin; pass --image explicitly"
  fi
  image_ref="ghcr.io/${owner}/blueox-os:${tag}"
fi

if [[ -z "$output_dir" ]]; then
  output_dir="$REPOSITORY_ROOT/output/iso-${tag}-${timestamp}"
elif [[ "$output_dir" != /* ]]; then
  output_dir="$REPOSITORY_ROOT/$output_dir"
fi
[[ ! -e "$output_dir" ]] || die "output path already exists: $output_dir (choose --output-dir)"
mkdir -p -- "$output_dir"

config_file="$REPOSITORY_ROOT/.logs/iso-config-${timestamp}.toml"
sed "s|IMAGE_REFERENCE|${image_ref}|g" disk_config/iso.toml > "$config_file"

printf 'BlueOx ISO build from published GitHub image\n'
printf '  Image:       %s\n' "$image_ref"
printf '  Builder:     %s\n' "$builder_image"
printf '  Rootfs:      btrfs\n'
printf '  Network:     %s\n' "$network_mode"
printf '  Output:      %s\n' "$output_dir"
printf '  Config copy: %s\n' "$config_file"
printf 'Sudo may prompt once for the privileged builder.\n'

sudo -v
getent hosts download.copr.fedorainfracloud.org >/dev/null \
  || die "the host cannot resolve download.copr.fedorainfracloud.org; repair the host DNS connection before building"
sudo podman pull "$builder_image"
sudo podman pull "$image_ref"
sudo podman run --rm --privileged \
  --security-opt label=type:unconfined_t \
  --network "$network_mode" \
  --volume /var/lib/containers/storage:/var/lib/containers/storage \
  --volume "$output_dir:/output:Z" \
  --volume "$config_file:/config.toml:ro,Z" \
  "$builder_image" build \
  --output /output \
  --chown "$(id -u):$(id -g)" \
  --rootfs btrfs \
  --use-librepo=True \
  --type anaconda-iso \
  "$image_ref"

mapfile -t iso_files < <(find "$output_dir" -type f -name '*.iso' -print | sort)
((${#iso_files[@]})) || die "bootc-image-builder completed but no ISO was found under $output_dir"

checksum_file="$output_dir/SHA256SUMS"
: > "$checksum_file"
for iso_file in "${iso_files[@]}"; do
  sha256sum "$iso_file" | sed "s|  .*|  $(basename -- "$iso_file")|" >> "$checksum_file"
done

printf '\nISO build completed successfully.\n'
printf 'ISO file(s):\n'
printf '  %s\n' "${iso_files[@]}"
printf 'Checksums: %s\n' "$checksum_file"
