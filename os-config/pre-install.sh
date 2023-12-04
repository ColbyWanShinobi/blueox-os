#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

# Create the software install folders
RPMDIR=${script_dir}/install/rpms
mkdir -p ${RPMDIR}

# Copy over my custom files
cp -Rv ${script_dir}/etc/* /etc
cp -Rv ${script_dir}/usr/* /usr

#OSTree Timer
systemctl enable rpm-ostreed-automatic.timer

# Enable Flatpak Daily Update
systemctl enable flatpak-system-update.timer
systemctl --global enable flatpak-user-update.timer
