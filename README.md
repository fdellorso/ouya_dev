# ouya_dev

Custom Linux kernel build system for the [OUYA](https://en.wikipedia.org/wiki/Ouya) game console (Tegra30 / ARMv7).

The OUYA runs a stock Android kernel. This project replaces it with a mainline Linux kernel (currently tracking the **6.12.x LTS** series), enabling Arch Linux ARM with Docker support, proper iptables/nftables, thermal management, and USB serial.

## Hardware

| Component | Detail |
|-----------|--------|
| SoC | NVIDIA Tegra30 (ARMv7) |
| RAM | 1 GB |
| Storage | Internal eMMC + USB HDD (root) |
| WiFi | Broadcom BCM4330 (brcmfmac) |
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
│   │   ├── ouya.fragment       # OUYA/Tegra30 specific options
│   │   ├── docker.fragment     # Docker runtime requirements
│   │   ├── iptables_qos.fragment  # full iptables + nftables + QoS
│   │   ├── hardening.fragment  # kernel hardening options
│   │   ├── notuner.fragment    # disable unused DVB/tuner drivers
│   │   └── usbserial.fragment  # USB serial adapters (CH341, CP210x)
│   ├── check-config.sh         # validates .config against Docker requirements
│   └── .config-ouya-patch      # full reference config from ouya-patch community
├── patches/                    # kernel patches applied before build (git apply)
├── scripts/
│   └── ouya_load_boot.sh       # flash kernel to OUYA via adb/fastboot
├── docs/
│   └── BUILD_NOTES.md          # historical build notes and commands
├── reference/
│   ├── ouya-patch/             # community reference configs (pgwipeout)
│   ├── linux-config-history/   # archived .config files from previous kernel versions
│   ├── old_image/              # archived zImage binaries
│   └── html/                   # archived OUYA web dashboard
├── Makefile                    # main build system
├── sysctl.conf                 # reference sysctl for the OUYA
└── zImage                      # last successfully built and tested kernel image
```

## Build workflow

### 1. First time setup

Build the dockcross image and compile mkbootimg:

```bash
# build cross-compilation Docker image
docker build -t linux-kernel-armv7 dockcross/

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
make kernel_dtb      # appends tegra30-ouya.dtb to zImage
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
| `make copy_lib` | Deploy modules via rsync |
| `make clean` | Clean build artifacts |
| `make clean_kernel` | Remove all build directories and zImage |
| `make reset_kernel` | Hard reset linux submodule |
| `make mkbootimg_bin` | Compile mkbootimg from submodule |
| `make submodule-linux` | Init/update linux submodule |
| `make submodule-mkbootimg` | Init/update mkbootimg submodule |
| `make submodule-all` | Init/update all submodules |

## Kernel configuration

The final `.config` is built by merging fragments in this order:

1. `tegra_defconfig` (base)
2. `docker.fragment` (cgroups, namespaces, overlay, netfilter)
3. `iptables_qos.fragment` (full iptables/nftables/QoS stack)
4. `notuner.fragment` (disable unused DVB/media tuners)
5. `ouya.fragment` (OUYA-specific: DTB append, cmdline, GPIO fan, Tegra cpuidle, thermal)
6. `usbserial.fragment` (CH341, CP210x)

To validate Docker compatibility after configuration:

```bash
bash linux-config/check-config.sh linux-build/.config
```

## Boot process

The OUYA bootloader (Tegra CBoot) does not boot a raw zImage. The kernel must be wrapped in an Android boot image format (no ramdisk). The boot image is loaded temporarily into RAM via `fastboot boot` — there is no permanent boot partition written.

The kernel cmdline is embedded in `ouya.fragment` and includes the serial number, GPT sector, root device, and framebuffer parameters.

## LTS kernel updates

To update to a new LTS kernel version, fetch the new tag in the linux submodule:

```bash
cd linux
git fetch --depth 1 origin tag vX.XX.XX
git checkout vX.XX.XX
cd ..
git add linux
git commit -m "linux: update to vX.XX.XX LTS"
```

> A semi-automated update script (`scripts/lts-update.sh`) is planned for Step 7.

## References

- [pgwipeout's OUYA kernel work](https://github.com/pgwipeout/ouya-kernel) — original Tegra30 config reference
- [linux-stable](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git)
- [osm0sis/mkbootimg](https://github.com/osm0sis/mkbootimg)
- [dockcross](https://github.com/dockcross/dockcross)
