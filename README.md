# BlueOx OS

[![Build Redux image](https://github.com/colbywanshinobi/blueox-os/actions/workflows/build.yml/badge.svg)](https://github.com/colbywanshinobi/blueox-os/actions/workflows/build.yml)

BlueOx OS is a personal Fedora Atomic desktop image built with [BlueBuild](https://blue-build.org/) and published to GitHub Container Registry (GHCR). The current release image is built from `recipes/redux.yml`, based on `ghcr.io/ublue-os/silverblue-main`.

## Use the released image

The Redux workflow publishes these equivalent tags:

```text
ghcr.io/colbywanshinobi/blueox-os:latest
ghcr.io/colbywanshinobi/blueox-os:redux
```

Use `:latest` for the normal moving release channel; `:redux` is the explicit image-flavor tag. Images are signed with this repository's [`cosign.pub`](./cosign.pub). For a first install from another Fedora Atomic or Universal Blue image, bootstrap the BlueOx signing policy with the unsigned transport, reboot, then switch to the signed transport:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/colbywanshinobi/blueox-os:latest
systemctl reboot
```

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/colbywanshinobi/blueox-os:latest
systemctl reboot
```

Afterward, use the system's normal `rpm-ostree upgrade` process for updates. To verify an image separately:

```bash
cosign verify --key cosign.pub ghcr.io/colbywanshinobi/blueox-os:latest
```

The image also includes `blueox-update`, which explicitly moves the system to the newest signed `:latest` image and stages it for the next boot:

```bash
blueox-update
# or stage and reboot immediately
blueox-update --reboot
```

## Installer ISO and releases

The signed OCI image is the continuous release artifact. The **Build Redux image** workflow validates pull requests and publishes `:latest` and `:redux` from default-branch pushes and the daily schedule. Push and pull-request builds run only when a Redux recipe input changes (the recipe, signing key, Redux system files, or a script used by Redux); the daily run still captures upstream base-image updates.

To create installer media, open **Actions → Build Redux installer ISO → Run workflow**. Select the published image tag—normally `redux`.

- Every ISO run uploads an Anaconda installer ISO and `SHA256SUMS` as a 14-day workflow artifact.
- Provide a `release_tag` such as `2026.08.13` to also create a GitHub Release with both files attached.
- The Release notes link to the exact GHCR image used by that ISO. OCI images themselves stay in GitHub Packages, not as GitHub Release assets.

Verify a downloaded ISO before flashing it:

```bash
sha256sum -c SHA256SUMS
```

The ISO is generated from the published OCI image using Bootc Image Builder and installs a Btrfs root filesystem. The GHCR package must remain public so the installer can retrieve it.

## Local builds

`build-local.sh` uses the same BlueBuild inputs as CI. With no recipe specified it builds `redux.yml`; pass a recipe name/path to build another recipe, or `--all` to build every local recipe.

```bash
# Build Redux locally without publishing.
./build-local.sh --no-push

# Build a different recipe locally.
./build-local.sh --no-push blueox.yml

# Publish Redux to GHCR using a token that has package write access.
REGISTRY_TOKEN="$(gh auth token)" ./build-local.sh
```

The script installs BlueBuild if it is missing, using the official installer image. It writes complete bootstrap and build output to `.logs/build-local-*.log` while still printing it to the terminal. Set a fixed log path with `--log PATH` or `BUILD_LOG=PATH`. The default signing key is `~/.ssh/blueox-os/cosign.key`; override it with `--key` or `COSIGN_KEY_PATH`. Run `./build-local.sh --help` for all options.

## Recipes

| Recipe | Base image | Intended tag |
| --- | --- | --- |
| `redux.yml` | `ghcr.io/ublue-os/silverblue-main:44` | `latest`, `redux` |
| `blueox.yml` | `ghcr.io/ublue-os/bazzite-gnome:stable-43` | `gnome` |
| `plasma.yml` | `ghcr.io/ublue-os/bazzite:stable-43` | `plasma` |

Only Redux is currently published by the GitHub Actions workflow. The other recipes are available for explicit local builds.
