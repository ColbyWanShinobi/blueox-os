#!/usr/bin/env bash

set -euo pipefail
################
APP_NAME=openlogi
APP_COMMAND=openlogi
DL_URL='https://github.com/AprilNEA/OpenLogi/releases/download/v0.7.1/openlogi-v0.7.1-linux-amd64.rpm'
PACKAGE_TYPE=rpm
################
# Space delimited list of required command-line utilities to run this script
prereq_list=(curl rpm)

# Check to see if the prereq utilities are installed
for util in "${prereq_list[@]}";do
  if [ ! -x "$(command -v ${util})" ];then
    echo "Missing utility! Please install [${util}] and try again..."
    exit 1
  fi
done

SETUP_PATH=${HOME}/Downloads/${APP_NAME}
PACKAGE_PATH=${SETUP_PATH}/${APP_NAME}.${PACKAGE_TYPE}

# Create setup directory
echo "Creating Setup Directory: ${SETUP_PATH}"
mkdir -p ${SETUP_PATH}

# Check to see if the app is already installed
if [ -x "$(command -v ${APP_COMMAND})" ];then
	echo "Command '${APP_COMMAND}' is already present. Aborting install."
	exit 0
fi

# Download the file
echo "Downloading file ${DL_URL} to ${PACKAGE_PATH}"
curl --location --silent --fail --show-error --output ${PACKAGE_PATH} ${DL_URL}

# Install the package. OpenLogi has no RPM dependencies, and its post-install
# and file-trigger hooks try to reload udev, which is unavailable while this
# image is being composed. The installed udev rules take effect at boot.
echo "Installing ${PACKAGE_PATH}"
rpm --install --noscripts --notriggers ${PACKAGE_PATH}
