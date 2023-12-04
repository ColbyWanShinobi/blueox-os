#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

RELEASE="$(rpm -E %fedora)"
RPMDIR=${script_dir}/install/rpms

# Install RPM Fusion Repos
wget "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${RELEASE}.noarch.rpm" -O ${RPMDIR}/rpmfusion-free.rpm
wget "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${RELEASE}.noarch.rpm" -O ${RPMDIR}/rpmfusion-nonfree.rpm

# Install VSCode natively because it sucks running in Flatpak
#wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64" -O ${RPMDIR}/vscode.rpm

rpm-ostree install \
  ${RPMDIR}/*.rpm \
  fedora-repos-archive

## install packages direct from github
${script_dir}/github-release-install.sh sigstore/cosign x86_64

#wget https://copr.fedorainfracloud.org/coprs/tigro/python-validity/repo/fedora-${RELEASE}/tigro-python-validity-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_tigro_python_validity.repo

#android-udev-rules
#wget https://copr.fedorainfracloud.org/coprs/ublue-os/staging/repo/fedora-${RELEASE}/ublue-os-staging-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_ublue-os_staging.repo

#Install OpenRGB DKMS
#LOL there's no fc39 package smdh
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/openrgb-dkms/repo/fedora-${RELEASE}/kylegospo-openrgb-dkms-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo-openrgb-dkms.repo

#Winesync
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/winesync-dkms/repo/fedora-${RELEASE}/kylegospo-winesync-dkms-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo_winesync_dkms.repo

#CorsairRMI
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/corsairmi/repo/fedora-${RELEASE}/kylegospo-corsairmi-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo_corsairmi.repo

#grub-btrfs
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/grub-btrfs/repo/fedora-${RELEASE}/kylegospo-grub-btrfs-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo-grub-btrfs.repo

#bazzite multilib
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/bazzite-multilib/repo/fedora-${RELEASE}/kylegospo-bazzite-multilib-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo_bazzite_multilib.repo

#more bazzite stuff
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/bazzite/repo/fedora-${RELEASE}/kylegospo-bazzite-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo_bazzite.repo

#OBS vkcapture
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/obs-vkcapture/repo/fedora-${RELEASE}/kylegospo-obs-vkcapture-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo_obs_vkcapture.repo

#Oversteer
#wget https://copr.fedorainfracloud.org/coprs/kylegospo/oversteer/repo/fedora-${RELEASE}/kylegospo-oversteer-fedora-${RELEASE}.repo \
#  -O /etc/yum.repos.d/_copr_kylegospo-oversteer.repo

# run common packages script
#${script_dir}/install-packages.sh

#Third-Party Repositories
#https://copr.fedorainfracloud.org/coprs/ublue-os/gnome-software/repo/fedora-39/ublue-os-gnome-software-fedora-39.repo
#https://copr.fedorainfracloud.org/coprs/kylegospo/minecraft-server-hibernation/repo/fedora-39/kylegospo-minecraft-server-hibernation-fedora-39.repo
