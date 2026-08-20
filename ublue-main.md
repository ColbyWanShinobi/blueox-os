# UBlue Main: trace from Fedora Atomic Desktop

This is a source-level trace of [ublue-os/main](https://github.com/ublue-os/main), inspected on 2026-08-20 for Fedora 44 x86_64. It documents the intermediary base used by Bazzite before Bazzite's own `Containerfile` applies its additional swaps and layers.

RPM filenames and COPR build IDs are a snapshot; resolve current artifacts from each repository's `repodata/repomd.xml` when reproducing a build.

## Starting point and outputs

The Main [Containerfile](https://github.com/ublue-os/main/blob/main/Containerfile) starts from Fedora's Atomic Desktop registry:

    quay.io/fedora-ostree-desktops/silverblue:44

For its KDE variant it uses the same mechanism with `SOURCE_IMAGE=kinoite`. Main produces the UBlue intermediary images consumed by Bazzite:

    ghcr.io/ublue-os/silverblue-main:44
    ghcr.io/ublue-os/kinoite-main:44

The build definition copies UBlue files and RPMs into a Fedora Atomic Desktop base, then runs [`install.sh`](https://github.com/ublue-os/main/blob/main/build_files/install.sh), [`initramfs.sh`](https://github.com/ublue-os/main/blob/main/build_files/initramfs.sh), and [`post-install.sh`](https://github.com/ublue-os/main/blob/main/build_files/post-install.sh).

## Core component changes

### 1. Replace Fedora's kernel with UBlue's signed kernel/artifact stack

This is the largest direct base-image replacement. Main removes Fedora's installed `kernel`, `kernel-core`, `kernel-modules`, `kernel-modules-core`, and `kernel-modules-extra` with `rpm --erase --nodeps`, then installs matching RPMs copied from the UBlue Akmods OCI build image and version-locks them.

- Source/build repository: <https://github.com/ublue-os/akmods>
- OCI build input: `ghcr.io/ublue-os/akmods:main-44`
- NVIDIA OCI input used when `BUILD_NVIDIA=Y`: `ghcr.io/ublue-os/akmods-nvidia-open:main-44`

The exact kernel RPM filenames are determined from the image's `/kernel-rpms` directory at compose time. The set always includes:

- `kernel-<EVR>.rpm`
- `kernel-core-<EVR>.rpm`
- `kernel-modules-<EVR>.rpm`
- `kernel-modules-core-<EVR>.rpm`
- `kernel-modules-extra-<EVR>.rpm`

It also installs all RPMs from the Akmods image's `/rpms/ublue-os` directory. On NVIDIA builds it runs the `nvidia-install.sh` shipped in the NVIDIA Akmods artifact. This is OCI-artifact delivery, not a normal COPR or DNF repository.

Relevant code: <https://github.com/ublue-os/main/blob/main/build_files/install.sh>

### 2. Sync the multimedia/Mesa stack from Negativo17

Main adds the Negativo17 multimedia repository at priority 90, then executes a targeted `dnf5 distro-sync` against that repository and version-locks the results.

- Repo definition: <https://negativo17.org/repos/fedora-multimedia.repo>
- Fedora 44 x86_64 base URL: <https://negativo17.org/repos/multimedia/fedora-44/x86_64/>
- Source RPM base URL: <https://negativo17.org/repos/multimedia/fedora-44/SRPMS/>

The explicitly synchronized packages are:

- `intel-gmmlib`
- `intel-mediasdk`
- `intel-vpl-gpu-rt`
- `libheif`
- `libva`
- `libva-intel-media-driver`
- `mesa-dri-drivers`
- `mesa-filesystem`
- `mesa-libEGL`
- `mesa-libGL`
- `mesa-libgbm`
- `mesa-va-drivers`
- `mesa-vulkan-drivers`

This is a replacement of Fedora builds with the Negativo17 builds, which Main's comments describe as “less crippled versions.” Bazzite later supersedes much of this Mesa stack again with Terra Mesa packages.

### 3. Layer UBlue support RPMs from the UBlue packages COPR

Main temporarily enables the UBlue packages and staging COPRs, then installs these UBlue-specific packages:

- `ublue-os-just`
- `ublue-os-luks`
- `ublue-os-signing`
- `ublue-os-udev-rules`
- `ublue-os-update-services`

Repository page: <https://copr.fedorainfracloud.org/coprs/ublue-os/packages/>

Repository base URL:

    https://download.copr.fedorainfracloud.org/results/ublue-os/packages/fedora-44-x86_64/

Current artifacts found in the repository metadata:

- `ublue-os-just`: <https://download.copr.fedorainfracloud.org/results/ublue-os/packages/fedora-44-x86_64/10802642-ublue-os-just/ublue-os-just-0.57-3.fc44.noarch.rpm>
- `ublue-os-luks`: <https://download.copr.fedorainfracloud.org/results/ublue-os/packages/fedora-44-x86_64/09824347-ublue-os-luks/ublue-os-luks-0.3-1.fc44.noarch.rpm>
- `ublue-os-signing`: <https://download.copr.fedorainfracloud.org/results/ublue-os/packages/fedora-44-x86_64/08892649-ublue-os-signing/ublue-os-signing-0.5-1.fc43.noarch.rpm>
- `ublue-os-udev-rules`: <https://download.copr.fedorainfracloud.org/results/ublue-os/packages/fedora-44-x86_64/10210073-ublue-os-udev-rules/ublue-os-udev-rules-0.10-1.fc44.noarch.rpm>
- `ublue-os-update-services`: <https://download.copr.fedorainfracloud.org/results/ublue-os/packages/fedora-44-x86_64/09288555-ublue-os-update-services/ublue-os-update-services-0.91-1.fc43.noarch.rpm>

The F43 release tags on noarch support RPMs are normal: those artifacts are still offered from the F44 COPR metadata.

### 4. Update plumbing and boot behavior

Main installs `fedora-repos-archive` and `zstd`, rebuilds a reproducible initramfs with Dracut (including the `ostree` module), and sets staged rpm-ostree updates through the configuration supplied by `ublue-os-update-services`.

It enables:

- `rpm-ostreed-automatic.timer`
- `flatpak-system-update.timer`
- global `flatpak-user-update.timer`

The build clears all version locks only at finalization, after the image payload has been composed.

## Flatpak and desktop-policy changes

Main removes `fedora-flathub-remote`, adds Flathub's remote definition, and replaces Fedora's `flatpak-add-flathub-repos.service` with a UBlue-owned service.

- UBlue service overlay: <https://github.com/ublue-os/main/blob/main/sys_files/usr/lib/systemd/system/flatpak-add-flathub-repos.service>
- Flathub remote definition: <https://dl.flathub.org/repo/flathub.flatpakrepo>

The replacement service adds Flathub enabled and adds the Fedora and Fedora-testing Flatpak remotes disabled. The service touches `/var/lib/flatpak/.ublue-initialized` to run once.

Main also:

- Removes `gnome-software-rpm-ostree` on Silverblue, disabling GNOME Software's DKMS support path.
- Removes `plasma-discover-rpm-ostree` on Kinoite through `packages.json`.
- Removes Fedora's `fedora-flathub-remote` package.
- Replaces Podman's vendor `policy.json` with the one supplied by `ublue-os-signing`.
- Adds the Linuxbrew path to `sudo`'s secure path.

## Added and removed ordinary packages

The full package policy is versioned in [packages.json](https://github.com/ublue-os/main/blob/main/packages.json). These are layers, not source patches to Fedora components.

Common additions include multimedia components (`ffmpeg`, `fdk-aac`, `libavcodec`, `libcamera`), hardware/admin tools, PipeWire extras, font packages, Distrobox, and development/terminal utilities. Silverblue gets `adw-gtk3-theme`, NFS support, and IBus packages; Kinoite gets Fcitx, Kate, and KDE support packages.

Common removals are:

- `google-noto-sans-cjk-vf-fonts`
- `default-fonts-cjk-sans`
- `fedora-third-party`

Variant-specific removals include:

- Silverblue: `totem-video-thumbnailer`, `gnome-software-rpm-ostree`
- Kinoite: `ffmpegthumbnailer`, `plasma-discover-rpm-ostree`

Main additionally installs the latest x86_64 `cosign` RPM directly from GitHub releases using [github-release-install.sh](https://github.com/ublue-os/main/blob/main/build_files/github-release-install.sh): <https://github.com/sigstore/cosign/releases/latest>.

## Filesystem overlays and small configuration deltas

Main copies the entire [`sys_files`](https://github.com/ublue-os/main/tree/main/sys_files) tree into `/`. The current tree contains:

- Dracut compression setting (`compress="zstd"`): <https://github.com/ublue-os/main/blob/main/sys_files/usr/lib/dracut/dracut.conf.d/10-compression.conf>
- UBlue Flathub service: <https://github.com/ublue-os/main/blob/main/sys_files/usr/lib/systemd/system/flatpak-add-flathub-repos.service>
- Five-day coredump retention: <https://github.com/ublue-os/main/blob/main/sys_files/usr/lib/tmpfiles.d/coredump.conf>
- DNF COPR plugin setting `distribution = fedora`, so a UBlue-derived `ID` does not make DNF request nonexistent Bazzite/Bluefin COPR chroots: <https://github.com/ublue-os/main/blob/main/sys_files/usr/share/dnf/plugins/copr.vendor.conf>

It also downloads CoreOS's emergency/rescue boot generator into the image:

- <https://raw.githubusercontent.com/coreos/fedora-coreos-config/refs/heads/stable/overlay.d/05core/usr/lib/systemd/system-generators/coreos-sulogin-force-generator>

## Repository lifetime in the final image

`ublue-os/packages` and `ublue-os/staging` are enabled only for the compose, and then removed by `post-install.sh`. Negativo17 is deliberately left installed but disabled by default in the image; it had priority 90 during composition. The resulting UBlue Main deployment contains the selected RPM payload, but does not leave the two UBlue COPRs configured for a normal user update.

## Relationship to Bazzite

This explains why Bazzite should be viewed as two layers of changes:

1. Fedora Atomic Desktop -> UBlue Main: signed UBlue kernel/akmods, Negativo17 multimedia stack, UBlue update/signing/udev tooling, Flatpak policy, and base utilities.
2. UBlue Main -> Bazzite: Bazzite's own COPR/Terra component replacements (notably WirePlumber, BlueZ, XWayland, and Mesa), gaming and handheld packages, Bazzite configuration, and optional NVIDIA/Deck layers.

See [bazzite.md](bazzite.md) for the second layer.
