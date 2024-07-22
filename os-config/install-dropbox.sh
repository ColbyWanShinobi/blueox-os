#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

RELEASE="$(rpm -E %fedora)"
RPMDIR=${script_dir}/install/rpms

wget "https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2024.04.17-1.fc39.x86_64.rpm" -O ${RPMDIR}/dropbox.rpm

rpm-ostree install ${RPMDIR}/dropbox.rpm
