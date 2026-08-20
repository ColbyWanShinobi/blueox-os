# Bazzite RPM patch/source map

This is a snapshot of the Bazzite build as inspected on 2026-08-20, for Fedora 44 x86_64. RPM filenames and COPR build IDs change; use each repository's `repodata/repomd.xml` to resolve a current artifact.

## Build model

Bazzite does not apply one monolithic patch RPM to Fedora Silverblue. It starts from UBlue's Silverblue/Kinoite base image and then selectively replaces a few core Fedora components, layers gaming/handheld packages, and copies configuration into the image.

- Build definition: <https://github.com/ublue-os/bazzite/blob/main/Containerfile>
- Build matrix, including the Silverblue base selection: <https://github.com/ublue-os/bazzite/blob/main/.github/workflows/build.yml>
- Intermediate UBlue base: <https://github.com/ublue-os/main>

For the GNOME variants, Bazzite's base image is `ghcr.io/ublue-os/silverblue-main:44`; KDE variants use the corresponding Kinoite image.

## Direct replacements of Fedora components

### Bazzite COPR

Repository page: <https://copr.fedorainfracloud.org/coprs/ublue-os/bazzite/>

Repository base URL:

    https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite/fedora-44-x86_64/

#### WirePlumber: Bazzite audio policy

- <https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite/fedora-44-x86_64/10389093-wireplumber/wireplumber-0.5.12-1.fc44.bazzite.0.0.git.7578.516dcde7.x86_64.rpm>
- <https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite/fedora-44-x86_64/10389093-wireplumber/wireplumber-libs-0.5.12-1.fc44.bazzite.0.0.git.7578.516dcde7.x86_64.rpm>

The Bazzite spec applies `block_steam_clear_default.patch`:

- <https://github.com/ublue-os/bazzite/blob/main/spec_files/wireplumber/wireplumber.spec>
- <https://github.com/ublue-os/bazzite/blob/main/spec_files/wireplumber/block_steam_clear_default.patch>

#### UPower: handheld/deck builds only

- <https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite/fedora-44-x86_64/10464073-upower/upower-1.91.2-1000.bazzite.0.0.git.7704.d9e4df6d.x86_64.rpm>
- <https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite/fedora-44-x86_64/10464073-upower/upower-libs-1.91.2-1000.bazzite.0.0.git.7704.d9e4df6d.x86_64.rpm>

The spec applies a Valve patch:

- <https://github.com/ublue-os/bazzite/blob/main/spec_files/upower/upower.spec>
- <https://github.com/ublue-os/bazzite/blob/main/spec_files/upower/valve.patch>

### Bazzite multilib COPR

Repository page: <https://copr.fedorainfracloud.org/coprs/ublue-os/bazzite-multilib/>

Repository base URL:

    https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite-multilib/fedora-44-x86_64/

#### BlueZ: Valve Bluetooth behavior

- <https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite-multilib/fedora-44-x86_64/10738736-bluez/bluez-5.87-2.fc44.bazzite.0.0.git.7950.32d2ebd9.dirty.3sl9q6.x86_64.rpm>
- <https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite-multilib/fedora-44-x86_64/10738736-bluez/bluez-libs-5.87-2.fc44.bazzite.0.0.git.7950.32d2ebd9.dirty.3sl9q6.x86_64.rpm>
- <https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite-multilib/fedora-44-x86_64/10738736-bluez/bluez-obexd-5.87-2.fc44.bazzite.0.0.git.7950.32d2ebd9.dirty.3sl9q6.x86_64.rpm>
- <https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite-multilib/fedora-44-x86_64/10738736-bluez/bluez-cups-5.87-2.fc44.bazzite.0.0.git.7950.32d2ebd9.dirty.3sl9q6.x86_64.rpm>

Patch sources:

- <https://github.com/ublue-os/bazzite/tree/main/spec_files/bluez>
- <https://github.com/ublue-os/bazzite/blob/main/spec_files/bluez/bluez.spec>

This includes Bazzite's crash fix plus Valve-derived Bluetooth configuration, PHY, wake policy, privacy, and GATT preference patches.

#### XWayland: SteamOS/Nobara behavior

- <https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite-multilib/fedora-44-x86_64/10461169-xorg-x11-server-Xwayland/xorg-x11-server-Xwayland-24.1.11.bazzite.0.0.git.7700.2d6aa7f1-1.fc44.x86_64.rpm>

Patch sources:

