#!/bin/bash
#SOME COMMANDS YOU WANT TO EXECUTE

systemctl disable firstboot.service

# Enable AMDCTL
sudo grubby --update-kernel=ALL --args="msr.allow_writes=on"

#rm -f /etc/systemd/system/firstboot.service
#rm -f /firstboot.sh
