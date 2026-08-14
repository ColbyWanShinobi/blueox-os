# blueox-os &nbsp; [![bluebuild build badge](https://github.com/colbywanshinobi/blueox-os/actions/workflows/build.yml/badge.svg)](https://github.com/colbywanshinobi/blueox-os/actions/workflows/build.yml)

See the [BlueBuild docs](https://blue-build.org/how-to/setup/) for quick setup instructions for setting up your own repository based on this template.

After setup, it is recommended you update this README to describe your custom image.

## Local builds

`build-local.sh` mirrors the inputs used by `.github/workflows/build.yml` and, with no arguments, builds `redux.yml`. Name another recipe explicitly, or use `--all`, to build additional images. GitHub Actions pushes signed images by default, so the script does too; provide a registry token and the cosign key, or use `--no-push` for a local-only build.

```bash
# Build Redux locally without publishing it.
./build-local.sh --no-push

# Mirror the CI publish behavior (requires a token with GHCR package write access).
REGISTRY_TOKEN="$(gh auth token)" ./build-local.sh --recipe blueox.yml
```

The script writes all bootstrap and build output to a timestamped file under `.logs/` (which is ignored by Git) while continuing to show it in the terminal. Use `--log PATH` or `BUILD_LOG=PATH` to choose the file. It installs BlueBuild automatically if needed, using the same `v0.9` CLI installer series as the current GitHub action. It uses Docker when available (matching CI’s Buildx path), otherwise Podman. The installer writes to `/usr/local/bin` and may request `sudo`; use `--no-install-bluebuild` to forbid this. The default signing key is `~/.ssh/blueox-os/cosign.key`. Override it with `--key` or `COSIGN_KEY_PATH`; see `./build-local.sh --help` for all options.

## Unverified
```
rpm-ostree rebase ostree-unverified-registry:ghcr.io/colbywanshinobi/blueox-os:gnome
```

```
rpm-ostree rebase ostree-unverified-registry:ghcr.io/colbywanshinobi/blueox-os:gnome-nvidia
```

```
rpm-ostree rebase ostree-unverified-registry:ghcr.io/colbywanshinobi/blueox-os:kde
```

```
rpm-ostree rebase ostree-unverified-registry:ghcr.io/colbywanshinobi/blueox-os:kde-nvidia
```

## Verified
```
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/colbywanshinobi/blueox-os:gnome
```

```
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/colbywanshinobi/blueox-os:gnome-nvidia
```

```
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/colbywanshinobi/blueox-os:kde
```

```
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/colbywanshinobi/blueox-os:kde-nvidia
```

## Installation

> **Warning**
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/colbywanshinobi/blueox-os:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/colbywanshinobi/blueox-os:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/colbywanshinobi/blueox-os
```
## ublue Image Layer Order
config - udev rules
akmods - kernel mods
main-kernel - ???
main - shared by most images
