#!/usr/bin/env bash
# Build the firmware for the board in board.env. Runs inside the container; used by the
# VS Code Build task, CI and the command line. Extra arguments are passed to west build:
#   scripts/build.sh -- -DEXTRA_CONF_FILE="debug.conf;rtt.conf"
set -euo pipefail
cd "$(dirname "$0")/.."
source board.env

# -p auto starts from scratch only when needed, e.g. after changing BOARD.
west build -b "$BOARD" -d build -p auto . "$@"

# Register descriptions for "Debug on device": the SVD file for the chip this build is for.
SOC=$(sed -n 's/^CONFIG_SOC="\(.*\)"$/\1/p' build/app/zephyr/.config)
case "$SOC" in
    nrf52832) SVD=nrf52.svd ;;
    nrf5340)  SVD=nrf5340_application.svd ;;
    *)        SVD=$SOC.svd ;;
esac
ln -sf "/workdir/modules/hal/nordic/nrfx/bsp/stable/mdk/$SVD" build/board.svd
