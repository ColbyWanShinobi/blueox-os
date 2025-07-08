#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

# Create an array of shell extension names to be removed
declare -a extensions=(
  'gnome-shell-extension-burn-my-windows-46-1.fc42.noarch'
  'gnome-shell-extension-compiz-alike-magic-lamp-effect-0.0.git.5689.e65cf76b-1.fc42.noarch'
  'gnome-shell-extension-compiz-windows-effect-0.0.git.5689.e65cf76b-1.fc42.noarch'
  'gnome-shell-extension-desktop-cube-28-1.fc42.noarch'
  'gnome-shell-extension-hanabi-0.0.git.403.ef70e818-1.fc42.noarch'
  'gnome-shell-extension-hotedge-0.0.git.67.2fb8340a-1.fc42.noarch'
  'gnome-shell-extension-launch-new-instance-48.2-1.fc42.noarch'
  'gnome-shell-extension-places-menu-48.2-1.fc42.noarch'
  'gnome-shell-extension-bazzite-menu-0.0.git.350.a5ef7dc6-1.fc42.noarch'
  'gnome-shell-extension-window-list-48.2-1.fc42.noarch'
)

# Loop through each extension and remove it
for extension in "${extensions[@]}"; do
  # Perform a search for the full name of the extansionusing rpm -qa and then remove each full named extension returned
  rpm -qa | grep $extension | while read -r line; do
    echo "Removing gnome shell extension: $line"
    rpm-ostree override remove $line
  done
done
