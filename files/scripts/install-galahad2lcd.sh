#!/usr/bin/env bash

# Build the Galahad II LCD streaming service from its archived upstream source.
# The service remains disabled because its required video/GIF path is specific
# to each installed system. Configure it with `sudo galahad2lcd set-args ...`.
set -euo pipefail

readonly APP_NAME='galahad2lcd'
readonly REPOSITORY='https://github.com/ColbyWanShinobi/GalahadII_LCD_Linux.git'
readonly REVISION='3a9d2028f2f0031fee7736826e1982f423e63bea'
readonly BUILD_ROOT="$(mktemp -d)"
readonly SOURCE_DIR="${BUILD_ROOT}/GalahadII_LCD_Linux"

cleanup() {
  rm -rf "$BUILD_ROOT"
}
trap cleanup EXIT

git clone --depth 1 "$REPOSITORY" "$SOURCE_DIR"
git -C "$SOURCE_DIR" checkout --detach "$REVISION"

cargo build --manifest-path "${SOURCE_DIR}/Cargo.toml" --release --locked

install -Dm755 "${SOURCE_DIR}/target/release/${APP_NAME}" \
  "/usr/bin/${APP_NAME}"
install -Dm644 "${SOURCE_DIR}/README.md" \
  "/usr/share/doc/${APP_NAME}/README.md"

install -Dm644 /dev/stdin "/usr/lib/systemd/system/${APP_NAME}.service" <<'EOF'
[Unit]
Description=Lian Li Galahad II LCD streaming service
After=network.target
ConditionPathExists=/etc/default/galahad2lcd

[Service]
Type=simple
EnvironmentFile=/etc/default/galahad2lcd
RuntimeDirectory=galahad2lcd
Environment=GALAHAD_CACHE_DIR=%t/galahad2lcd
ExecStartPre=/bin/sleep 8
ExecStart=/usr/bin/galahad2lcd daemon $MYAPP_ARGS
Restart=on-failure
RestartSec=5s
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
