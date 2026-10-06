# nRF Connect SDK Dev Container Template

## Intro

This is a template for an nRF Connect based development environment using a docker container for nearly all dependencies.
The container is built dynamically rather than using Nordic's prebuilt images, since those are x86 only. Doing so allows us to build at native speed without emulation.

A main goal was to use the same toolchain image locally and in CI builds and to have builds match given same git hash. The NCS toolchain is selectable in one place in the source tree. Additionally we follow Nordic's recommended workspace layout and use `west.yml`. This is not a pure cmake build environment.

## What's provided

### Capabilities

- **Zero local toolchain**: develop NCS apps on macOS (Apple Silicon or Intel) with only VS Code + Docker Desktop. The toolchain runs natively in a container (no emulation).
- **One-click dev environment**: Reopen in Container gives NCS v3.4.1 (or whatever is chosen), the Zephyr SDK and all tools. Extensions installed automatically: C/C++ IntelliSense, Nordic's build panel, Kconfig GUI and Devicetree editor, Cortex-Debug.
- **Same build everywhere**: VS Code, command line (`docker run … scripts/build.sh`) and CI use the same image and script.
- **Reproducible builds**: byte-identical firmware for the same commit on any Mac or in CI, across CPU architectures. Releases record everything needed to rebuild them byte-for-byte.
- **One-line configuration**: NCS/Zephyr version (`west.yml`), board (`board.env`), app version (`VERSION`).
- **Unit testing**: ztest on `native_sim`, from a VS Code task and in CI on every push.
- **Debugging without hardware**: run and debug the app as a program in the container (`native_sim`).
- **On-device debugging** via a J-Link on the Mac: breakpoints, stepping, Zephyr thread view, peripheral registers, memory views. Flashes as part of the debug session.
- **Optional RTT logging**: console and logs through the J-Link, for boards without a serial port.
- **CI on every push**: toolchain image (rebuilt only when it changes), firmware build, unit tests, artifacts named `<version>-<git hash>`.
- **Releases from tags**: `git tag vX.Y.Z` produces a GitHub Release with ELF/HEX, SHA-256s, NCS version, digest-pinned image and the rebuild command. Tag is checked against `VERSION`.
- **Versioning**: version and git hash compiled into the firmware and printed at boot.
- **Portable across boards**: switching boards is done in one line. The debug chip name and register file follow automatically.


### File map

- `west.yml`: NCS version (`revision:`, one line)
- `board.env`: board (`BOARD=`, one line)
- `VERSION`: app version
- `docker/`: the image; derives every tool version from Nordic's pin files; builds natively on Apple Silicon and x86
- `.devcontainer/`: VS Code dev container (C/C++, Nordic nRF Connect, Cortex-Debug)
- `.vscode/`: tasks (Build, Build native_sim, Test, RTT console, Clean) and debug configs (native_sim, device)
- `scripts/build.sh`: single build entry point; `scripts/jlink-gdb-server.sh`: run on the Mac for debugging
- `rtt.conf`, `debug.conf`: opt-in build options
- `.github/workflows/`: CI on every push; releases on `v*` tags
- `src/`, `tests/`: blinky plus one ztest

## Installation

- Prerequisites: VS Code, Xcode CLT, Docker Desktop, Dev Containers extension.
- **Do not** have Nordic's nRF Connect extensions installed locally, they will likely conflict.
- Install Docker *before* opening VS Code, or Cmd+Q and reopen VS Code afterwards.
- Clone (VS Code "Clone from GitHub" works for the private repo), then **Reopen in Container**. First time about 7–10 min and about 9 GB disk; later opens take seconds.
- For on-device debugging only: SEGGER J-Link Software Pack on the Mac.

## Usage

- **Build**: Cmd+Shift+B, or from the Mac terminal:
  - `docker build -f docker/Dockerfile -t ncs-app .`
  - `docker run --rm -v "$PWD":/workdir/app ncs-app scripts/build.sh`
  - Output: `build/app/zephyr/zephyr.{elf,hex}`.
- **Test**: Test task (Twister on `native_sim/native/64`).
- **Change board**: edit `BOARD=` in `board.env`; it rebuilds from scratch automatically.
- **Change NCS**: edit `revision:` in `west.yml`, then Rebuild Container. CI rebuilds the image automatically.
- **Debug, no hardware**: "Debug on native_sim".
- **Debug on hardware**: build once; on the Mac run `scripts/jlink-gdb-server.sh`; in VS Code run "Debug on device" (loads firmware, stops at `main()`, registers and memory views). Build with `debug.conf` to see Zephyr threads.
- **Logs over the J-Link**: build with `-- -DEXTRA_CONF_FILE=rtt.conf`, then the RTT console task.
- **Flash**:
  - "Debug on device" flashes as part of loading.
  - On the Mac with Nordic's tools: `nrfjprog --program build/app/zephyr/zephyr.hex --chiperase --verify --reset`. `nrfutil device program` is the newer equivalent **(unverified)**.
  - DK drag-and-drop onto its `JLINK` drive **(unverified)**.
  - Boards with bootloaders use their own tools (Adafruit `adafruit-nrfutil`, Arduino `bossac`); needs app placement settings in `boards/<board>_<soc>.conf` (board name with `/` replaced by `_`, see [workflow.md](workflow.md)).
