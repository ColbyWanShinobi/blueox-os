#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

IMAGE_NAME=blueox-os-skelli
CONTAINER_ID=$(podman ps -a | grep ${IMAGE_NAME} | cut -d' ' -f1) || true

podman kill ${CONTAINER_ID} || true
podman rm ${CONTAINER_ID} || true

podman build \
  --pull \
  --no-cache \
  --tag docker.owljet.com/${IMAGE_NAME} \
  --file ${script_dir}/../Containerfile \
  ${script_dir}/../
