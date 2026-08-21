# ouya_dev

Kernel Linux mainline personalizzato per la console [OUYA](https://en.wikipedia.org/wiki/Ouya) (Tegra30 / ARMv7).

La console OUYA esce di fabbrica con un kernel Android stock. Questo progetto lo sostituisce con un kernel Linux mainline (attualmente la serie **6.12.x LTS**), abilitando distribuzioni Linux complete (Void Linux, Arch Linux ARM, ecc.) con supporto a Docker, Podman, wireless, Bluetooth, gestione termica, iptables/nftables e USB gadget ethernet.

## Hardware

| Componente | Dettaglio |
|------------|-----------|
| SoC | NVIDIA Tegra30 (ARMv7) |
| RAM | 1 GB |
| Storage | eMMC interno + HDD USB (root) |
| WiFi | Broadcom BCM4330 (brcmfmac SDIO) |
| Bluetooth | Broadcom BCM4330 (HCI UART) |
| Audio | Wolfson WM8903 |

## Funzionalità kernel attive

### Wireless

- Driver **brcmfmac** (modulo) per BCM4330 via SDIO
- CFG80211 + MAC80211 + RFKILL abilitati
- **Firmware proprietario richiesto** su rootfs (vedi sezione [Firmware](#firmware))

### Bluetooth

- Driver **HCIUART** con supporto BCM (modulo) per BCM4330 via UART
- **HCIBTUSB** come fallback (modulo)
- Profile: LE, HIDP, BNEP
- Firmware caricato automaticamente dal modulo `btbcm` da `/lib/firmware/brcm/`

### Container runtime

Il kernel supporta Docker e Podman sia in modalità rootful che rootless.

| Requisito kernel | Docker rootful | Docker rootless | Podman rootful | Podman rootless |
|---|---|---|---|---|
| Namespaces (NET, PID, IPC, UTS, USER) | `=y` | `=y` | `=y` | `=y` |
| Cgroups (cpu, cpuset, device, freezer, pids, memory) | `=y` | `=y` | `=y` | `=y` |
| Overlay FS | `=y` | `=y` | `=y` | `=y` |
| OVERLAY_FS_INDEX | opzionale | **` =y`** | opzionale | **`=y`** |
| Bridge + VETH + Netfilter | `=y` | `=y` | `=y` | `=y` |
| TUN (`/dev/net/tun`) | non necessario | **`=y`** | non necessario | **`=y`** |
| FUSE | opzionale | **`=m`** | opzionale | **`=m`** |
| Seccomp + BPF | `=y` | `=y` | `=y` | `=y` |

- **Rootful**: usa un daemon con privilegi, networking via bridge/iptables
- **Rootless**: usa `slirp4netns` o `pasta` per la rete (serve `CONFIG_TUN=y`), `fuse-overlayfs` o overlay nativo per lo storage

### Networking

- **iptables** completo: filter, nat, mangle, raw, security
- **nftables**: modulo `NF_TABLES` con tutti i set rule
- **QoS/TC**: HTB, CAKE, FQ_CODEL, NETEM, INGRESS e altri scheduler
- **Bridge** con VLAN filtering, IGMP snooping, netfilter
- **VETH, VXLAN, MACVLAN, IPVLAN** (con L3S)
- **Netfilter avanzato**: conntrack, NAT, masquerade, mark, state, BPF match
- **IPVS** per load balancing (modulo)

### USB

- **Host**: EHCI Tegra, XHCI Tegra, Chipidea (`=y`)
- **Gadget**: RNDIS ethernet via configfs (per connessione host)
- **Serial**: CH341, CP210x, PL2303 (moduli)
- **Storage**: USB mass storage (`=y`)
- **Note**: porta host USB richiede le [patch USB host](#patch-usb-host-kernel-662) per kernel ≥6.6.2

### Storage

- **ext4**: con POSIX ACL e security attributes
- **btrfs**: con POSIX ACL
- **overlay**: per container (Docker/Podman)
- **tmpfs**: con POSIX ACL e extended attributes
- **devtmpfs** con auto-mount
- **FUSE**: modulo (per fuse-overlayfs in rootless mode)

### Thermal

- **GPIO fan** (modulo) + **PWM fan** (modulo)
- **Bang-bang governor** (default termico)

### Security

Stack LSM completo:

- **SELinux** (default security module)
- **AppArmor** (con export binario, hash, introspection)
- **Landlock** (LSM non-privilegiato)
- **Yama** (ptrace restriction)
- **Safesetid**
- **Lockdown LSM**
- **BPF LSM**

- **Seccomp** + seccomp filter
- **Module signing**: SHA512 + RSA (verifica firma moduli)
- **Audit** + audit syscall

### Audio

- **Wolfson WM8903** via Tegra ASoC (driver integrato nel defconfig)

## Fragment kernel

Il `.config` finale è generato combinando `tegra_defconfig` (base) con i seguenti fragment:

| # | Fragment | Contenuto |
|---|----------|-----------|
| 1 | `docker.fragment` | Cgroups v1/v2, namespaces, overlay, netfilter, memcg, FUSE |
| 2 | `iptables_qos.fragment` | iptables/nftables completo + QoS/TC |
| 3 | `notuner.fragment` | Disabilita DVB/TV/radio (mantiene VDE e webcam USB) |
| 4 | `ouya.fragment` | DTB append, cmdline force, GPIO fan, thermal bang_bang |
| 5 | `usbserial.fragment` | CH341, CP210x, PL2303 |
| 6 | `bluetooth.fragment` | BT HCI UART BCM per BCM4330 |
| 7 | `usb_gadget.fragment` | RNDIS ethernet via configfs |
| 8 | `rootless.fragment` | TUN (built-in), OVERLAY_FS_INDEX (per Docker/Podman rootless) |
| 9 | `security.fragment` | LSM stack, module signing, lockdown |

**Nota:** `wireless.fragment` è 100% ridondante con `tegra_defconfig` ed è stato commentato nel `config_patch`.

Per validare la compatibilità Docker dopo la configurazione:

```bash
bash linux-config/check-config.sh linux-build/.config
```

## Patch USB host (kernel ≥6.6.2)

### Problema

Il kernel Linux ≥6.6.2 causa un **reset-loop sulla porta USB host** della console OUYA. Quando una periferica USB viene collegata alla porta host, il controller USB entra in un ciclo infinito di reset, rendendo la periferica inutilizzabile.

Con kernel ≤6.6.1 il problema non si presenta.

### Root cause

Il commit `38a41a0c0272` ("usb: chipidea: Fix DMA overwrite for Tegra"), backportato in v6.6.2, ha modificato il meccanismo di bounce buffer DMA in `drivers/usb/chipidea/host.c`. Il controller USB Tegra30 EHCI non gestisce correttamente le allocazioni aggiuntive di bounce buffer introdotte dal nuovo codice.

### Soluzione

Due patch in `patches/`:

1. **`0001-usb-chipidea-tegra-remove-REQUIRES_ALIGNED_DMA.patch`** — rimuove il flag `CI_HDRC_REQUIRES_ALIGNED_DMA` da `tegra30_ehci_soc_info` in `ci_hdrc_tegra.c`

2. **`0002-usb-chipidea-host-revert-DMA-alignment-to-v6.6.1.patch`** — riporta il codice DMA alignment in `host.c` allo stato di v6.6.1

### Applicazione

Le patch vengono applicate automaticamente dopo il checkout del kernel:

```bash
make submodule-linux       # checkout v6.12.104
make apply_patches         # applica le 2 patch USB host
make config
make config_patch
make kernel
```

### Versioni testate

| Versione | Stato |
|---|---|
| v6.6.1 | Funziona senza patch |
| v6.6.2 | Reset-loop (risolto con patch) |
| v6.12.104 | Reset-loop (risolto con patch) |
| v7.x | Richiede un revert parziale diverso di host.c |

## Firmware

Il BCM4330 WiFi e Bluetooth richiedono firmware proprietari **non inclusi nel kernel** che vanno installati sul root filesystem.

### WiFi (brcmfmac)

Posizionare i seguenti file in `/lib/firmware/brcm/` sull'OUYA:

| File | Descrizione |
|------|-------------|
| `brcmfmac4330-sdio.bin` | Firmware binario BCM4330 |
| `brcmfmac4330-sdio.txt` | Configurazione NVRAM BCM4330 |

Fonte: [milaq/android_vendor_boxer8_ouya](https://github.com/milaq/android_vendor_boxer8_ouya) e [milaq/android_device_boxer8_ouya](https://github.com/milaq/android_device_boxer8_ouya) (vedere `reference/postmarketos/APKBUILD` per i commit esatti).

### Bluetooth

Il firmware BCM4330 Bluetooth viene caricato automaticamente dal modulo `btbcm` da `/lib/firmware/brcm/`. Il file esatto dipende dalla versione del kernel — controllare `dmesg` dopo il boot per il nome del file richiesto.

## Boot process

Il bootloader OUYA (Tegra CBoot) non avvia un zImage raw. Il kernel deve essere wrappato in formato Android boot image (senza ramdisk). L'immagine viene caricata temporaneamente in RAM via `fastboot boot` — non viene scritta una partizione di boot permanente.

La cmdline del kernel è hardcoded in `ouya.fragment` (`CONFIG_CMDLINE_FORCE=y`) e include il numero di seriale del dispositivo, i settori GPT, il root device (`/dev/sda1`) e i parametri del framebuffer. Aggiornare `CONFIG_CMDLINE` in `ouya.fragment` se il numero di seriale o la partizione root del dispositivo sono diversi.

Offset boot image (Tegra30, definiti nel Makefile):

| Parametro | Valore |
|-----------|--------|
| base | `0x10000000` |
| kernel_offset | `0x00008000` |
| ramdisk_offset | `0x01000000` |
| tags_offset | `0x00000100` |
| pagesize | `2048` |

## Build workflow

### 1. Setup iniziale

Costruire l'immagine dockcross e compilare mkbootimg:

```bash
make dockcross-build     # immagine Docker di cross-compilazione
make mkbootimg_bin       # compila mkbootimg dal submodule
make submodule-all       # inizializza tutti i submodule
```

### 2. Configurazione kernel

Generare la config base da tegra_defconfig e applicare tutti i fragment:

```bash
make config              # tegra_defconfig → linux-build/.config
make config_patch        # merge di tutti i fragment nel .config
make menuconfig          # opzionale: revisione interattiva
```

### 3. Build kernel

```bash
make apply_patches       # applica patch USB host (per kernel ≥6.6.2)
make kernel              # build zImage + moduli + dtbs
make kernel_dtb          # append del tegra30-ouya.dtb al zImage
make kernel_bootimg      # wrap in formato Android boot image → zImage
```

### 4. Deploy

Flash via fastboot (OUYA deve essere in modalità fastboot):

```bash
bash scripts/ouya_load_boot.sh   # riavvia al bootloader e fastboot boot del zImage
```

Deploy dei moduli kernel sul sistema in esecuzione:

```bash
make copy_lib            # rsync moduli a root@alarm.local:/lib/modules
```

### Target utili

| Target | Descrizione |
|--------|-------------|
| `make config` | Genera .config da tegra_defconfig |
| `make config_patch` | Merge di tutti i fragment nel .config |
| `make menuconfig` | Configurazione interattiva |
| `make apply_patches` | Applica patch USB host fix |
| `make kernel` | Build completo (zImage + moduli + dtbs) |
| `make kernel_dtb` | Append DTB al zImage |
| `make kernel_bootimg` | Wrap in Android boot image |
| `make copy_kernel DEPLOY_HOST=user@host:/path` | Deploy zImage via rsync |
| `make copy_lib` | Deploy moduli via rsync a root@alarm.local |
| `make clean` | Pulisce artefatti di build |
| `make clean_kernel` | Rimuove build dir e zImage |
| `make reset_kernel` | Hard reset del submodule linux |
| `make mkbootimg_bin` | Compila mkbootimg |
| `make submodule-linux` | Init/update submodule linux |
| `make submodule-mkbootimg` | Init/update submodule mkbootimg |
| `make submodule-all` | Init/update tutti i submodule |
| `make dockcross-build` | Build immagine Docker di cross-compilazione |
| `make dockcross-rebuild` | Pull immagine base e rebuild |

## Aggiornamento LTS

Usare lo script interattivo per aggiornare alla prossima versione LTS:

```bash
bash scripts/lts-update.sh
```

Lo script verifica le tag LTS disponibili, mostra un riepilogo, chiede conferma, aggiorna il submodule e crea un commit.

Aggiornamento manuale:

```bash
cd linux
git fetch --depth 1 origin tag vX.XX.XX
git checkout vX.XX.XX
cd ..
git add linux
git commit -m "linux: update to vX.XX.XX LTS"
```

## Struttura del repository

```
ouya_dev/
├── linux/                      # submodule — linux-stable v6.12.x LTS
├── mkbootimg/                  # submodule — osm0sis/mkbootimg (C implementation)
├── dockcross/                  # cross-compilation toolchain
├── linux-config/
│   ├── fragment/               # kconfig fragment
│   │   ├── docker.fragment     # Docker + FUSE
│   │   ├── iptables_qos.fragment  # iptables/nftables + QoS
│   │   ├── notuner.fragment    # disabilita DVB/TV/radio
│   │   ├── ouya.fragment       # OUYA/Tegra30: DTB, cmdline, fan, thermal
│   │   ├── usbserial.fragment  # CH341, CP210x, PL2303
│   │   ├── bluetooth.fragment  # BCM4330 BT HCI UART
│   │   ├── usb_gadget.fragment # RNDIS ethernet via configfs
│   │   ├── rootless.fragment   # TUN + OVERLAY_FS_INDEX (Docker/Podman rootless)
│   │   └── security.fragment   # LSM stack, module signing
│   ├── check-config.sh         # validazione .config vs requisiti Docker
│   └── .config-ouya-patch      # config completa di riferimento
├── patches/                    # patch kernel applicate prima del build
│   ├── 0001-usb-chipidea-tegra-remove-REQUIRES_ALIGNED_DMA.patch
│   └── 0002-usb-chipidea-host-revert-DMA-alignment-to-v6.6.1.patch
├── scripts/
│   ├── ouya_load_boot.sh       # flash kernel via adb/fastboot
│   └── lts-update.sh           # bump versione LTS
├── docs/
│   ├── USB_HOST_FIX.md         # documentazione fix USB host
│   └── BUILD_NOTES.md          # note storiche di build
├── reference/                  # materiali di riferimento (non modificare)
│   ├── ouya-patch/             # config community (pgwipeout)
│   ├── postmarketos/           # device file postmarketOS
│   └── ...
├── Makefile                    # build system
└── zImage                      # ultimo zImage testato
```

## Limitazioni note

- **USB host**: porta USB richiede patch per kernel ≥6.6.2
- **FANOTIFY**: non abilitato (non necessario per questo use case)
- **Huge pages**: non supportate (1GB RAM insufficiente per HUGETLB)
- **MEMCG_SWAP**: rimosso dal kernel v5.8+ (lo swap accounting è sempre attivo)
- **wireless.fragment**: ridondante con tegra_defconfig, commentato nel Makefile

## Riferimenti

- [pgwipeout ouya-kernel](https://github.com/pgwipeout/ouya-kernel) — config di riferimento Tegra30
- [postmarketOS OUYA](https://github.com/postmarketOS/pmaports) — device file e firmware
- [linux-stable](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git)
- [osm0sis/mkbootimg](https://github.com/osm0sis/mkbootimg)
- [dockcross](https://github.com/dockcross/dockcross)
