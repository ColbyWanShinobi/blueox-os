#!/usr/bin/env bash

# Build and install the upstream OBSBOT Control release system-wide.  Upstream
# does not provide CMake install rules, so this mirrors its maintained PKGBUILD.
set -euo pipefail

readonly APP_NAME='obsbot-camera-control'
readonly APP_VERSION='1.3.0'
readonly REPOSITORY='https://github.com/aaronsb/obsbot-camera-control.git'
readonly BUILD_ROOT="$(mktemp -d)"
readonly SOURCE_DIR="${BUILD_ROOT}/${APP_NAME}"

cleanup() {
  rm -rf "$BUILD_ROOT"
}
trap cleanup EXIT

git clone --depth 1 --branch "v${APP_VERSION}" "$REPOSITORY" "$SOURCE_DIR"

cmake -S "$SOURCE_DIR" -B "${SOURCE_DIR}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "${SOURCE_DIR}/build" --parallel "$(nproc)"

install -Dm755 "${SOURCE_DIR}/bin/obsbot-gui" /usr/bin/obsbot-gui
install -Dm755 "${SOURCE_DIR}/bin/obsbot-cli" /usr/bin/obsbot-cli

install -Dm755 "${SOURCE_DIR}/sdk/lib/libdev.so.1.0.2" /usr/lib64/libdev.so.1.0.2
ln -sfn libdev.so.1.0.2 /usr/lib64/libdev.so.1
ln -sfn libdev.so.1.0.2 /usr/lib64/libdev.so

install -Dm644 "${SOURCE_DIR}/obsbot-control.desktop" \
  /usr/share/applications/obsbot-control.desktop
install -Dm644 "${SOURCE_DIR}/resources/icons/camera.svg" \
  /usr/share/icons/hicolor/scalable/apps/obsbot-control.svg
install -Dm644 "${SOURCE_DIR}/LICENSE" \
  "/usr/share/licenses/${APP_NAME}/LICENSE"
install -Dm644 "${SOURCE_DIR}/README.md" \
  "/usr/share/doc/${APP_NAME}/README.md"

# The virtual-camera service is installed but intentionally not enabled.
install -Dm644 "${SOURCE_DIR}/resources/modprobe.d/obsbot-virtual-camera.conf" \
  /usr/lib/modprobe.d/obsbot-virtual-camera.conf
install -Dm644 "${SOURCE_DIR}/resources/systemd/obsbot-virtual-camera.service" \
  /usr/lib/systemd/system/obsbot-virtual-camera.service

ldconfig
