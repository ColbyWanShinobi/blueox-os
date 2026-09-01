#!/usr/bin/env bash

set -euo pipefail

set_user_cfg_option() {
    local key="$1"
    local value="$2"

    # user.cfg is sourced by Fedora Atomic's static GRUB config. Remove only
    # the option this script owns, then append its current value.
    sudo sed -i "/^[[:space:]]*set[[:space:]]\\+${key}=/d" "$GRUB_FILE"
    printf 'set %s=%s\n' "$key" "$value" | sudo tee -a "$GRUB_FILE" >/dev/null
}

update_windows_entry() {
    local windows_file="$1"
    local probe_result=""
    local efi_device=""
    local efi_uuid=""

    # custom.cfg is sourced after Fedora Atomic's BLS entries, keeping Windows
    # at the bottom of the menu. Remove only the block managed by this script
    # so rerunning it does not create duplicates or retain a stale entry.
    sudo install -d -m 0755 "$(dirname "$windows_file")"
    sudo touch "$windows_file"
    sudo sed -i '/^# BEGIN BazziteSetupScript Windows entry$/,/^# END BazziteSetupScript Windows entry$/d' "$windows_file"

    if command -v os-prober >/dev/null 2>&1; then
        probe_result="$(sudo os-prober 2>/dev/null | awk -F: '$3 == "Windows" && $4 == "efi" { print $1; exit }' || true)"
        efi_device="${probe_result%%@*}"
        [[ "$efi_device" == /dev/* ]] || efi_device=""
    fi

    # os-prober may not be installed. Check the currently mounted ESP as a
    # useful fallback for machines that share it with Windows.
    if [[ -z "$efi_device" && -f /boot/efi/EFI/Microsoft/Boot/bootmgfw.efi ]]; then
        efi_device="$(findmnt -n -o SOURCE --target /boot/efi 2>/dev/null || true)"
    fi

    if [[ -z "$efi_device" ]]; then
        echo "Windows Boot Manager was not found; no Windows GRUB entry was added."
        return
    fi

    efi_uuid="$(sudo blkid -s UUID -o value "$efi_device" 2>/dev/null || true)"
    if [[ -z "$efi_uuid" ]]; then
        echo "Could not read the EFI filesystem UUID for $efi_device; no Windows GRUB entry was added."
        return
    fi

    sudo tee -a "$windows_file" >/dev/null <<EOF
# BEGIN BazziteSetupScript Windows entry
menuentry 'Windows Boot Manager (UEFI)' --class windows --class os {
    insmod part_gpt
    insmod fat
    search --no-floppy --fs-uuid --set=windows_efi $efi_uuid
    chainloader (\$windows_efi)/EFI/Microsoft/Boot/bootmgfw.efi
}
# END BazziteSetupScript Windows entry
EOF

    echo "Added a Windows Boot Manager entry for $efi_device."
}

GRUB_FILE="/boot/grub2/user.cfg"
WINDOWS_FILE="/boot/grub2/custom.cfg"
sudo install -d -m 0755 /boot/grub2
sudo touch "$GRUB_FILE"

set_user_cfg_option "timeout" "5"
# Fedora Atomic's static GRUB configuration does not provide the
# `savedefault` command. Use the first menu entry instead of enabling saved
# entry support, which would make GRUB abort while sourcing user.cfg.
set_user_cfg_option "default" "0"
# Remove the setting written by older versions of this script. Leaving it in
# user.cfg makes the script non-idempotent and can cause the static config to
# emit/use the unsupported `savedefault` command.
sudo sed -i '/^[[:space:]]*set[[:space:]]\+save_default=/d' "$GRUB_FILE"
sudo sed -i '/^[[:space:]]*savedefault[[:space:]]*$/d' "$GRUB_FILE"
set_user_cfg_option "gfxmode" "1920x1080,auto"
set_user_cfg_option "gfxpayload" "keep"
set_user_cfg_option "menu_color_normal" "white/black"
set_user_cfg_option "menu_color_highlight" "black/light-gray"
# Keep all display settings in one managed block. The individual deletes
# migrate output from earlier versions that did not use block markers.
sudo sed -i '/^# BEGIN BazziteSetupScript GRUB display$/,/^# END BazziteSetupScript GRUB display$/d' "$GRUB_FILE"
sudo sed -i "/^# Use GRUB's Unicode font so menu box-drawing glyphs render as solid lines\\.$/d" "$GRUB_FILE"
sudo sed -i '/^[[:space:]]*insmod[[:space:]]\+font$/d' "$GRUB_FILE"
sudo sed -i '/^[[:space:]]*insmod[[:space:]]\+gfxterm$/d' "$GRUB_FILE"
sudo sed -i '/^[[:space:]]*terminal_output[[:space:]]\+gfxterm$/d' "$GRUB_FILE"
sudo sed -i '/^[[:space:]]*loadfont[[:space:]].*unicode\.pf2$/d' "$GRUB_FILE"
cat <<'EOF' | sudo tee -a "$GRUB_FILE" >/dev/null
# BEGIN BazziteSetupScript GRUB display
# Use GRUB's Unicode font so menu box-drawing glyphs render as solid lines.
insmod font
if loadfont ($prefix)/fonts/unicode.pf2; then
    insmod gfxterm
    terminal_output gfxterm
fi
# END BazziteSetupScript GRUB display
EOF
# Migrate an entry written by earlier versions of this script.
sudo sed -i '/^# BEGIN BazziteSetupScript Windows entry$/,/^# END BazziteSetupScript Windows entry$/d' "$GRUB_FILE"
update_windows_entry "$WINDOWS_FILE"

echo "Updated /boot/grub2/user.cfg for Fedora Atomic/Silverblue."
