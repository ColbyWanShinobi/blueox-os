#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

RELEASE="$(rpm -E %fedora)"
RPMDIR=${script_dir}/install/rpms

#AMDCTL
wget https://copr.fedorainfracloud.org/coprs/kylegospo/amdctl/repo/fedora-${RELEASE}/kylegospo-amdctl-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_kylegospo_amdctl.repo

rpm-ostree install amdctl

# Added entry in first-boot.sh
