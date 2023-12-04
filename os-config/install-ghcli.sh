#!/usr/bin/env bash

set -ouex pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

RELEASE="$(rpm -E %fedora)"
RPMDIR=${script_dir}/install/rpms

#distrobox
wget https://cli.github.com/packages/rpm/gh-cli.repo \
  -O /etc/yum.repos.d/gh-cli.repo

rpm-ostree install gh
