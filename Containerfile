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
RUN /tmp/os-config/pre-install.sh
RUN /tmp/os-config/install-rpmfusion.sh
RUN /tmp/os-config/install-system76-scheduler.sh
RUN /tmp/os-config/install-AMDCTL.sh
RUN /tmp/os-config/install-lact.sh
RUN /tmp/os-config/install-distrobox.sh
RUN /tmp/os-config/install-ghcli.sh
RUN /tmp/os-config/install-vscode.sh
RUN /tmp/os-config/install-apple-fonts.sh
RUN /tmp/os-config/install-packages.sh
RUN /tmp/os-config/post-install.sh

RUN rm -rfv /tmp/* /var/* && \
  ostree container commit && \
  mkdir -p /var/tmp && \
  chmod -R 1777 /var/tmp

#At some point, change this to a multistage build?
