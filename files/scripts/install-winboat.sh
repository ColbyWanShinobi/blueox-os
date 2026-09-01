#!/usr/bin/env bash

set -euo pipefail
################
APP_NAME=winboat
APP_COMMAND=winboat
RELEASE_API_URL='https://api.github.com/repos/winboat-org/winboat/releases/latest'
PACKAGE_TYPE=rpm
################
# Space delimited list of required command-line utilities to run this script
prereq_list=(curl jq rpm-ostree)

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

# Resolve the x86_64 RPM from WinBoat's latest GitHub release. Keeping this
# dynamic avoids pinning the image to a stale upstream release.
DL_URL="$(curl --location --silent --fail --show-error "${RELEASE_API_URL}" | jq --raw-output --exit-status '
  .assets[]
  | select(.name | test("^winboat-.+-x86_64\\.rpm$"))
  | .browser_download_url
' | head --lines 1)"

if [ -z "${DL_URL}" ];then
  echo "Unable to find an x86_64 RPM in the latest WinBoat release."
  exit 1
fi

# Download the file
echo "Downloading file ${DL_URL} to ${PACKAGE_PATH}"
curl --location --silent --fail --show-error --output "${PACKAGE_PATH}" "${DL_URL}"

# Layer the RPM transactionally so it remains compatible with Fedora Atomic's
# read-only /usr filesystem.
echo "Installing ${PACKAGE_PATH}"
rpm-ostree install -y "${PACKAGE_PATH}"
