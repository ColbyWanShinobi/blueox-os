#!/usr/bin/env bash

set -ouex pipefail

systemctl enable rpm-ostreed-automatic.timer
#systemctl enable flatpak-system-update.timer

#Not sure what this does, but it keeps failing so...
#systemctl --global enable flatpak-user-update.timer

#systemctl enable --now com.system76.Scheduler.service

#AMDCTL
#grubby --update-kernel=ALL --args="msr.allow_writes=on"

#grub-btrfs
#systemctl enable --now grub-btrfs.path

#cp /usr/share/ublue-os/update-services/etc/rpm-ostreed.conf /etc/rpm-ostreed.conf

#ln -s "/usr/share/fonts/google-noto-sans-cjk-fonts" "/usr/share/fonts/noto-cjk"
