#!/usr/bin/env bash

# Layer the current Slack RPM published for RHEL/Fedora-compatible systems.
set -euo pipefail

readonly DOWNLOAD_PAGE_URL='https://slack.com/downloads/instructions/linux?build=rpm&ddl=1'
RPM_PATH="$(mktemp --suffix=.rpm)"
REPACKAGED_RPM_DIR="$(mktemp --directory)"
readonly RPM_PATH REPACKAGED_RPM_DIR

cleanup() {
  rm -f "$RPM_PATH"
  rm -rf "$REPACKAGED_RPM_DIR"
}
trap cleanup EXIT

command -v curl >/dev/null 2>&1 || {
  echo 'curl is required to install Slack.' >&2
  exit 1
}
command -v rpm >/dev/null 2>&1 || {
  echo 'rpm is required to install Slack.' >&2
  exit 1
}
command -v rpmrebuild >/dev/null 2>&1 || {
  echo 'rpmrebuild is required to repackage Slack.' >&2
  exit 1
}

echo 'Resolving the current Slack RPM...'
RPM_URL="$(
  curl --fail --location --show-error --silent --compressed "$DOWNLOAD_PAGE_URL" \
    | grep --only-matching --extended-regexp \
      'https://downloads\.slack-edge\.com/desktop-releases/linux/x64/[^"[:space:]]+\.rpm' \
    | sed --quiet '1p'
)"

if [[ -z "$RPM_URL" ]]; then
  echo 'Unable to find the current x86_64 Slack RPM on Slack download page.' >&2
  exit 1
fi

echo 'Downloading Slack Fedora RPM...'
curl --fail --location --show-error --silent --output "$RPM_PATH" "$RPM_URL"

RPM_RELEASE="$(rpm --query --package --queryformat '%{RELEASE}' "$RPM_PATH")"

echo 'Repackaging Slack without non-runtime build-ID links...'
# Slack and WinBoat bundle identical Electron helper binaries.  Vendor RPMs
# publish build-ID symlinks globally under /usr/lib/.build-id, which makes RPM
# treat the otherwise independent packages as conflicting. Remove those entries
# from the generated %files manifest and suppress automatic regeneration.
# These links are for debugger lookup only; Slack never uses them at runtime.
#
# Do not delete the staging files with --change-files: rpmrebuild validates the
# generated manifest before applying its spec-section filters. Omitting their
# manifest entries is both sufficient and compatible with that ordering.
rpmrebuild \
  --package \
  --batch \
  --define='_build_id_links none' \
  --release="${RPM_RELEASE}.blueox" \
  --directory="$REPACKAGED_RPM_DIR" \
  --change-spec-files='grep -v /usr/lib/.build-id' \
  "$RPM_PATH"

REPACKAGED_RPM="$(find "$REPACKAGED_RPM_DIR" -type f -name '*.rpm' -print -quit)"
if [[ -z "$REPACKAGED_RPM" ]]; then
  echo 'rpmrebuild did not produce a Slack RPM.' >&2
  exit 1
fi

if rpm --query --list --package "$REPACKAGED_RPM" \
  | grep --fixed-strings --quiet '/usr/lib/.build-id'; then
  echo 'Repackaged Slack RPM still contains build-ID links.' >&2
  exit 1
fi

echo 'Installing Slack...'
rpm --install "$REPACKAGED_RPM"
