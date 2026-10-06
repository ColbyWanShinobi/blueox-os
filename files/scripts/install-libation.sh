#!/usr/bin/env bash

# Install the newest Libation RPM published by upstream for this architecture.
set -euo pipefail

readonly RELEASE_API='https://api.github.com/repos/rmcrackan/Libation/releases/latest'
RPM_PATH="$(mktemp --suffix=.rpm)"
readonly RPM_PATH

cleanup() {
  rm -f "$RPM_PATH"
}
trap cleanup EXIT

for command in curl dnf install jq uname; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "${command} is required to install Libation." >&2
    exit 1
  }
done

case "$(uname -m)" in
  x86_64)
    upstream_arch='amd64'
    ;;
  aarch64)
    upstream_arch='arm64'
    ;;
  *)
    echo "Libation does not publish an RPM for $(uname -m)." >&2
    exit 1
    ;;
esac

echo 'Looking up the latest Libation release...'
release_json="$(curl --fail --location --show-error --silent \
  -H 'Accept: application/vnd.github+json' "$RELEASE_API")"
rpm_url="$(jq --raw-output --arg arch "$upstream_arch" '
  [ .assets[]
    | select(.name | test("^Libation\\..*-linux-.*-" + $arch + "\\.rpm$"))
    | .browser_download_url
  ] | first // empty
' <<<"$release_json")"

if [[ -z "$rpm_url" ]]; then
  echo "The latest Libation release has no ${upstream_arch} RPM asset." >&2
  exit 1
fi

echo "Downloading ${rpm_url##*/}..."
curl --fail --location --show-error --silent --output "$RPM_PATH" "$rpm_url"

echo 'Installing Libation...'
# Libation's %post writes a sysctl setting and immediately reloads it. A
# container build must not modify the builder's kernel, so install its files
# without RPM scriptlets and provide the persistent setting below instead.
dnf --setopt=tsflags=noscripts install -y "$RPM_PATH"

install -Dm644 /dev/stdin /usr/lib/sysctl.d/90-libation.conf <<'EOF'
# Required by Libation when monitoring a large library.
fs.inotify.max_user_instances = 524288
EOF
