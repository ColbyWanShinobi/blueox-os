#!/usr/bin/env bash
# Build this repository locally using the same BlueBuild inputs as
# .github/workflows/build.yml (blue-build/github-action@v1.10).
#
# By default this builds Redux and pushes a signed image.
# Use --no-push for a local-only build.
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="${0##*/}"
readonly REPOSITORY_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} [options] [recipe ...]

Build redux.yml by default. Other recipes are built only when explicitly named.
Recipe arguments may be a name in recipes/ (for example blueox.yml) or a path.

Options:
  --recipe RECIPE       Add one recipe to build (may be repeated)
  --all                 Build all local recipes (plasma.yml, blueox.yml, redux.yml)
  --no-install-bluebuild  Do not install BlueBuild if it is missing
  --log PATH            Append build output to PATH (default: .logs/build-local-*.log)
  --no-push             Build locally without pushing to a registry
  --unsigned            Do not require or supply a cosign private key
  --registry REGISTRY   Registry to push to (default: ghcr.io)
  --namespace NAME      Registry namespace (default: Git remote owner, then user)
  --username NAME       Registry username (default: namespace)
  --key PATH            Cosign private key (default: ~/.ssh/blueox-os/cosign.key)
  --build-opt OPTION    Pass one additional option to bluebuild build
  -h, --help            Show this help

Environment overrides:
  REGISTRY, NAMESPACE, REGISTRY_USERNAME, REGISTRY_TOKEN (or GH_TOKEN),
  BUILD_LOG, COSIGN_KEY_PATH, COSIGN_PASSWORD, BB_BUILD_PUSH, BB_* BlueBuild
  options, and BLUEBUILD_INSTALLER_IMAGE.

Examples:
  ${SCRIPT_NAME} --no-push
  ${SCRIPT_NAME} --no-push blueox.yml
  REGISTRY_TOKEN="\$(gh auth token)" ${SCRIPT_NAME}
EOF
}

recipes=()
build_opts=()
install_bluebuild=true
log_file="${BUILD_LOG:-}"
push="${BB_BUILD_PUSH:-true}"
unsigned=false
registry="${REGISTRY:-ghcr.io}"
namespace="${NAMESPACE:-}"
username="${REGISTRY_USERNAME:-}"
key_path="${COSIGN_KEY_PATH:-${HOME}/.ssh/blueox-os/cosign.key}"

