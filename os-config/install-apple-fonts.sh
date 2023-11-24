#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")
INSTALL_DIR=${script_dir}/AppleFonts

mkdir -p ${INSTALL_DIR}
echo "Installing Apple San Francisco font family..."

sudo mkdir -p /usr/share/fonts/truetype/apple-emoji-linux/
wget https://github.com/samuelngs/apple-emoji-linux/releases/download/v16.4-patch.1/AppleColorEmoji.ttf -O ${INSTALL_DIR}/AppleColorEmoji.ttf

# Copy Apple Emoji font to the system
sudo cp ${INSTALL_DIR}/AppleColorEmoji.ttf /usr/share/fonts/truetype/apple-emoji-linux/

# Apple San Francisco font
# Download font
git clone https://github.com/aishalih/sfwin.git ${INSTALL_DIR}/sfwin

# Make system location for font
sudo mkdir -p /usr/share/fonts/truetype/sfwin/

# Find all the .ttf font files and copy them to the system
find ${INSTALL_DIR}/sfwin -name \*.otf -exec sudo cp -v {} /usr/share/fonts/truetype/sfwin/ \;
