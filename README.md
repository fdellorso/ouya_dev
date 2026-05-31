# ouya_dev

Custom Linux kernel build system for the [OUYA](https://en.wikipedia.org/wiki/Ouya) game console (Tegra30 / ARMv7).

The OUYA runs a stock Android kernel. This project replaces it with a mainline Linux kernel (currently tracking the **6.12.x LTS** series), enabling Arch Linux ARM with Docker support, proper iptables/nftables, thermal management, wireless, Bluetooth, and USB gadget ethernet.

## Hardware

| Component | Detail |
|-----------|--------|
| SoC | NVIDIA Tegra30 (ARMv7) |
| RAM | 1 GB |
| Storage | Internal eMMC + USB HDD (root) |
| WiFi | Broadcom BCM4330 (brcmfmac SDIO) |
| Bluetooth | Broadcom BCM4330 (HCI UART) |
| Audio | Wolfson WM8903 |

## Requirements

- Docker (for cross-compilation via dockcross)
- `adb` and `fastboot` (from `android-tools`)
- `rsync` (for deploying modules)
- `arm-linux-gnueabihf-` toolchain (provided by dockcross image)

## Repository structure

```
ouya_dev/
├── linux/                      # submodule — linux-stable v6.12.x LTS
├── mkbootimg/                  # submodule — osm0sis/mkbootimg (C implementation)
├── dockcross/                  # cross-compilation toolchain (see dockcross/README.md)
├── linux-config/
│   ├── fragment/               # kconfig fragments merged into final .config
│   │   ├── ouya.fragment       # OUYA/Tegra30: DTB append, cmdline, fan, thermal
│   │   ├── docker.fragment     # Docker runtime requirements
│   │   ├── iptables_qos.fragment  # full iptables + nftables + QoS
│   │   ├── wireless.fragment   # BCM4330 WiFi (brcmfmac SDIO)
│   │   ├── bluetooth.fragment  # BCM4330 Bluetooth (HCI UART)
│   │   ├── usb_gadget.fragment # USB gadget ethernet (RNDIS via configfs)
│   │   ├── security.fragment   # LSM stack (AppArmor, SELinux, yama)
│   │   ├── notuner.fragment    # disable unused DVB/tuner drivers
│   │   └── usbserial.fragment  # USB serial adapters (CH341, CP210x)
│   ├── check-config.sh         # validates .config against Docker requirements
│   └── .config-ouya-patch      # full reference config from ouya-patch community
├── patches/                    # kernel patches applied before build (git apply)
├── scripts/
│   ├── ouya_load_boot.sh       # flash kernel to OUYA via adb/fastboot
│   └── lts-update.sh           # interactive LTS kernel version bump
├── docs/
│   └── BUILD_NOTES.md          # historical build notes and commands
├── reference/
│   ├── ouya-patch/             # community reference configs (pgwipeout)
│   ├── linux-config-history/   # archived .config files and hardening fragment
│   ├── postmarketos/           # postmarketOS device files (reference)
│   ├── old_image/              # archived zImage binaries
│   └── html/                   # archived OUYA web dashboard
├── Makefile                    # main build system
└── zImage                      # last successfully built and tested kernel image
```

## Build workflow

### 1. First time setup

Build the dockcross image and compile mkbootimg:

```bash
# build cross-compilation Docker image
make dockcross-build

# compile mkbootimg
make mkbootimg_bin

# initialize submodules (if not already done)
make submodule-all
```

### 2. Configure kernel

Generate base config from Tegra defconfig, then apply all fragments:

```bash
make config          # tegra_defconfig → linux-build/.config
make config_patch    # merge all fragments into .config
make menuconfig      # optional: interactive review
```

### 3. Build kernel

```bash
make kernel          # builds zImage, modules, dtbs
make kernel_dtb      # appends tegra30-ouya.dtb to zImage-X.XX.XX
make kernel_bootimg  # wraps into Android boot image format → zImage
```

### 4. Deploy

Flash via fastboot (OUYA must be in fastboot mode):

```bash
bash scripts/ouya_load_boot.sh   # reboots to bootloader and fastboot boots zImage
```

Deploy kernel modules to the running system:

```bash
make copy_lib        # rsync modules to root@alarm.local:/lib/modules
```

### Useful targets

| Target | Description |
|--------|-------------|
| `make config` | Generate .config from tegra_defconfig |
| `make config_patch` | Merge all fragments into .config |
| `make menuconfig` | Interactive kernel configuration |
| `make kernel` | Full kernel build (zImage + modules + dtbs) |
| `make kernel_dtb` | Append DTB to zImage |
| `make kernel_bootimg` | Wrap into Android boot image |
| `make copy_kernel DEPLOY_HOST=user@host:/path` | Deploy zImage via rsync |
| `make copy_lib` | Deploy modules via rsync to root@alarm.local |
| `make clean` | Clean build artifacts |
| `make clean_kernel` | Remove all build directories and zImage |
| `make reset_kernel` | Hard reset linux submodule |
| `make mkbootimg_bin` | Compile mkbootimg from submodule |
| `make submodule-linux` | Init/update linux submodule |
| `make submodule-mkbootimg` | Init/update mkbootimg submodule |
| `make submodule-all` | Init/update all submodules |
| `make dockcross-build` | Build cross-compilation Docker image |
| `make dockcross-rebuild` | Pull base image and rebuild |

## Kernel configuration

The final `.config` is built by merging fragments in this order:

1. `tegra_defconfig` (base — includes Tegra30 drivers, cpuidle, thermal, audio)
2. `docker.fragment` (cgroups v1/v2, namespaces, overlay, netfilter, memcg)
3. `iptables_qos.fragment` (full iptables/nftables/QoS stack)
4. `notuner.fragment` (disable unused DVB/media tuners)
5. `ouya.fragment` (DTB append, cmdline force, GPIO fan, thermal bang_bang)
6. `usbserial.fragment` (CH341, CP210x)
7. `wireless.fragment` (brcmfmac SDIO — BCM4330)
8. `bluetooth.fragment` (BT HCI UART BCM — BCM4330)
9. `usb_gadget.fragment` (RNDIS ethernet via configfs)
10. `security.fragment` (LSM: landlock, lockdown, yama, safesetid, apparmor, selinux, bpf)

To validate Docker compatibility after configuration:

```bash
bash linux-config/check-config.sh linux-build/.config
```

## Firmware

The BCM4330 WiFi and Bluetooth require proprietary firmware files that are **not included** in the kernel and must be installed on the root filesystem of the OUYA.

### WiFi (brcmfmac)

Place the following files on the OUYA at `/lib/firmware/brcm/`:

| File | Description |
|------|-------------|
| `brcmfmac4330-sdio.bin` | BCM4330 firmware binary |
| `brcmfmac4330-sdio.txt` | BCM4330 NVRAM configuration |

Source: [milaq/android_vendor_boxer8_ouya](https://github.com/milaq/android_vendor_boxer8_ouya) and [milaq/android_device_boxer8_ouya](https://github.com/milaq/android_device_boxer8_ouya) (see `reference/postmarketos/APKBUILD` for exact commits).

### Bluetooth

The BCM4330 Bluetooth firmware is loaded automatically via `btbcm` kernel module from `/lib/firmware/brcm/`. The exact firmware file depends on the kernel version — check `dmesg` after boot for the filename requested.

## Boot process

The OUYA bootloader (Tegra CBoot) does not boot a raw zImage. The kernel must be wrapped in an Android boot image format (no ramdisk). The boot image is loaded temporarily into RAM via `fastboot boot` — there is no permanent boot partition written.

The kernel cmdline is hardcoded in `ouya.fragment` (`CONFIG_CMDLINE_FORCE=y`) and includes the device serial number, GPT sector, root device (`/dev/sda1`), and framebuffer parameters. Update `CONFIG_CMDLINE` in `ouya.fragment` if your device serial number or root partition differs.

Boot image offsets (Tegra30, defined in Makefile):

| Parameter | Value |
|-----------|-------|
| base | `0x10000000` |
| kernel_offset | `0x00008000` |
| ramdisk_offset | `0x01000000` |
| tags_offset | `0x00000100` |
| pagesize | `2048` |

## LTS kernel updates

Use the interactive update script to bump to the next LTS version:

```bash
bash scripts/lts-update.sh
```

The script checks available LTS tags, shows a summary, asks for confirmation, updates the submodule, and creates a commit.

To update manually:

```bash
cd linux
git fetch --depth 1 origin tag vX.XX.XX
git checkout vX.XX.XX
cd ..
git add linux
git commit -m "linux: update to vX.XX.XX LTS"
```

## References

- [pgwipeout's OUYA kernel work](https://github.com/pgwipeout/ouya-kernel) — original Tegra30 config reference
- [postmarketOS OUYA device](https://github.com/postmarketOS/pmaports) — device files and firmware sources
- [linux-stable](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git)
- [osm0sis/mkbootimg](https://github.com/osm0sis/mkbootimg)
- [dockcross](https://github.com/dockcross/dockcross)
