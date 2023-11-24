#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

IMAGE_NAME=blueox-os
CONTAINER_ID=$(docker ps -a | grep ${IMAGE_NAME} | cut -d' ' -f1) || true

docker kill ${CONTAINER_ID} || true
docker rm ${CONTAINER_ID} || true

docker build \
  --pull \
  --no-cache \
  --tag ${IMAGE_NAME} \
  --file ${script_dir}/../Containerfile \
  ${script_dir}/../
