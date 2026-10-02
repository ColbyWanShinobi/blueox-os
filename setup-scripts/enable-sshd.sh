#!/usr/bin/env bash
# Enable OpenSSH and permit each configured SSH listen port through firewalld.
# Safe to run repeatedly.

set -euo pipefail

if ! command -v sshd >/dev/null 2>&1; then
    echo "OpenSSH server is not installed. Install the openssh-server package first." >&2
    exit 1
fi

if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "firewalld is not installed. Install the firewalld package first." >&2
    exit 1
fi

sudo systemctl enable --now sshd
sudo systemctl enable --now firewalld

# Obtain the effective global Port directives, including a custom SSH port.
# Starting sshd first also ensures its runtime directory and host keys exist.
sshd_config=$(sudo sshd -T) || {
    echo "Unable to read sshd's effective configuration." >&2
    exit 1
}
mapfile -t ssh_ports < <(awk '$1 == "port" { print $2 }' <<<"$sshd_config" | sort -nu)
if ((${#ssh_ports[@]} == 0)); then
    echo "Could not determine an SSH listen port from sshd's configuration." >&2
    exit 1
fi

changed=false
for port in "${ssh_ports[@]}"; do
    if ! sudo firewall-cmd --permanent --query-port="${port}/tcp" >/dev/null; then
        sudo firewall-cmd --permanent --add-port="${port}/tcp"
        changed=true
    fi
done

if "$changed"; then
    sudo firewall-cmd --reload
fi

printf 'sshd is enabled and running. Firewall permits: '
printf '%s/tcp ' "${ssh_ports[@]}"
printf '\n'
