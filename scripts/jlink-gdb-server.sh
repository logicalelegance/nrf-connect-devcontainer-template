#!/usr/bin/env bash
# Run this on the Mac, not in the container. It starts SEGGER's J-Link GDB server, which owns
# the USB connection to the probe; "Debug on device" in the container connects to it.
# Needs SEGGER's J-Link Software Pack installed on the Mac.
#
# Usage: scripts/jlink-gdb-server.sh [J-Link device name]
#   scripts/jlink-gdb-server.sh                  # chip of the last build (build/app/zephyr/runners.yaml)
#   scripts/jlink-gdb-server.sh nRF52832_xxAA    # or name it explicitly
set -euo pipefail

# Zephyr writes each board's J-Link device name into the build's runners.yaml.
RUNNERS="$(dirname "$0")/../build/app/zephyr/runners.yaml"
DEVICE=${1:-$(grep -o -- "--device=[^ ,'\"]*" "$RUNNERS" 2>/dev/null | head -1 | cut -d= -f2 || true)}
if [ -z "$DEVICE" ]; then
    echo "No J-Link device name: build the firmware first, or pass one (e.g. nRF52840_xxAA)." >&2
    exit 1
fi

# Port 2331: GDB. Port 19021: RTT output (see rtt.conf). Only reachable from this Mac.
# The Zephyr RTOS plugin shows each Zephyr thread in the debugger (firmware built with debug.conf).
exec JLinkGDBServerCL -device "$DEVICE" -if SWD -speed 4000 -port 2331 -LocalhostOnly 1 -nogui \
    -rtos GDBServer/RTOSPlugin_Zephyr
