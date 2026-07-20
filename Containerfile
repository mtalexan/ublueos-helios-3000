# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY / /

## The kernels, modules, and headers are installed in this akmods image under /kernel-rpms/.
## There is no latest bazzite image, or matching to bazzite*:stable.
## There's nothing else in this image except the RPMs.
#FROM ghcr.io/ublue-os/akmods:bazzite-42-x86_64 as kernel-rpms
#
## Match to the base image
#FROM ghcr.io/ublue-os/bazzite-dx-nvidia:stable as builder
#
## The kernel-devel RPM and all build tools are already installed in this image, so we don't need to
## find a way to get it from the akmods image(s).
#
### Copy the kernel-devel RPM from the akmods image folder, then install it along with the build tools
##COPY --from=kernel-rpms /kernel-rpms/kernel-devel*.rpm /
##RUN --mount=type=cache,dst=/var/cache \
##    --mount=type=cache,dst=/var/log \
##    --mount=type=tmpfs,dst=/tmp \
##    dnf install -y --setopt=install_weak_deps=False \
##        /kernel-devel-*.rpm \
##        make \
##        gcc
#
#RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
#    --mount=type=cache,dst=/var/cache \
#    --mount=type=cache,dst=/var/log \
#    --mount=type=tmpfs,dst=/tmp \
#    /ctx/build_files/acer-predator-driver.sh

# Base Image
FROM ghcr.io/ublue-os/aurora-dx:stable as prod
# :stable is updated weekly, :stable-daily is daily, :latest is bleeding edge unstable.
#FROM ghcr.io/ublue-os/aurora-dx:stable

# Must modify the Justfile to actually pass these.
# These must be present to be able to add the cosign.pub key as a signing key so subsequent updates can be signature-checked.
ARG GITHUB_USERNAME
ARG IMAGE_REGISTRY
ARG IMAGE_NAME

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:testing
# FROM ghcr.io/ublue-os/aurora:stable
# FROM ghcr.io/ublue-os/bluefin-nvidia-open:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:44
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/signing.sh "${GITHUB_USERNAME}" "${IMAGE_REGISTRY}" "${IMAGE_NAME}" && \
    /ctx/build_files/build.sh && \
    /ctx/build_files/cleanup.sh
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