- **Release**: bump `VERSION`, `git tag -a vX.Y.Z`, push the tag. Release notes include the image digest and rebuild command.
- **Rebuild a release**: the release notes' command pulls the pinned toolchain image from this repo's private GitHub Container Registry, so first run `docker login ghcr.io` with your GitHub username and a token that has `read:packages`.

For more detailed usage information see [workflow.md](workflow.md)

## What's not working / not included

- Flashing or debugging from *inside* the container: Docker Desktop on macOS has no USB passthrough, the Mac side does it via a local network port.
- Nordic's "nRF Debug" panel (Cortex-Debug used instead).
- CI builds only the amd64 image. Macs build their own arm64 copy though they build identical firmware.
- 32-bit `native_sim` (no multilib on arm64).
- No "latest release" keyword; `revision: main` gives NCS development head, not the latest release. You must choose a specific version to find something stable.

## Caveats and gotchas

- After Rebuild Container, Cortex-Debug may say "debug-tracker-vscode not loaded". Issue the command "Developer->Reload Window" once and this will go away for the life of the container.
- Nordic's extension prompts:
  - decline the `nordic-mcp` (aidev.nordicsemi.com) sign-in, then disable it via **MCP: List Servers**, sorry I couldn't find a way to shut this up.
  - dismiss the J-Link install, do that yourself outside the container first.
  - telemetry can only be switched off in user settings
  - Kconfig hover needs an active app selected in the nRF Connect panel
- Changing `west.yml` or `docker/` means **Rebuild Container** (VS Code doesn't notice by itself).
- `ninja: no work to do` is normal; `-p always` for a clean build.
- RTT shows stale text after a firmware change: power-cycle the board once.
- "Cannot connect to J-Link": a leftover J-Link process (e.g. `JLinkGUIServerExe`) is holding the probe, kill it.
- Git in the container uses the Mac's SSH agent; keys must be loaded there.

- Reproducibility:
  - The same commit gives byte-identical firmware anywhere.
  - release builds differ from branch builds only by the version string (`v0.1.0` vs hash)
  - keep GHCR images: rebuilding the Dockerfile years later depends on upstream downloads. I.e. if you don't keep CI docker images stored somewhere, it's possible the Dockerfile will refer to things that don't exist in the distant future.

## Sources

Directly used for this template:

- Memfault Interrupt: [Building Nordic nRF-Connect SDK Projects with GitHub Actions](https://interrupt.memfault.com/blog/ncs-github-actions) (custom ARM-only image, T2 workspace layout, shallow `west update`, version pinning)
- Nordic: [ncs-example-application](https://github.com/nrfconnect/ncs-example-application) (recommended workspace-application layout)
- Nordic's pinned tool versions, which the image reads: [tools-versions-linux.yml](https://github.com/nrfconnect/sdk-nrf/blob/v3.4.1/scripts/tools-versions-linux.yml), [requirements-fixed.txt](https://github.com/nrfconnect/sdk-nrf/blob/v3.4.1/scripts/requirements-fixed.txt)
- [Zephyr SDK releases](https://github.com/zephyrproject-rtos/sdk-ng/releases) (native aarch64 and x86_64 toolchains)
- Nordic DevZone: [nRF Connect for VS Code Extension Pack breaks Dev Containers](https://devzone.nordicsemi.com/f/nordic-q-a/115987/nrf-connect-for-vs-code-extension-pack-breaks-dev-containers-in-visual-studio-code) (why Nordic's extensions mustn't be installed locally)
- Zephyr docs: [Application development](https://docs.zephyrproject.org/latest/develop/application/index.html), [Sysbuild](https://docs.zephyrproject.org/latest/build/sysbuild/index.html)
- VS Code: [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers)
- [Cortex-Debug](https://github.com/Marus/cortex-debug); SEGGER: [J-Link GDB Server](https://wiki.segger.com/J-Link_GDB_Server), [thread-aware debugging](https://www.segger.com/products/debug-probes/j-link/tools/j-link-gdb-server/thread-aware-debugging/)

Background reading (Memfault Interrupt):

- [Reproducible Firmware Builds](https://interrupt.memfault.com/blog/reproducible-firmware-builds)
- Practical Zephyr series: [Zephyr Basics](https://interrupt.memfault.com/blog/practical_zephyr_basics), [Kconfig](https://interrupt.memfault.com/blog/practical_zephyr_kconfig), [Devicetree semantics](https://interrupt.memfault.com/blog/practical_zephyr_dt_semantics), [West workspaces](https://interrupt.memfault.com/blog/practical_zephyr_west)
- Debugging: [Debugging Firmware with GDB](https://interrupt.memfault.com/blog/gdb-for-firmware-1), [Advanced GDB Usage](https://interrupt.memfault.com/blog/advanced-gdb), [A Deep Dive into ARM Cortex-M Debug Interfaces](https://interrupt.memfault.com/blog/a-deep-dive-into-arm-cortex-m-debug-interfaces) (covers RTOS thread awareness)
