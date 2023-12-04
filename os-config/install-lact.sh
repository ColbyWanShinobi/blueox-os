#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

RELEASE="$(rpm -E %fedora)"
RPMDIR=${script_dir}/install/rpms

wget "https://github.com/ilya-zlobintsev/LACT/releases/download/v0.5.0/lact-0.5.0-0.x86_64.fedora-39.rpm" -O ${RPMDIR}/lact.rpm

rpm-ostree install ${RPMDIR}/lact.rpm

systemctl enable lactd
