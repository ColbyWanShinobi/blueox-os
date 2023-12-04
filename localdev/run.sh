#!/usr/bin/env bash

set -oue pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

IMAGE_NAME=blueox-os

docker run -it \
  -v ${script_dir}/../os-config:/tmp/os-config \
  ${IMAGE_NAME} \
  bash
