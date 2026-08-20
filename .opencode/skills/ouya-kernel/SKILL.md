---
name: ouya-kernel
description: Build, configure, and debug the custom mainline Linux kernel for the OUYA console (Tegra30/ARMv7). Use when working on kernel config fragments, DTS changes, dockcross builds, boot image creation, or USB/hardware debugging specific to this project.
---

# OUYA Kernel Build & Debug

## Build pipeline

1. `make submodule-all` — init linux + mkbootimg submodules
2. `make dockcross-build` — build cross-compile Docker image (one-time)
3. `make config` — generate base `.config` from `tegra_defconfig`
4. `make config_patch` — merge all fragments in `linux-config/fragment/`
5. `make kernel` — build zImage + modules + dtbs
6. `make kernel_dtb` — append DTB to zImage
7. `make kernel_bootimg` — wrap into Android bootimg (required — OUYA bootloader needs this format even for `fastboot boot`)

## Fragment discipline

Each fragment in `linux-config/fragment/` is scoped to one concern (wireless, bluetooth, docker, usb_gadget, security, ouya-specific). Before adding a kconfig option, grep all fragments first — duplicated/conflicting options across fragments cause silent merge_config.sh override bugs that are hard to spot.

## Known issue: USB host instability on mainline ≥6.6

External USB host port reset-loops, preventing root filesystem mount from USB. `tegra30-ouya.dts` inherits USB PHY parameters (`nvidia,xcvr-setup`, `nvidia,hsdiscon-level`, etc.) from `tegra30.dtsi` via DTS overlay merge — they are NOT absent. The instability may be caused by incorrect VALUES for these parameters compared to the decatf/postmarketOS fork, which uses different trim values. Compare values against https://github.com/decatf/linux DTS and override in `tegra30-ouya.dts` if they differ.

## Debugging boot failures

- No serial console available — debug via HDMI framebuffer log only (photograph the screen).
- `fastboot boot zImage` loads into RAM, no flash — safe to iterate without bricking the device.
- `scripts/ouya_load_boot.sh [zImage-path]` — reboots OUYA to bootloader via adb then fastboot-boots.
- If root mount fails: check `Waiting for root device` timing vs USB enumeration — `rootdelay=` in cmdline (`ouya.fragment`) may help but does not fix PHY-level reset loops.

## When changing kernel LTS version

Use `bash scripts/lts-update.sh`, not manual submodule commands — it checks EOL dates via endoflife.date API and updates `.gitmodules` branch tracking automatically.