while (($#)); do
  case "$1" in
    --recipe)
      (($# >= 2)) || die "--recipe requires a value"
      recipes+=("$2")
      shift 2
      ;;
    --all)
      recipes=("plasma.yml" "blueox.yml" "redux.yml")
      shift
      ;;
    --no-install-bluebuild)
      install_bluebuild=false
      shift
      ;;
    --log)
      (($# >= 2)) || die "--log requires a path"
      log_file="$2"
      shift 2
      ;;
    --no-push)
      push=false
      shift
      ;;
    --unsigned)
      unsigned=true
      shift
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
      (($# >= 2)) || die "--key requires a path"
      key_path="$2"
      shift 2
      ;;
    --build-opt)
      (($# >= 2)) || die "--build-opt requires one BlueBuild option"
      build_opts+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      recipes+=("$@")
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      recipes+=("$1")
      shift
      ;;
  esac
done

if ((${#recipes[@]} == 0)); then
  recipes=("redux.yml")
fi

cd -- "$REPOSITORY_ROOT"

if [[ -z "$log_file" ]]; then
  log_file="$REPOSITORY_ROOT/.logs/build-local-$(date +%Y%m%dT%H%M%S%z).log"
elif [[ "$log_file" != /* ]]; then
  log_file="$REPOSITORY_ROOT/$log_file"
fi
mkdir -p -- "$(dirname -- "$log_file")"
touch -- "$log_file" || die "cannot write build log: $log_file"

# Keep the terminal useful while retaining the complete BlueBuild/bootstrap log.
exec > >(tee -a -- "$log_file") 2>&1
printf 'Logging all build output to: %s\n' "$log_file"

install_bluebuild_cli() {
  local container_engine
  local installer_image="${BLUEBUILD_INSTALLER_IMAGE:-ghcr.io/blue-build/cli:v0.9-installer}"

  # The GitHub action installs this same v0.9 CLI series from its installer
  # image. Docker is preferred because the action uses Docker Buildx; Podman is
  # an official equivalent when Docker is not present.
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    container_engine=docker
  elif command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then
    container_engine=podman
  else
    die "bluebuild is missing and neither Docker nor Podman is usable; start/configure one, or install BlueBuild manually"
  fi

  printf 'BlueBuild is not installed; installing it from %s via %s...\n' "$installer_image" "$container_engine"
  printf 'The official installer writes to /usr/local/bin and may ask for sudo.\n'
  if ! "$container_engine" run --pull always --rm "$installer_image" | bash; then
    die "BlueBuild installation failed; install it manually or re-run with --no-install-bluebuild"
  fi
  command -v bluebuild >/dev/null 2>&1 || die "BlueBuild installer completed but bluebuild is still not on PATH; start a new shell or add its install location to PATH"
}

if ! command -v bluebuild >/dev/null 2>&1; then
  [[ "$install_bluebuild" == true ]] || die "bluebuild is not installed or is not on PATH"
  install_bluebuild_cli
fi
command -v git >/dev/null 2>&1 || die "git is not installed or is not on PATH"

if [[ -z "$namespace" ]]; then
  remote_url="$(git config --get remote.origin.url 2>/dev/null || true)"
  if [[ "$remote_url" =~ (github.com[:/])([^/]+)/[^/]+(\.git)?$ ]]; then
    namespace="${BASH_REMATCH[2]}"
  else
    namespace="$(id -un)"
    warn "could not determine the GitHub owner from origin; using local user '$namespace'"
  fi
fi
namespace="$(tr '[:upper:]' '[:lower:]' <<<"$namespace")"
[[ -n "$username" ]] || username="$namespace"

if [[ "$push" == "true" ]]; then
  registry_token="${REGISTRY_TOKEN:-${GH_TOKEN:-${BB_PASSWORD:-}}}"
  [[ -n "$registry_token" ]] || die "pushing is enabled (as in GitHub Actions); set REGISTRY_TOKEN/GH_TOKEN or use --no-push"
else
  registry_token="${REGISTRY_TOKEN:-${GH_TOKEN:-${BB_PASSWORD:-}}}"
fi

if [[ "$unsigned" == false ]]; then
  [[ -r "$key_path" ]] || die "cosign private key is not readable: $key_path (or use --unsigned)"
  # The GitHub action supplies the key material in COSIGN_PRIVATE_KEY, not a path.
  COSIGN_PRIVATE_KEY="$(<"$key_path")"
  export COSIGN_PRIVATE_KEY
fi

# These are the variables set by blue-build/github-action@v1.10.  Preserve a
# caller-provided BB_* value so advanced action inputs can be mirrored locally.
export BB_BUILD_PUSH="$push"
export BB_REGISTRY="${BB_REGISTRY:-$registry}"
export BB_REGISTRY_NAMESPACE="${BB_REGISTRY_NAMESPACE:-$namespace}"
export RUST_LOG_STYLE="${RUST_LOG_STYLE:-always}"
export CLICOLOR_FORCE="${CLICOLOR_FORCE:-1}"

# Do not export empty credentials. BlueBuild treats their presence as a request
# for basic authentication, which prevents anonymous pulls from public GHCR
# repositories. GitHub Actions always has a token; local no-push builds often
# intentionally do not.
if [[ -n "$registry_token" ]]; then
  export BB_PASSWORD="${BB_PASSWORD:-$registry_token}"
  export BB_USERNAME="${BB_USERNAME:-$username}"
  export GH_TOKEN="${GH_TOKEN:-$registry_token}"
else
  unset BB_PASSWORD BB_USERNAME GH_TOKEN
fi

resolved_recipes=()
for recipe in "${recipes[@]}"; do
  if [[ -f "$recipe" ]]; then
    resolved_recipes+=("$recipe")
  elif [[ -f "recipes/$recipe" ]]; then
    resolved_recipes+=("recipes/$recipe")
  elif [[ -f "config/$recipe" ]]; then
    resolved_recipes+=("config/$recipe")
  else
    die "recipe not found: $recipe"
  fi
done

printf 'BlueOx local build (GitHub Actions compatible)\n'
printf '  BlueBuild: %s\n' "$(bluebuild --version 2>/dev/null || printf 'unknown')"
printf '  Registry:  %s/%s\n' "$BB_REGISTRY" "$BB_REGISTRY_NAMESPACE"
printf '  Push:      %s\n' "$BB_BUILD_PUSH"
printf '  Signing:   %s\n' "$([[ "$unsigned" == true ]] && printf 'disabled' || printf 'cosign key loaded')"

for recipe in "${resolved_recipes[@]}"; do
  printf '\n==> Building %s\n' "$recipe"
  bluebuild build -v "${build_opts[@]}" "$recipe"
done

printf '\nBuild completed successfully.\n'
if [[ "$push" == "true" ]]; then
  printf 'Published images are under %s/%s/<recipe-name>.\n' "$BB_REGISTRY" "$BB_REGISTRY_NAMESPACE"
else
  printf 'Images were not pushed. Re-run without --no-push after providing registry credentials.\n'
fi
