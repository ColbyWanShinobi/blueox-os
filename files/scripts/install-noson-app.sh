#!/usr/bin/env bash

# Build Noson during image creation and install it into the immutable /usr tree.
# A pinned upstream revision keeps subsequent image rebuilds reproducible.
set -euo pipefail

readonly APP_NAME='noson-app'
readonly REPOSITORY='https://github.com/janbar/noson-app.git'
readonly REVISION='441981896073019e156e402b8a9901f3cbcff73d'
BUILD_ROOT="$(mktemp -d)"
readonly BUILD_ROOT
readonly SOURCE_DIR="${BUILD_ROOT}/${APP_NAME}"

cleanup() {
  rm -rf "$BUILD_ROOT"
}
trap cleanup EXIT

git init --quiet "$SOURCE_DIR"
git -C "$SOURCE_DIR" remote add origin "$REPOSITORY"
git -C "$SOURCE_DIR" fetch --depth 1 origin "$REVISION"
git -C "$SOURCE_DIR" checkout --quiet --detach FETCH_HEAD

cmake -S "$SOURCE_DIR" -B "${SOURCE_DIR}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr
cmake --build "${SOURCE_DIR}/build" --parallel "$(nproc)"
cmake --install "${SOURCE_DIR}/build"
