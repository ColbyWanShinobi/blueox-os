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
# Build Redux locally. This is unsigned and does not publish by default.
./build-local.sh

# Build a different recipe locally.
./build-local.sh blueox.yml

# Publish and sign Redux using a token that has package write access.
REGISTRY_TOKEN="$(gh auth token)" ./build-local.sh --push --signed
```

The script installs BlueBuild if it is missing, using the official installer image. It writes complete bootstrap and build output to `.logs/build-local-*.log` while still printing it to the terminal. Set a fixed log path with `--log PATH` or `BUILD_LOG=PATH`. When using `--signed`, the default signing key is `~/.ssh/blueox-os/cosign.key`; override it with `--key` or `COSIGN_KEY_PATH`. `build.sh`, `build-redux.sh`, `redux.sh`, and `build-plasma.sh` route through this same local workflow. Run `./build-local.sh --help` for all options.

### Build and stage a local self-update

On an existing BlueOx install, use `self-update.sh` to build Redux from this
checkout, push and sign it with the configured Cosign key, and stage that
signed `:redux` image for the next boot. `rpm-ostree` verifies the signature
against the system container policy while staging:

```bash
REGISTRY_TOKEN="$(gh auth token)" ./self-update.sh
# or stage and reboot immediately
REGISTRY_TOKEN="$(gh auth token)" ./self-update.sh --reboot
```

The image is built locally, but it must be pushed to a registry: Cosign image
signatures are stored alongside the registry image, and `ostree-image-signed`
verifies them through the system container policy. To stage an image already
built and signed with the same key, use `./self-update.sh --no-build --image
ghcr.io/colbywanshinobi/blueox-os:redux`.

### Preview a local update

On an existing BlueOx install, use `blueox-preview` to build Redux, push the
signed candidate image, and print the RPM changes compared with the current
system without staging a deployment:

```bash
REGISTRY_TOKEN="$(gh auth token)" ./blueox-preview
```

It uses `rpm-ostree rebase --download-only`, so image data may be downloaded
into the local OSTree cache but the running and next-boot deployments are left
unchanged. To preview an already-published image instead, use
`./blueox-preview --no-build --image IMAGE_REFERENCE`. Flatpak updates are
separate from the OS image; check or apply them with `flatpak update --system`.

### Root scripts

The root scripts are grouped by purpose:

| Script | Purpose |
| --- | --- |
| `./build-local.sh` | Main local BlueBuild entrypoint. Builds `recipes/redux.yml` by default, accepts other recipe names or paths, can build `--all`, optionally pushes to a registry, optionally signs with cosign, logs to `.logs/`, and installs BlueBuild if missing. |
| `./self-update.sh` | Builds Redux locally, pushes the signed `:redux` image, then stages it as the next deployment after signature verification. |
| `./blueox-preview` | Builds Redux locally, pushes the signed `:redux` image, then prints the RPM diff without staging a deployment. |
| `./build-redux.sh` | Convenience wrapper for `./build-local.sh --no-push --unsigned redux.yml`. |
| `./redux.sh` | Duplicate convenience wrapper for `./build-local.sh --no-push --unsigned redux.yml`. |
| `./build.sh` | Convenience wrapper for `./build-local.sh --no-push --unsigned blueox.yml`. This builds the older/non-default `blueox.yml` recipe, not the current Redux release image. |
| `./build-plasma.sh` | Convenience wrapper for `./build-local.sh --no-push --unsigned plasma.yml`. |
| `./build-github-iso.sh` | Builds an installer ISO from an already-published GHCR image, defaulting to `ghcr.io/<GitHub-owner>/blueox-os:redux`. This mirrors the GitHub Actions ISO workflow. |
| `./build-local-iso.sh` | Builds a local recipe into an OCI archive, then turns that exact local archive into an installer ISO without pushing anything. |
| `./validate.sh` | Installs BlueBuild if needed, then validates `recipes/redux.yml`. |
| `./create-vm.sh` | Creates or starts a local QEMU VM, optionally booting an installer ISO. VM files live under `.linux-vm/`. |
| `./destroy-vm.sh` | Stops and removes a QEMU VM created by `./create-vm.sh`. The shared `~/VMShare` directory is preserved. |

The image also includes `galahad2lcd`, built from the archived Galahad II LCD
project. Install an FFmpeg build with `ffmpeg` and `ffprobe` (including the
`libx264` encoder), then configure and enable the service with:

```bash
sudo galahad2lcd set-args --input /path/to/video-or-gif -r 0
sudo systemctl enable galahad2lcd.service
```

For normal image work, use `./build-local.sh`. For installer media, use `./build-local-iso.sh` when testing a local recipe and `./build-github-iso.sh` when building from the published image. Use `./create-vm.sh` and `./destroy-vm.sh` only for local VM testing.

### Local installer ISOs

There are two ISO scripts, depending on the image source:

- `./build-github-iso.sh` mirrors the GitHub ISO workflow. It uses rootful Podman to produce a Btrfs Anaconda ISO from the published `ghcr.io/<GitHub-owner>/blueox-os:redux` image. Use `--tag latest` or `--image IMAGE_REFERENCE` to choose another published image. Output goes to `output/iso-<tag>-<timestamp>/` and logs to `.logs/build-github-iso-*.log`. It uses host networking by default to avoid local Podman DNS/CNI problems; override that with `--network MODE` or `BIB_NETWORK=MODE`.
- `./build-local-iso.sh` builds `recipes/redux.yml` locally as an OCI archive, then passes that exact archive to a rootful Podman installer container. It does not push an image and installs BlueBuild automatically if needed. Rootful Podman is necessary because Lorax mounts `devtmpfs` while creating boot media. The script requests sudo once at startup and refreshes that credential while it runs, so the later installer stage will not time out during an unattended build. This explicit two-stage flow also works around BlueBuild 0.9.37’s local ISO archive filename mismatch. Pass another recipe, `--variant`, or `--output-dir` as needed. Output goes to `output/local-iso-<timestamp>/` and logs to `.logs/build-local-iso-*.log`.

Both scripts write `SHA256SUMS` beside their ISO output. Run either script with `--help` for its full options.

## Recipes

| Recipe | Base image | Intended tag |
| --- | --- | --- |
| `redux.yml` | `ghcr.io/ublue-os/silverblue-main:44` | `latest`, `redux` |
| `blueox.yml` | `ghcr.io/ublue-os/bazzite-gnome:stable-43` | `gnome` |
| `plasma.yml` | `ghcr.io/ublue-os/bazzite:stable-43` | `plasma` |

Only Redux is currently published by the GitHub Actions workflow. The other recipes are available for explicit local builds.
