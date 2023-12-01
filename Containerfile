# These will be overridden by passed in values when built in the cloud
#
# quay.io/fedora-ostree-desktops/silverblue:39
# docker.io/library/ubuntu:22.04

ARG IMAGE_NAME="${IMAGE_NAME:-blueox-os}"
ARG BASE_IMAGE="${BASE_IMAGE:-quay.io/fedora-ostree-desktops/silverblue}"
ARG BASE_VERSION="${BASE_VERSION:-39}"

FROM ${BASE_IMAGE}:${BASE_VERSION} AS os-build

#Copy the setup folder onto the container
COPY os-config/ /tmp/os-config/

#Run the container setup
RUN /tmp/os-config/install.sh && \
  /tmp/os-config/post-install.sh && \
  rm -rfv /tmp/* /var/* && \
  ostree container commit && \
  mkdir -p /var/tmp && \
  chmod -R 1777 /var/tmp

#Third-Party Repositories
#https://copr.fedorainfracloud.org/coprs/ublue-os/gnome-software/repo/fedora-39/ublue-os-gnome-software-fedora-39.repo
#https://copr.fedorainfracloud.org/coprs/kylegospo/minecraft-server-hibernation/repo/fedora-39/kylegospo-minecraft-server-hibernation-fedora-39.repo
