# Development Workflow

## 1. Start a project

- "Use this template" on GitHub, or `gh repo create my-app --template logicalelegance/ncs-devcontainer-template --private`.
- Clone, open in VS Code, **Reopen in Container** (first image build about 7–10 min).
- Rename `project(blinky)` in `CMakeLists.txt`, reset `VERSION` to 0.1.0, replace `src/` and `tests/`, edit `prj.conf`.

## 2. Configure

- Board: `BOARD=` in `board.env`.
- Board-specific settings: devicetree overlays and Kconfig in `boards/<board>_<soc>.overlay` / `boards/<board>_<soc>.conf`, i.e. the board name with `/` replaced by `_` (e.g. `boards/nrf52840dk_nrf52840.conf`, `boards/thingy52_nrf52832.overlay`). Zephyr picks them up automatically. Don't use the short board name (`boards/nrf52840dk.conf`): Zephyr rejects it for boards that cover several chips, like the nRF52840 DK.
- NCS version: `revision:` in `west.yml`, then Rebuild Container.
- Extra libraries/modules: in-repo folders, or extra `projects:` in `west.yml` (pinned revision; rebuild the container).
- Private dependencies (private repos) are not covered yet. `west update` runs while the Docker image is built, without access to your SSH keys, and CI would need its own credentials too. Options for later: pass credentials into the image build (Docker build secrets or SSH forwarding) plus a CI deploy key or token; or keep private code as git submodules of the app repo, which are cloned with the app on the Mac and in CI and never need to be inside the image.

## 3. Edit → build → test loop

- Edit, then **Build** (Cmd+Shift+B), look for errors in the Problems panel.
- IntelliSense works after the first build (`compile_commands.json`). Nordic's Kconfig hover needs the app selected in its panel.
- **Test** task: ztest suites in `tests/` run on `native_sim`. New suite: `tests/<name>/` with `CMakeLists.txt`, `prj.conf`, `testcase.yaml`, `src/`.
- Keep hardware-independent logic in separate files (like `blink.c`) so it can be unit tested.

## 4. Debug without hardware

- "Debug on native_sim": breakpoints and stepping in the container; peripherals simulated.

## 5. Run and debug on the board

1. Connect the J-Link or DK to the Mac.
2. On the Mac: `scripts/jlink-gdb-server.sh` (leave it running).
3. Optional, once: `scripts/build.sh -- -DEXTRA_CONF_FILE="debug.conf;rtt.conf"`. Later builds keep these until the board changes.
4. "Debug on device": builds, flashes, stops at `main()`; threads, registers, memory views.
5. Optional: **RTT console** task for logs.

- Flash without debugging: `nrfjprog --program build/app/zephyr/zephyr.hex --chiperase --verify --reset` on the Mac, or the board's own bootloader tool.

## 6. Commit and push

- Git works in the container (Source Control panel or terminal) through the Mac's SSH agent.
- Every push runs CI: image check, build, unit tests. Download artifacts `firmware-<version>-<hash>` and `test-results-…` from the run.
- PRs from branches in the repo show the same checks. Requiring them before merge needs GitHub Pro for private repos.

## 7. Release

1. Bump `VERSION`, commit, push.
2. `git tag -a vX.Y.Z -m "Release X.Y.Z"` then `git push origin vX.Y.Z`.
3. The release workflow checks tag vs `VERSION`, builds, and publishes the release: ELF/HEX, SHA-256s, NCS version, pinned image, rebuild command.

- The firmware reports `vX.Y.Z` (annotated tag) instead of a hash.

## 8. Reproduce an old build

- Check out the tag and run the `docker run … scripts/build.sh` line from that release's notes (uses the pinned image). Compare SHA-256s.

## 9. Maintenance

- **Upgrading NCS**: change `revision:`, Rebuild Container; CI builds a new image. Expect firmware hashes to change; re-test.
- If a new NCS needs another package that only exists on Nordic's PyPI mirror, the image build fails with a clear pip error: add it to `NORDIC_ONLY` in `docker/install-toolchain.sh`.
- **Moving to the real board**: change `BOARD=`, add `boards/<board>.*` overlays/conf as needed. CI, debugging and releases follow automatically.
- **Disk**: Docker Desktop accumulates old images; prune occasionally. Keep the GHCR images for releases.
