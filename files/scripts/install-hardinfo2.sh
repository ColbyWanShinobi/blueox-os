#!/usr/bin/env bash

set -euo pipefail
################
APP_NAME=hardinfo2
APP_COMMAND=hardinfo2
GITHUB_RELEASES_API='https://api.github.com/repos/hardinfo2/hardinfo2/releases?per_page=20'
PACKAGE_TYPE=rpm
################
# Space delimited list of required command-line utilities to run this script
prereq_list=(curl dnf jq)

# Check to see if the prereq utilities are installed
for util in "${prereq_list[@]}";do
  if [ ! -x "$(command -v "${util}")" ];then
    echo "Missing utility! Please install [${util}] and try again..."
    exit 1
  fi
done

SETUP_PATH=${HOME}/Downloads/${APP_NAME}
PACKAGE_PATH=${SETUP_PATH}/${APP_NAME}.${PACKAGE_TYPE}

# shellcheck disable=SC1091
source /etc/os-release
FEDORA_VERSION="${VERSION_ID}"
ARCHITECTURE="$(uname -m)"
if [[ ! "$FEDORA_VERSION" =~ ^[0-9]+$ ]]; then
  echo "Could not determine the Fedora version from /etc/os-release." >&2
  exit 1
fi

# Stable Hardinfo2 releases contain source only.  Query all public releases,
# including prereleases, and select the newest one that has a Fedora RPM for
# this release or the closest older Fedora release.  Never install an RPM built
# for a newer Fedora release because its dependencies may not be available.
echo 'Finding the newest compatible Hardinfo2 RPM release...'
DL_URL="$(
  curl --location --silent --fail --show-error \
    --retry 5 --retry-all-errors --retry-delay 3 --retry-max-time 120 \
    --connect-timeout 30 "$GITHUB_RELEASES_API" |
    jq -er --arg architecture "$ARCHITECTURE" --argjson fedora_version "$FEDORA_VERSION" '
      first(
        .[]
        | select(.draft | not)
        | [
            .assets[]
            | select(.name | endswith("." + $architecture + ".rpm"))
            | . as $asset
            | ($asset.name | capture("FedoraLinux-(?<fedora_version>[0-9]+)\\.")) as $match
            | $asset + {fedora_version: ($match.fedora_version | tonumber)}
            | select(.fedora_version <= $fedora_version)
          ]
        | if length > 0 then max_by(.fedora_version) else empty end
        | .browser_download_url
      ) // empty
    '
)"

if [[ -z "$DL_URL" ]]; then
  echo "No compatible Fedora ${FEDORA_VERSION} ${ARCHITECTURE} Hardinfo2 RPM was found." >&2
  exit 1
fi

# Create setup directory
echo "Creating Setup Directory: ${SETUP_PATH}"
mkdir -p "${SETUP_PATH}"

# Check to see if the app is already installed
if [ -x "$(command -v ${APP_COMMAND})" ];then
	echo "Command '${APP_COMMAND}' is already present. Aborting install."
	exit 0
fi

# Download the file
echo "Downloading file ${DL_URL} to ${PACKAGE_PATH}"
curl --location --silent --fail --show-error \
  --retry 5 --retry-all-errors --retry-delay 3 --retry-max-time 120 \
  --connect-timeout 30 --output "${PACKAGE_PATH}" "${DL_URL}"

# Install the package
echo "Installing ${PACKAGE_PATH}"
rpm-ostree install -y "${PACKAGE_PATH}"
