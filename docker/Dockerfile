# Build environment for this app: nRF Connect SDK toolchain + SDK sources.
# Builds natively for linux/arm64 (Apple Silicon) and linux/amd64 (CI).
# Used unchanged by the devcontainer, the command line, and GitHub Actions.
#
# Every version comes from the NCS revision in west.yml. To change NCS, edit that one
# line and rebuild this image. Build from the repo root:
#   docker build -f docker/Dockerfile -t ncs-app .

# Base image pinned by digest so rebuilds start from the same OS.
FROM ubuntu:24.04@sha256:a853f94d226358a79c740cfc7bce0c289748f3fe3488d921d038ccd752c61b60

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates ccache curl device-tree-compiler dfu-util file \
        gdb-multiarch git gperf libmagic1 openssh-client python3 python3-dev python3-venv python3-yaml \
        sudo unzip wget xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Toolchain (Zephyr SDK, CMake, Ninja, Python packages) at Nordic's pinned versions.
COPY docker/install-toolchain.sh west.yml /tmp/
RUN /tmp/install-toolchain.sh /tmp/west.yml && rm /tmp/install-toolchain.sh /tmp/west.yml
ENV PATH=/opt/venv/bin:$PATH \
    ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk \
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr

# Non-root user. uid 1000 matches the devcontainer default; replaces Ubuntu's default user.
RUN userdel -r ubuntu \
    && useradd -m -u 1000 -s /bin/bash dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
    && install -d -o dev -g dev /workdir

# NCS workspace (sdk-nrf, Zephyr, modules) at the revision in west.yml.
# This repo is mounted over /workdir/app at run time.
USER dev
COPY --chown=dev:dev west.yml /workdir/app/west.yml
RUN cd /workdir && west init -l app && west update --narrow -o=--depth=1
WORKDIR /workdir/app
