#!/usr/bin/env bash
# Build, sign, publish, and stage a new BlueOx Redux deployment from this checkout.
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

Build Redux locally, push and sign it, then stage that signed image as the next
rpm-ostree deployment. Run this from an existing BlueOx installation whose
container policy trusts the selected public key.

Options:
  --reboot              Reboot immediately after staging the deployment
  --no-build            Do not build; stage the image supplied with --image
  --image REFERENCE     Signed registry image to stage (requires --no-build)
  --registry REGISTRY   Registry for the local build (default: ghcr.io)
  --namespace NAME      Registry namespace (default: Git remote owner, then user)
  --username NAME       Registry username (default: namespace)
  --key PATH            Cosign private key for the build
                         (default: ~/.ssh/blueox-os/cosign.key)
  -h, --help            Show this help

Environment overrides:
  REGISTRY, NAMESPACE, REGISTRY_USERNAME, REGISTRY_TOKEN (or GH_TOKEN),
  COSIGN_KEY_PATH, and COSIGN_PASSWORD.

Examples:
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --reboot
  ${SCRIPT_NAME} --no-build --image ghcr.io/colbywanshinobi/blueox-os:redux
EOF
}

reboot_after_update=false
build_image=true
image_reference=""
registry="${REGISTRY:-ghcr.io}"
namespace="${NAMESPACE:-}"
username="${REGISTRY_USERNAME:-}"
private_key="${COSIGN_KEY_PATH:-${HOME}/.ssh/blueox-os/cosign.key}"

while (($#)); do
  case "$1" in
    --reboot)
      reboot_after_update=true
      shift
      ;;
    --no-build)
      build_image=false
      shift
      ;;
    --image)
      (($# >= 2)) || die "--image requires a value"
      image_reference="$2"
      shift 2
      ;;
    --registry)
      (($# >= 2)) || die "--registry requires a value"
      registry="$2"
      shift 2
      ;;
    --namespace)
      (($# >= 2)) || die "--namespace requires a value"
      namespace="$2"
      shift 2
      ;;
    --username)
      (($# >= 2)) || die "--username requires a value"
      username="$2"
      shift 2
      ;;
    --key)
      (($# >= 2)) || die "--key requires a value"
      private_key="$2"
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

(( EUID != 0 )) || die "run as your normal user; sudo is used only to stage the deployment"

if [[ "$build_image" == true ]]; then
  [[ -z "$image_reference" ]] || die "--image requires --no-build"
  if [[ -z "$namespace" ]]; then
    remote_url="$(git -C "$REPOSITORY_ROOT" config --get remote.origin.url 2>/dev/null || true)"
    if [[ "$remote_url" =~ (github.com[:/])([^/]+)/[^/]+(\.git)?$ ]]; then
      namespace="${BASH_REMATCH[2]}"
    else
      namespace="$(id -un)"
      printf "warning: could not determine the GitHub owner from origin; using local user '%s'\n" "$namespace" >&2
    fi
  fi
  namespace="$(tr '[:upper:]' '[:lower:]' <<<"$namespace")"
  [[ -n "$username" ]] || username="$namespace"

  printf 'Building, signing, and pushing Redux from this checkout...\n'
  "$REPOSITORY_ROOT/build-local.sh" \
    --push --signed \
    --registry "$registry" \
    --namespace "$namespace" \
    --username "$username" \
    --key "$private_key" \
    redux.yml
  image_reference="${registry}/${namespace}/blueox-os:redux"
elif [[ -z "$image_reference" ]]; then
  die "--no-build requires --image REFERENCE"
fi

printf 'Verifying and staging signed image as the next deployment...\n'
sudo rpm-ostree rebase "ostree-image-signed:docker://${image_reference}"

if [[ "$reboot_after_update" == true ]]; then
  sudo systemctl reboot
fi

printf '\nSigned image staged. Reboot to boot the new deployment.\n'
