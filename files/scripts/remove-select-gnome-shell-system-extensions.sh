#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

# Create an array of shell extension names to be removed
declare -a extensions=(
  'gnome-shell-extension-compiz*'
  'gnome-shell-extension-gamerzilla*'
  'gnome-shell-extension-hotedge*'
)

# Loop through each extension and remove it
for extension in "${extensions[@]}"; do
  # Perform a search for the full name of the extansionusing rpm -qa and then remove each full named extension returned
  rpm -qa | grep $extension | while read -r line; do
    echo "Removing gnome shell extension: $line"
    rpm-ostree override remove $line
  done
done
