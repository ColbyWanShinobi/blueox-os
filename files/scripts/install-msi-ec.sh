#!/usr/bin/env bash

set -euo pipefail
################
APP_NAME=msi-ec
APP_COMMAND=code
DL_URL='https://github.com/BeardOverflow/msi-ec.git'
PACKAGE_TYPE=git
################
# Space delimited list of required command-line utilities to run this script
prereq_list=(make git)

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

# Download the file
echo "Downloading file ${DL_URL} to ${PACKAGE_PATH}"
git clone ${DL_URL} ${PACKAGE_PATH}

# Install the package
echo "Installing ${PACKAGE_PATH}"
cd ${PACKAGE_PATH}
make

mkdir -p /usr/lib/modules/$(uname -r)/extra
cp msi-ec.ko /usr/lib/modules/$(uname -r)/extra
sudo chmod 644 /usr/lib/modules/$(uname -r)/extra/msi-ec.ko
sudo chown root:root /usr/lib/modules/$(uname -r)/extra/msi-ec.ko
echo msi-ec > /etc/modules-load.d/msi-ec.conf

depmod -a
