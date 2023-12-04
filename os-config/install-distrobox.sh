#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

RELEASE="$(rpm -E %fedora)"
RPMDIR=${script_dir}/install/rpms

#distrobox
wget https://copr.fedorainfracloud.org/coprs/ublue-os/distrobox-git/repo/fedora-${RELEASE}/ublue-os-distrobox-git-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_ublue-os_distrobox.repo

rpm-ostree install distrobox
