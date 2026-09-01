#!/usr/bin/env bash

# Configure the image-wide Podman settings WinBoat needs. Per-user subordinate
# UID/GID mappings remain in setup-scripts/fix-podman.sh.
set -euo pipefail

podman system migrate
setsebool -P container_use_devices=true
