#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

RELEASE="$(rpm -E %fedora)"
RPMDIR=${script_dir}/install/rpms

# Install System76 scheduler
wget https://copr.fedorainfracloud.org/coprs/kylegospo/system76-scheduler/repo/fedora-${RELEASE}/kylegospo-system76-scheduler-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_kylegospo_system76_scheduler.repo

rpm-ostree install system76-scheduler gnome-shell-extension-system76-scheduler

# Enable System76 scheduler
systemctl enable com.system76.Scheduler.service
