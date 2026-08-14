#!/usr/bin/env bash
# Stop and remove a QEMU Linux VM created by create.sh.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VM_ROOT="$SCRIPT_DIR/.linux-vm"

usage() {
  printf 'Usage: ./destroy.sh [VM_NAME]\n'
}

[[ $# -le 1 ]] || { usage >&2; exit 2; }
case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac
requested=${1:-}
[[ -z "$requested" || "$requested" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || { usage >&2; exit 2; }

available=()
if [[ -d "$VM_ROOT" ]]; then
  while IFS= read -r -d '' directory; do
    available+=("${directory##*/}")
  done < <(find "$VM_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
fi

if [[ -n "$requested" ]]; then
  [[ -d "$VM_ROOT/$requested" ]] || { printf 'No %s VM exists.\n' "$requested" >&2; exit 1; }
  selected=$requested
elif ((${#available[@]} == 0)); then
  printf 'No VM files found in %s\n' "$VM_ROOT"
  exit 0
elif ((${#available[@]} == 1)); then
  selected=${available[0]}
elif [[ -t 0 ]]; then
  PS3='Choose a VM to destroy (or cancel): '
  select choice in "${available[@]}" Cancel; do
    [[ -n "$choice" ]] || { printf 'Invalid selection.\n' >&2; continue; }
    [[ "$choice" != Cancel ]] || exit 0
    selected=$choice
    break
  done
else
  printf 'More than one VM exists; specify its name.\n' >&2
  exit 2
fi

VM_DIR="$VM_ROOT/$selected"
PID_FILE="$VM_DIR/qemu.pid"
if [[ -f "$PID_FILE" ]]; then
  pid=$(<"$PID_FILE")
  process_args=$(ps -p "$pid" -o args= 2>/dev/null || true)
  if [[ "$pid" =~ ^[0-9]+$ ]] && [[ "$process_args" == *qemu-system-x86_64* ]] && [[ "$process_args" == *"$VM_DIR"* ]] && kill -0 "$pid" 2>/dev/null; then
    printf 'Stopping %s VM (PID %s)...\n' "$selected" "$pid"
    kill "$pid"
    for _ in {1..50}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done
    kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
  fi
fi

rm -rf -- "$VM_DIR"
printf 'Removed %s VM files from %s\n' "$selected" "$VM_DIR"
printf 'The shared host folder ~/VMShare was kept.\n'
