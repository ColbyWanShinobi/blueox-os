#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

RELEASE="$(rpm -E %fedora)"

wget -P ${script_dir}/rpms \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${RELEASE}.noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${RELEASE}.noarch.rpm

rpm-ostree install \
  ${script_dir}/rpms/*.rpm \
  fedora-repos-archive

${script_dir}/install-apple-fonts.sh

#android-udev-rules
wget https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-${RELEASE}/ublue-os-staging-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_ublue-os_staging.repo

#distrobox
wget https://copr.fedorainfracloud.org/coprs/ublue-os/distrobox-git/repo/fedora-39/ublue-os-distrobox-git-fedora-39.repo \
  -O /etc/yum.repos.d/_copr_ublue-os_distrobox.repo

#akmods
wget https://copr.fedorainfracloud.org/coprs/ublue-os/akmods/repo/fedora-39/ublue-os-akmods-fedora-39.repo \
  -O /etc/yum.repos.d/_copr_ublue-os_akmods.repo

#Install System76 scheduler
wget https://copr.fedorainfracloud.org/coprs/kylegospo/system76-scheduler/repo/fedora-${RELEASE}/kylegospo-system76-scheduler-fedora-${RELEASE}.repo \
  -O /etc/yum.repos.d/_copr_kylegospo-system76-scheduler.repo

#Install OpenRGB DKMS
#LOL there's no fc39 package smdh
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/openrgb-dkms/repo/fedora-39/kylegospo-openrgb-dkms-fedora-39.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo-openrgb-dkms.repo

#Winesync
wget https://copr.fedorainfracloud.org/coprs/kylegospo/winesync-dkms/repo/fedora-39/kylegospo-winesync-dkms-fedora-39.repo \
  -O /etc/yum.repos.d/_copr_kylegospo-winesync-dkms.repo

#AMDCTL
wget https://copr.fedorainfracloud.org/coprs/kylegospo/amdctl/repo/fedora-39/kylegospo-amdctl-fedora-39.repo \
  -O /etc/yum.repos.d/_copr_kylegospo-amdctl.repo

#CorsairRMI
wget https://copr.fedorainfracloud.org/coprs/kylegospo/corsairmi/repo/fedora-39/kylegospo-corsairmi-fedora-39.repo \
  -O /etc/yum.repos.d/_copr_kylegospo-corsairmi.repo

#grub-btrfs
wget https://copr.fedorainfracloud.org/coprs/kylegospo/grub-btrfs/repo/fedora-39/kylegospo-grub-btrfs-fedora-39.repo \
  -O /etc/yum.repos.d/_copr_kylegospo-grub-btrfs.repo

#bazzite multilib
wget https://copr.fedorainfracloud.org/coprs/kylegospo/bazzite-multilib/repo/fedora-39/kylegospo-bazzite-multilib-fedora-39.repo \
  -O /etc/yum.repos.d/_copr_kylegospo-bazzite-multilib.repo

#more bazzite stuff
wget https://copr.fedorainfracloud.org/coprs/kylegospo/bazzite/repo/fedora-39/kylegospo-bazzite-fedora-39.repo \
  -O /etc/yum.repos.d/_copr_kylegospo-bazzite.repo

#OBS vkcapture
wget https://copr.fedorainfracloud.org/coprs/kylegospo/obs-vkcapture/repo/fedora-39/kylegospo-obs-vkcapture-fedora-39.repo \
  -O /etc/yum.repos.d/_copr_kylegospo-obs-vkcapture.repo

#Oversteer
wget https://copr.fedorainfracloud.org/coprs/kylegospo/oversteer/repo/fedora-39/kylegospo-oversteer-fedora-39.repo \
  -O /etc/yum.repos.d/_copr_kylegospo-oversteer.repo

# run common packages script
${script_dir}/packages.sh

## install packages direct from github
${script_dir}/github-release-install.sh sigstore/cosign x86_64
