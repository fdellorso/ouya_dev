# ouya_dev — Agent Instructions

## Project

Custom mainline Linux kernel for the OUYA console (Tegra30/ARMv7), built via dockcross cross-compilation. Currently tracking kernel v6.12.x LTS (submodule pinned at v6.12.104). An earlier v6.12 attempt had been reverted due to a USB host instability regression; the regression is now fixed via the patches in `patches/` — see `docs/USB_HOST_FIX.md` for the fix and `docs/AUDIT_REPORT_V2.md` for the audit history.

## Critical context

- This is a hobby/homelab embedded kernel project — correctness on real hardware matters more than code elegance.
- `linux/` and `mkbootimg/` are git submodules. Never `git add` inside them without checking out a specific tag first.
- The OUYA bootloader (Tegra CBoot) requires an Android bootimg wrapper (no ramdisk in our case) — see `make kernel_bootimg`.
- `CONFIG_CMDLINE_FORCE=y` is intentional — cmdline is hardcoded in `ouya.fragment`, not from bootloader.
- USB host (`ci_hdrc`) reset-loop on kernel ≥6.6.2: **resolved** by `patches/0001-*.patch` + `patches/0002-*.patch`, applied via `make apply_patches` (the `linux/` submodule is *expected* to look dirty while the patches are applied — don't "fix" it). Root cause is commit `38a41a0c0272` ("usb: chipidea: Fix DMA overwrite for Tegra"), a DMA bounce-buffer change in `drivers/usb/chipidea/host.c` that Tegra30 EHCI mishandles — **not** missing DTS PHY trim parameters (that theory is disproven in `docs/AUDIT_REPORT_V2.md`, §Correzioni 2). Verified on v6.6.2 and v6.12.104. For v7.x a different partial revert of `host.c` will be needed.

## Session continuity

Before starting work, check the `handoff/` directory and read the 2 most recent files (sorted by filename — they are timestamped `YYYYMMDD_HHMMSS.md`, so the highest filenames are the latest). These contain the state, open issues, and next steps from the last sessions. Treat them as more current than older context in this file if there's a conflict — AGENTS.md is updated less frequently than handoffs.

## Workflow rules

- Never modify a kconfig fragment without checking `linux-config/fragment/*.fragment` for an existing equivalent option first — duplication across fragments causes silent override bugs.
- Always run `make config && make config_patch` after changing any fragment, and check `bash linux-config/check-config.sh linux-build/.config` before building.
- DTS changes go in `linux/arch/arm/boot/dts/nvidia/tegra30-ouya.dts` (submodule) — flag clearly when a change needs to be carried as a patch in `patches/` since the submodule resets on every `git fetch`/`checkout`.
- Never run `make clean_kernel` without confirming — it deletes the build dir and zImage.
- Submodule version bumps must use `scripts/lts-update.sh`, not manual checkout, unless explicitly told otherwise.

## Commit conventions

- Italian or English commit messages both fine, but be consistent within a single logical change.
- Prefix with the area: `kernel:`, `fragment:`, `dts:`, `makefile:`, `docs:`, `scripts:`.
- Never commit generated artifacts: `zImage`, `zImage-*`, `build.log`, `linux-build/`, `.config` working files — check `.gitignore` is respected.

## Boundaries

- Don't touch `reference/` — it's intentionally archived material (community configs, old images, postmarketOS files) kept for comparison, not for editing.
- Don't add new top-level directories without checking README.md's documented structure first.
