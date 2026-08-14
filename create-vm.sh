#!/usr/bin/env bash
# Create and start a Linux virtual machine with QEMU.
set -euo pipefail
umask 077

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VM_ROOT="$SCRIPT_DIR/.linux-vm"
SHARE_DIR="${HOME}/VMShare"

RAM="4G"
CPUS="4"
DISK_SIZE="40G"
VM_NAME="linux"
FIRMWARE="uefi"
ISO=""

usage() {
  cat <<'EOF'
Usage: ./create.sh [LINUX.iso] [options]

Create or start a QEMU Linux VM. Supply an ISO to boot an installer; omit it
when restarting an existing VM. The ISO can also be provided with --iso.

Options:
  -i, --iso PATH        Linux installation/live ISO
  -n, --name NAME       VM name and storage directory (default: linux)
  -m, --ram SIZE        Guest memory (default: 4G)
  -c, --cpus COUNT      Guest CPU threads (default: 4)
  -d, --disk-size SIZE  New virtual disk size (default: 40G)
  -f, --firmware TYPE   bios or uefi (default: uefi)
      --no-share        Do not expose ~/VMShare to this VM
  -h, --help            Show this help

Examples:
  ./create.sh ~/Downloads/Fedora-Workstation.iso
  ./create.sh --iso Debian.iso --name debian --ram 8G --cpus 6 --disk-size 80G
  ./create.sh --name debian

VM files are stored in .linux-vm/NAME. When sharing is enabled, mount the host
folder inside a Linux guest with:
  sudo mkdir -p /mnt/hostshare
  sudo mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt/hostshare
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

while (($#)); do
  case "$1" in
    -i|--iso)
      (($# >= 2)) || die "$1 requires a value"
      ISO=$2
      shift 2
      ;;
    -n|--name)
      (($# >= 2)) || die "$1 requires a value"
      VM_NAME=$2
      shift 2
      ;;
    -m|--ram)
      (($# >= 2)) || die "$1 requires a value"
      RAM=$2
      shift 2
      ;;
    -c|--cpus|--threads)
      (($# >= 2)) || die "$1 requires a value"
      CPUS=$2
      shift 2
      ;;
    -d|--disk-size)
      (($# >= 2)) || die "$1 requires a value"
      DISK_SIZE=$2
      shift 2
      ;;
    -f|--firmware)
      (($# >= 2)) || die "$1 requires a value"
      FIRMWARE=${2,,}
      shift 2
      ;;
    --no-share)
      SHARE_DIR=""
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *)
      [[ -z "$ISO" ]] || die "Only one ISO path may be supplied"
      ISO=$1
      shift
      ;;
  esac
done

[[ "$VM_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || die "VM name may contain letters, digits, ., _, and -"
[[ "$CPUS" =~ ^[1-9][0-9]*$ ]] || die "CPU thread count must be a positive integer"
[[ "$RAM" =~ ^[1-9][0-9]*([MmGg])?$ ]] || die "RAM must look like 4G or 4096M"
[[ "$DISK_SIZE" =~ ^[1-9][0-9]*([MmGgTt])?$ ]] || die "Disk size must look like 40G"
[[ "$FIRMWARE" == bios || "$FIRMWARE" == uefi ]] || die "Firmware must be bios or uefi"
[[ -z "$ISO" || -f "$ISO" ]] || die "ISO does not exist or is not a regular file: $ISO"

command -v qemu-system-x86_64 >/dev/null || die "qemu-system-x86_64 is required"
command -v qemu-img >/dev/null || die "qemu-img is required"

VM_DIR="$VM_ROOT/$VM_NAME"
DISK_IMAGE="$VM_DIR/linux.qcow2"
PID_FILE="$VM_DIR/qemu.pid"
UEFI_VARS="$VM_DIR/OVMF_VARS.fd"

mkdir -p "$VM_DIR"
if [[ -e "$PID_FILE" ]]; then
  old_pid=$(<"$PID_FILE")
  if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
    die "The $VM_NAME VM is already running (PID $old_pid)"
  fi
  rm -f -- "$PID_FILE"
fi

if [[ ! -e "$DISK_IMAGE" ]]; then
  [[ -n "$ISO" ]] || die "No disk exists for '$VM_NAME'; supply a Linux ISO to create one"
  qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
elif [[ ! -f "$DISK_IMAGE" ]]; then
  die "VM disk path exists but is not a regular file: $DISK_IMAGE"
fi

if [[ -n "$SHARE_DIR" ]]; then
  mkdir -p "$SHARE_DIR"
fi

QEMU_ARGS=(
  -name "$VM_NAME"
  -machine q35,accel=kvm:tcg
  -smp "$CPUS"
  -m "$RAM"
  -drive "file=$DISK_IMAGE,format=qcow2,if=virtio"
  -display gtk,zoom-to-fit=on,show-cursor=on
  -vga virtio
  -device qemu-xhci,id=xhci
  -device usb-tablet,bus=xhci.0
  -netdev user,id=net0
  -device virtio-net-pci,netdev=net0
  -spice port=0,disable-ticketing=on,disable-copy-paste=off
  -device virtio-serial-pci
  -chardev spicevmc,id=vdagent,name=vdagent
  -device virtserialport,chardev=vdagent,name=com.redhat.spice.0
)

if [[ -r /dev/kvm && -w /dev/kvm ]]; then
  QEMU_ARGS+=( -cpu host )
else
  printf 'KVM is unavailable; using slower software emulation.\n' >&2
  QEMU_ARGS+=( -cpu max )
fi

if [[ -n "$ISO" ]]; then
  QEMU_ARGS+=( -drive "file=$ISO,media=cdrom,readonly=on" -boot order=dc,menu=on )
else
  QEMU_ARGS+=( -boot order=c,menu=on )
fi

if [[ -n "$SHARE_DIR" ]]; then
  QEMU_ARGS+=( -virtfs "local,path=$SHARE_DIR,mount_tag=hostshare,security_model=none,readonly=off" )
fi

if [[ "$FIRMWARE" == uefi ]]; then
  OVMF_CODE=""
  OVMF_VARS_TEMPLATE=""
  for candidate in /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/OVMF/OVMF_CODE.fd; do
    [[ -r "$candidate" ]] && OVMF_CODE=$candidate && break
  done
  for candidate in /usr/share/edk2/x64/OVMF_VARS.4m.fd /usr/share/OVMF/OVMF_VARS.fd; do
    [[ -r "$candidate" ]] && OVMF_VARS_TEMPLATE=$candidate && break
  done
  [[ -n "$OVMF_CODE" && -n "$OVMF_VARS_TEMPLATE" ]] || die "UEFI requires OVMF/edk2 firmware (install an ovmf or edk2-ovmf package)"
  [[ -f "$UEFI_VARS" ]] || cp -- "$OVMF_VARS_TEMPLATE" "$UEFI_VARS"
  QEMU_ARGS+=(
    -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
    -drive "if=pflash,format=raw,file=$UEFI_VARS"
  )
fi

cleanup() {
  rm -f -- "$PID_FILE"
}
trap cleanup EXIT INT TERM

printf 'Starting Linux VM %s. Disk: %s\n' "$VM_NAME" "$DISK_IMAGE"
if [[ -n "$SHARE_DIR" ]]; then
  printf 'Host share: %s (guest mount tag: hostshare)\n' "$SHARE_DIR"
fi
printf 'Install spice-vdagent in the guest for clipboard integration.\n'

qemu-system-x86_64 "${QEMU_ARGS[@]}" &
qemu_pid=$!
printf '%s\n' "$qemu_pid" > "$PID_FILE"
wait "$qemu_pid"
