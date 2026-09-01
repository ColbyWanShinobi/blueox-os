#!/usr/bin/env bash

# Configure the image-wide SELinux setting WinBoat needs. Rootless Podman
# migration must run for the desktop user after its subordinate ID mappings are
# configured; see setup-scripts/fix-podman.sh.
set -euo pipefail

setsebool -P container_use_devices=true
