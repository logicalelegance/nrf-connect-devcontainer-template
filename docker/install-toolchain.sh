#!/usr/bin/env bash
# Install the nRF Connect SDK toolchain at the exact versions Nordic pins for the
# NCS revision in west.yml. Nothing here is versioned by hand:
#
#   Zephyr SDK, CMake, Ninja  <- sdk-nrf/scripts/tools-versions-linux.yml
#   Python packages (+ west)  <- sdk-nrf/scripts/requirements-fixed.txt
#
# Works on x86_64 and aarch64 Linux. Runs as root during the image build.
# Usage: install-toolchain.sh <path/to/west.yml>
set -euo pipefail

WEST_YML=$1
ARCH=$(uname -m) # x86_64 or aarch64

# The one line that selects everything: the sdk-nrf revision in west.yml.
NCS_REVISION=$(python3 -c '
import sys, yaml
projects = yaml.safe_load(open(sys.argv[1]))["manifest"]["projects"]
print(next(p["revision"] for p in projects if p["name"] == "nrf"))
' "$WEST_YML")
echo "Installing toolchain for NCS ${NCS_REVISION} on ${ARCH}"

WORK_DIR=$(mktemp -d)
cd "$WORK_DIR"
PINS=https://raw.githubusercontent.com/nrfconnect/sdk-nrf/${NCS_REVISION}/scripts
curl -fsSLO "${PINS}/tools-versions-linux.yml"
curl -fsSLO "${PINS}/requirements-fixed.txt"

version_of() { # version_of <tool>: the version Nordic pins for <tool>
    python3 -c 'import sys, yaml; print(yaml.safe_load(open("tools-versions-linux.yml"))[sys.argv[1]]["version"])' "$1"
}
CMAKE_VERSION=$(version_of cmake)
NINJA_VERSION=$(version_of ninja)
ZEPHYR_SDK_VERSION=$(version_of zephyr-sdk)
echo "cmake ${CMAKE_VERSION}, ninja ${NINJA_VERSION}, zephyr-sdk ${ZEPHYR_SDK_VERSION}"

# CMake (upstream release, checksum verified).
CMAKE_TGZ=cmake-${CMAKE_VERSION}-linux-${ARCH}.tar.gz
CMAKE_URL=https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}
curl -fsSLO "${CMAKE_URL}/${CMAKE_TGZ}"
curl -fsSL "${CMAKE_URL}/cmake-${CMAKE_VERSION}-SHA-256.txt" | grep " ${CMAKE_TGZ}\$" | sha256sum -c -
mkdir -p /opt/cmake
tar -xzf "${CMAKE_TGZ}" -C /opt/cmake --strip-components=1
ln -s /opt/cmake/bin/* /usr/local/bin/

# Ninja (upstream release; the x86_64 asset has no arch suffix).
if [ "$ARCH" = aarch64 ]; then NINJA_ZIP=ninja-linux-aarch64.zip; else NINJA_ZIP=ninja-linux.zip; fi
curl -fsSLO "https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/${NINJA_ZIP}"
unzip -q "${NINJA_ZIP}" -d /usr/local/bin

# Zephyr SDK: only the ARM toolchain (nRF52/53/54 are Cortex-M) plus host tools.
SDK_TAR=zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-${ARCH}_minimal.tar.xz
SDK_URL=https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}
curl -fsSLO "${SDK_URL}/${SDK_TAR}"
curl -fsSL "${SDK_URL}/sha256.sum" | grep "${SDK_TAR}\$" | sha256sum -c -
mkdir -p /opt/zephyr-sdk
tar -xf "${SDK_TAR}" -C /opt/zephyr-sdk --strip-components=1
/opt/zephyr-sdk/setup.sh -t arm-zephyr-eabi -h

# Python packages, including west, at the exact versions in Nordic's pinned requirements file.
# The file points pip at Nordic's PyPI mirror, which lacks aarch64 Linux wheels, so:
#   1. the packages Nordic publishes only on its mirror are installed from there first;
#   2. everything else comes from public PyPI (step 1's packages are already satisfied).
NORDIC_PYPI=https://files.nordicsemi.com/artifactory/api/pypi/nordic-pypi/simple
NORDIC_ONLY='^(matter-idl|x690)=='
grep -v '^--index-url' requirements-fixed.txt > requirements.txt
grep -E "$NORDIC_ONLY" requirements.txt > requirements-nordic-only.txt
python3 -m venv /opt/venv
/opt/venv/bin/pip install --no-cache-dir --no-deps --index-url "$NORDIC_PYPI" -r requirements-nordic-only.txt
/opt/venv/bin/pip install --no-cache-dir --index-url https://pypi.org/simple -r requirements.txt

cd / && rm -rf "$WORK_DIR"
