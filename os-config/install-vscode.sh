#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

RELEASE="$(rpm -E %fedora)"
RPMDIR=${script_dir}/install/rpms

# Install VSCode natively because it sucks running in Flatpak
wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64" -O ${RPMDIR}/vscode.rpm

rpm-ostree install ${RPMDIR}/vscode.rpm
