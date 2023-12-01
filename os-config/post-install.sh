#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

cp -Rv ${script_dir}/etc/* /etc
cp -Rv ${script_dir}/usr/* /usr

#OSTree Timer
systemctl enable rpm-ostreed-automatic.timer

# Enable Flatpak Daily Update
systemctl enable flatpak-system-update.timer
systemctl --global enable flatpak-user-update.timer

# Enable System76 scheduler
systemctl enable com.system76.Scheduler.service

# LACT
systemctl enable lactd

# Fingerprint Reader on Thinkpads
#systemctl enable open-fprintd-resume.service 
#systemctl enable open-fprintd-suspend.service 
#systemctl enable open-fprintd.service 
#systemctl enable python3-validity.service
#systemctl start python3-validity.service
#systemctl start open-fprintd.service
#authselect enable-feature with-fingerprint
#authselect apply-changes

#AMDCTL
#grubby --update-kernel=ALL --args="msr.allow_writes=on"

#grub-btrfs
#systemctl enable --now grub-btrfs.path

#cp /usr/share/ublue-os/update-services/etc/rpm-ostreed.conf /etc/rpm-ostreed.conf
#ln -s "/usr/share/fonts/google-noto-sans-cjk-fonts" "/usr/share/fonts/noto-cjk"
