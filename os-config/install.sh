#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

RELEASE="$(rpm -E %fedora)"

wget -P ${script_dir}/rpms \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${RELEASE}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${RELEASE}.noarch.rpm" \
  "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64" \
  "https://github.com/ilya-zlobintsev/LACT/releases/download/v0.5.0/lact-0.5.0-0.x86_64.fedora-39.rpm"

rpm-ostree install \
  ${script_dir}/rpms/*.rpm \
  fedora-repos-archive

${script_dir}/install-apple-fonts.sh

#wget https://copr.fedorainfracloud.org/coprs/tigro/python-validity/repo/fedora-${RELEASE}/tigro-python-validity-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_tigro_python_validity.repo

#android-udev-rules
wget https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-${RELEASE}/ublue-os-staging-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_ublue-os_staging.repo

#distrobox
wget https://copr.fedorainfracloud.org/coprs/ublue-os/distrobox-git/repo/fedora-${RELEASE}/ublue-os-distrobox-git-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_ublue-os_distrobox.repo

#akmods
wget https://copr.fedorainfracloud.org/coprs/ublue-os/akmods/repo/fedora-${RELEASE}/ublue-os-akmods-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_ublue-os_akmods.repo

#Install System76 scheduler
wget https://copr.fedorainfracloud.org/coprs/kylegospo/system76-scheduler/repo/fedora-${RELEASE}/kylegospo-system76-scheduler-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_kylegospo_system76_scheduler.repo

#Install OpenRGB DKMS
#LOL there's no fc39 package smdh
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/openrgb-dkms/repo/fedora-${RELEASE}/kylegospo-openrgb-dkms-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo-openrgb-dkms.repo

#Winesync
wget https://copr.fedorainfracloud.org/coprs/kylegospo/winesync-dkms/repo/fedora-${RELEASE}/kylegospo-winesync-dkms-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_kylegospo_winesync_dkms.repo

#AMDCTL
wget https://copr.fedorainfracloud.org/coprs/kylegospo/amdctl/repo/fedora-${RELEASE}/kylegospo-amdctl-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_kylegospo_amdctl.repo

#CorsairRMI
wget https://copr.fedorainfracloud.org/coprs/kylegospo/corsairmi/repo/fedora-${RELEASE}/kylegospo-corsairmi-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_kylegospo_corsairmi.repo

#grub-btrfs
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/grub-btrfs/repo/fedora-${RELEASE}/kylegospo-grub-btrfs-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo-grub-btrfs.repo

#bazzite multilib
wget https://copr.fedorainfracloud.org/coprs/kylegospo/bazzite-multilib/repo/fedora-${RELEASE}/kylegospo-bazzite-multilib-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_kylegospo_bazzite_multilib.repo

#more bazzite stuff
wget https://copr.fedorainfracloud.org/coprs/kylegospo/bazzite/repo/fedora-${RELEASE}/kylegospo-bazzite-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_kylegospo_bazzite.repo

#OBS vkcapture
wget https://copr.fedorainfracloud.org/coprs/kylegospo/obs-vkcapture/repo/fedora-${RELEASE}/kylegospo-obs-vkcapture-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_kylegospo_obs_vkcapture.repo

#Oversteer
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/oversteer/repo/fedora-${RELEASE}/kylegospo-oversteer-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo-oversteer.repo

# run common packages script
${script_dir}/packages.sh

## install packages direct from github
${script_dir}/github-release-install.sh sigstore/cosign x86_64
