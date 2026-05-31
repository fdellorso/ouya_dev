# dockcross

Cross-compilation toolchain for the OUYA kernel (ARMv7 / Tegra30).

This folder contains a custom [dockcross](https://github.com/dockcross/dockcross) image that extends the stock `dockcross/linux-armv7` image with the additional packages required to build a Linux kernel.

## Files

| File | Description |
|------|-------------|
| `Dockerfile` | Extends `dockcross/linux-armv7` with kernel build dependencies |
| `kernel-armv7` | dockcross wrapper script for the custom `linux-kernel-armv7` image |
| `linux-armv7` | Stock dockcross wrapper script for `dockcross/linux-armv7` (upstream reference) |

## Image

The custom image is named `linux-kernel-armv7` and is **not published on any registry** — it must be built locally.

```bash
docker build -t linux-kernel-armv7 dockcross/
```

It adds the following packages on top of the stock `dockcross/linux-armv7`:

```
libgmp-dev
libmpc-dev
libssl-dev
```

These are required by the kernel build system for:
- `libgmp-dev` — GMP support in GCC plugins
- `libmpc-dev` — MPC support in GCC plugins
- `libssl-dev` — kernel module signing and certificate generation

## Usage

The wrapper script `kernel-armv7` is called by the `Makefile` targets to run any command inside the container with the current directory mounted as `/work`:

```bash
./dockcross/kernel-armv7 bash -c 'make -C linux O=../linux-build -j8 tegra_defconfig'
./dockcross/kernel-armv7 bash -c 'make -C linux O=../linux-build -j8 zImage modules dtbs'
```

The script automatically detects whether `docker` or `podman` is available and handles UID/GID mapping so that output files are owned by the current user.

## Updating the base image

To pull the latest `dockcross/linux-armv7` base and rebuild:

```bash
docker pull dockcross/linux-armv7
docker build --no-cache -t linux-kernel-armv7 dockcross/
```

## Toolchain

| Parameter | Value |
|-----------|-------|
| Target arch | `arm` |
| ABI | `gnueabihf` (hard-float) |
| Compiler prefix | `arm-linux-gnueabihf-` |
| ARCH | `arm` |

These values are set in the root `Makefile` and passed automatically to the kernel build system.
