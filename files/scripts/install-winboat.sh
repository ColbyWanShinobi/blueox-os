#!/usr/bin/env bash

set -euo pipefail
################
APP_NAME=winboat
APP_COMMAND=winboat
RELEASE_LATEST_URL='https://github.com/winboat-org/winboat/releases/latest'
PACKAGE_TYPE=rpm
################
# Space delimited list of required command-line utilities to run this script
prereq_list=(curl rpm-ostree)

# Check to see if the prereq utilities are installed
for util in "${prereq_list[@]}";do
  if [ ! -x "$(command -v "${util}")" ];then
    echo "Missing utility! Please install [${util}] and try again..."
    exit 1
  fi
done

SETUP_PATH=${HOME}/Downloads/${APP_NAME}
PACKAGE_PATH=${SETUP_PATH}/${APP_NAME}.${PACKAGE_TYPE}

# Create setup directory
echo "Creating Setup Directory: ${SETUP_PATH}"
mkdir -p "${SETUP_PATH}"

# Check to see if the app is already installed
if [ -x "$(command -v ${APP_COMMAND})" ];then
	echo "Command '${APP_COMMAND}' is already present. Aborting install."
	exit 0
fi

# Resolve the latest release tag through GitHub's public redirect rather than
# the unauthenticated REST API.  Shared GitHub Actions runner IPs can exhaust
# the API rate limit and receive HTTP 403 before the RPM download begins.
echo 'Finding the newest WinBoat release...'
RELEASE_URL="$(curl --location --silent --fail --show-error \
  --retry 5 --retry-all-errors --retry-delay 3 --retry-max-time 120 \
  --connect-timeout 30 --output /dev/null --write-out '%{url_effective}' "$RELEASE_LATEST_URL")"
RELEASE_TAG="${RELEASE_URL##*/}"
RELEASE_VERSION="${RELEASE_TAG#v}"

if [[ -z "$RELEASE_VERSION" ]] || [[ "$RELEASE_VERSION" == "$RELEASE_TAG" ]]; then
  echo "Unable to determine the latest WinBoat release tag." >&2
  exit 1
fi

DL_URL="https://github.com/winboat-org/winboat/releases/download/${RELEASE_TAG}/winboat-${RELEASE_VERSION}-x86_64.rpm"

# Download the file
echo "Downloading file ${DL_URL} to ${PACKAGE_PATH}"
curl --location --silent --fail --show-error \
  --retry 5 --retry-all-errors --retry-delay 3 --retry-max-time 120 \
  --connect-timeout 30 --output "${PACKAGE_PATH}" "${DL_URL}"

# Layer the RPM transactionally so it remains compatible with Fedora Atomic's
# read-only /usr filesystem.
echo "Installing ${PACKAGE_PATH}"
rpm-ostree install -y "${PACKAGE_PATH}"