- <https://github.com/ublue-os/bazzite/tree/main/spec_files/xorg-x11-server-Xwayland>
- <https://github.com/ublue-os/bazzite/blob/main/spec_files/xorg-x11-server-Xwayland/xwayland-pointer-warp-fix.patch>

The spec also contains two SteamOS reverts related to XWayland commits/`allow_commits`.

#### KWin: available from the multilib COPR

- <https://download.copr.fedorainfracloud.org/results/ublue-os/bazzite-multilib/fedora-44-x86_64/10577081-kwin/kwin-6.6.5-1000.x86_64.rpm>
- <https://github.com/ublue-os/bazzite/blob/main/spec_files/kwin/9278.patch>

KWin is available in this source, but is not one of the packages explicitly swapped in the current top-level `Containerfile`, unlike BlueZ and XWayland.

### Terra Mesa

Bazzite explicitly describes this as its Valve-patched Mesa source.

- Repository: <https://repos.fyralabs.com/terra44-mesa/>
- Current x86_64 example: <https://repos.fyralabs.com/terra44-mesa/mesa-filesystem-1:26.2.1-4.fc44.x86_64.rpm>

The image swaps `mesa-filesystem`, then version-locks the resulting Mesa stack. Relevant package names are:

- `mesa-dri-drivers`
- `mesa-filesystem`
- `mesa-libEGL`
- `mesa-libGL`
- `mesa-libgbm`
- `mesa-vulkan-drivers`

Both x86_64 and i686 Mesa libraries are used for gaming. `mesa-libOpenCL` is also installed from this repository.

### UBlue staging COPR

Repository page: <https://copr.fedorainfracloud.org/coprs/ublue-os/staging/>

The Bazzite Containerfile explicitly swaps `ostree` from this repository:

- <https://download.copr.fedorainfracloud.org/results/ublue-os/staging/fedora-44-x86_64/10877736-ostree/ostree-2026.3-2.x86_64.rpm>

## Layers rather than core-component replacements

These are part of the Bazzite image but should not be read as patches to a Silverblue core component.

### UBlue packages COPR

- Repository: <https://copr.fedorainfracloud.org/coprs/ublue-os/packages/>
- Base URL: <https://download.copr.fedorainfracloud.org/results/ublue-os/packages/fedora-44-x86_64/>
- Bazaar: <https://download.copr.fedorainfracloud.org/results/ublue-os/packages/fedora-44-x86_64/10856688-bazaar/bazaar-0.9.3-4.fc44.x86_64.rpm>
- Media automount udev: <https://download.copr.fedorainfracloud.org/results/ublue-os/packages/fedora-44-x86_64/09536500-ublue-os-media-automount-udev/ublue-os-media-automount-udev-0.19-1.fc44.noarch.rpm>

The repo is also used for Bazzite applications and support packages such as SELinux workarounds.

### Kernel and modules

Bazzite consumes kernel and kmod RPMs from UBlue OCI build artifacts rather than enabling a conventional kernel RPM repository:

- Source/build repository: <https://github.com/ublue-os/akmods>
- Registry namespace: <https://github.com/orgs/ublue-os/packages?repo_name=akmods>

The build currently selects an OGC kernel artifact and copies its kernel RPMs and akmods into the image. NVIDIA artifacts are pulled from related `akmods-nvidia-*` OCI images.

### Non-RPM image inputs

- Nonfree firmware is copied from the git submodule: <https://github.com/ublue-os/bazzite-firmware-nonfree>
- The Bazzite source repository contains additional configuration and direct file overlays: <https://github.com/ublue-os/bazzite/tree/main/system_files>

## Other enabled repositories

The build also enables the following temporarily. These mostly provide applications, codecs, fonts, or ancillary gaming software, rather than the selective OS-component patch set above.

- Terra: <https://repos.fyralabs.com/terra44/>
- Audinux COPR: <https://copr.fedorainfracloud.org/coprs/ycollet/audinux/>
- Nerd Fonts COPR: <https://copr.fedorainfracloud.org/coprs/che/nerd-fonts/>
- Negativo17 multimedia: <https://negativo17.org/repos/multimedia/fedora/>
- Kernel CachyOS addons COPR (enabled temporarily for `scx-*` packages): <https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos-addons/>

## Important implementation detail

The Bazzite build enables its COPRs only while composing the immutable image, then disables them before finalizing the image. The resulting deployment contains the selected RPM contents; it does not leave the Bazzite COPRs enabled for normal user updates.
