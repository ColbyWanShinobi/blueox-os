#!/usr/bin/env bash
# Fail the image build when a required RPM source cannot provide metadata.
set -Eeuo pipefail

readonly TERRA_MESA_METADATA='https://repos.fyralabs.com/terra44-mesa/repodata/repomd.xml'

printf 'Verifying Terra Mesa repository metadata...\n'
curl --fail --location --show-error --silent \
  --retry 3 --retry-all-errors --connect-timeout 15 --max-time 60 \
  --output /dev/null "$TERRA_MESA_METADATA"

printf 'Refreshing all enabled RPM repositories (unavailable sources are fatal)...\n'
dnf --setopt=skip_if_unavailable=false makecache --refresh
