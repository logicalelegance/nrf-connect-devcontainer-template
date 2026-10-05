#!/usr/bin/env bash
# Run this on the Mac, not in the container. It starts SEGGER's J-Link GDB server, which owns
# the USB connection to the probe; "Debug on device" in the container connects to it.
# Needs SEGGER's J-Link Software Pack installed on the Mac.
#
# Usage: scripts/jlink-gdb-server.sh [J-Link device name]
#   scripts/jlink-gdb-server.sh                  # nRF52840 DK (default)
#   scripts/jlink-gdb-server.sh nRF52832_xxAA    # nRF52832 boards, e.g. Thingy:52
set -euo pipefail

DEVICE=${1:-nRF52840_xxAA}

# Port 2331: GDB. Port 19021: RTT output (see rtt.conf). Only reachable from this Mac.
exec JLinkGDBServerCL -device "$DEVICE" -if SWD -speed 4000 -port 2331 -LocalhostOnly 1 -nogui
