# Multi-arch (linux/amd64 + linux/arm64) build environment for nRF Connect SDK.
#
# Nordic's own toolchain image is amd64-only and no aarch64-linux NCS toolchain
# bundle exists, so this image assembles the same pinned pieces natively:
# Zephyr SDK (ARM toolchain + host tools) + west/cmake/ninja from PyPI.
# The same image is used by the devcontainer and by CI.

# Pinned by digest for reproducibility (ubuntu:24.04 multi-arch index).
ARG UBUNTU_IMAGE=ubuntu:24.04@sha256:a853f94d226358a79c740cfc7bce0c289748f3fe3488d921d038ccd752c61b60
FROM ${UBUNTU_IMAGE}

# Zephyr SDK version. Must match what the chosen NCS release pins
# (NCS v3.4.1 -> zephyr-sdk 1.0.1, see sdk-nrf/scripts/tools-versions-linux.yml).
ARG ZEPHYR_SDK_VERSION=1.0.1
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates ccache curl device-tree-compiler dfu-util file git gperf \
        gdb-multiarch libmagic1 make openssh-client python3 python3-dev python3-pip python3-venv \
        sudo udev unzip wget xz-utils \
    && if [ "$TARGETARCH" = "amd64" ]; then apt-get install -y --no-install-recommends gcc-multilib g++-multilib; fi \
    && rm -rf /var/lib/apt/lists/*

# Pinned Python tooling (west, cmake, ninja) in a venv (before the SDK: its setup needs cmake) that stays writable so the
# SDK-specific Python requirements can be installed by scripts/bootstrap.sh.
COPY tool-requirements.txt /tmp/tool-requirements.txt
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir -r /tmp/tool-requirements.txt \
    && rm /tmp/tool-requirements.txt
ENV VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH

# Zephyr SDK: minimal archive + only the ARM toolchain + host tools (openocd, etc.).
RUN case "$TARGETARCH" in \
        amd64) SDK_ARCH=x86_64 ;; \
        arm64) SDK_ARCH=aarch64 ;; \
        *) echo "unsupported TARGETARCH=$TARGETARCH" >&2; exit 1 ;; \
    esac \
    && BASE=https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION} \
    && cd /tmp \
    && curl -fsSLO ${BASE}/sha256.sum \
    && curl -fsSLO ${BASE}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-${SDK_ARCH}_minimal.tar.xz \
    && grep " \*\?zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-${SDK_ARCH}_minimal.tar.xz\$" sha256.sum | sha256sum -c - \
    && mkdir -p /opt/zephyr-sdk \
    && tar -xf zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-${SDK_ARCH}_minimal.tar.xz -C /opt/zephyr-sdk --strip-components=1 \
    && /opt/zephyr-sdk/setup.sh -t arm-zephyr-eabi -h \
    && rm -rf /tmp/*

# Non-root user; uid/gid 1000 is the devcontainer default and avoids root-owned files.
RUN (userdel -r ubuntu 2>/dev/null || true) \
    && groupadd -g 1000 dev && useradd -m -u 1000 -g 1000 -s /bin/bash dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev \
    && mkdir -p /workdir && chown dev:dev /workdir /opt/venv

ENV ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk \
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    WEST_WORKSPACE=/workdir

USER dev
WORKDIR /workdir/app
