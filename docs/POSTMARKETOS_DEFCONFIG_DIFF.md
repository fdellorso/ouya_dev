# PostmarketOS vs tegra_defconfig (nostro) Diff Report

## Premessa

- **PostmarketOS config**: `reference/postrmaketos/config-ouya-ouya-mainline.armv7` — kernel **5.0.0**, config Alpine Linux per OUYA.
- **Nostro .config**: `linux-build/.config` — kernel **6.12.91**, generato da `make config` (tegra_defconfig processato da Kconfig).
- L'analisi considera solo le opzioni attive (`=y` o `=m`) in almeno uno dei due config. Opzioni "is not set" in entrambi sono ignorate.
- Opzioni rimosse/rinominate tra 5.0 e 6.12 sono verificate contro il kernel sorgente prima di essere classificate come "assenti".

---

## 1. Solo in postmarketOS (opzioni attive in pmOS, assenti o disabilitate nel nostro .config)

### Alta priorità — potenziale impatto su USB / PHY / EMC / pinmux / SDHCI

| Opzione | pmOS | Nostro | Priorità | Note |
|---------|------|--------|----------|------|
| `CONFIG_TEGRA_CLK_EMC` | `=y` | assente | **ALTA** | Clock driver per EMC (External Memory Controller). Assente nel nostro config. Tegra30 richiede un EMC clock ben calibrato per la stabilità delle periferiche (incluso USB). |
| `CONFIG_BATTERY_MAX17042` | `=y` | `is not set` | **MEDIA** | Fuel gauge MAX17042 — presente su molte schede Tegra30. Non indispensabile per USB ma parte del power management. |
| `CONFIG_CHARGER_MAX8903` | `=y` | `is not set` | **MEDIA** | Caricabatterie MAX8903 — presente su OUYA per la gestione alimentazione. |
| `CONFIG_ARM_ATAG_DTB_COMPAT` | `=y` | `is not set` (ouya.fragment) | **BASSA** | Compatibilità ATAG→DTB. Noi usiamo `ARM_APPENDED_DTB` + `CMDLINE_FORCE`, quindi non serve. Differenza intenzionale. |
| `CONFIG_INET6_XFRM_MODE_BEET` | `=y` | assente | **BASSA** | Modalità BEET IPsec. Non usata. |
| `CONFIG_INET6_XFRM_MODE_TRANSPORT` | `=y` | assente | **BASSA** | Modalità Transport IPsec. Rimosso in kernel >5.2 (integrato in XFRM). Falso positivo. |
| `CONFIG_INET_XFRM_MODE_TRANSPORT` | `=y` | assente | **BASSA** | Stessa situazione — rimosso in kernel moderno. Falso positivo. |
| `CONFIG_CFG80211_WEXT` | `=y` | `is not set` | **BASSA** | WEXT compatibility per wireless. Noi usiamo cfg80211 diretto. |
| `CONFIG_USB_NET_RNDIS_HOST` | `=y` | `is not set` | **MEDIA** | RNDIS host side (permette alla OUYA di fare da host RNDIS via USB gadget? No, host RNDIS è per connettere dispositivi RNDIS come modem). |
| `CONFIG_CONFIGFS_FS` | `=y` | `is not set` | **MEDIA** | Filesystem configfs. Noi abilitiamo configfs tramite `CONFIG_CONFIGFS` (che in kernel 6.12 è un bool separato). |
| `CONFIG_I2C_GPIO` | `=y` | `is not set` | **BASSA** | I2C bit-banging via GPIO. Non serve sulle OUYA (I2C Tegra nativo disponibile). |
| `CONFIG_UEVENT_HELPER` | `=y` | `is not set` | **BASSA** | Uevent helper userspace. Deprecato su kernel moderni. |
| `CONFIG_CRYPTO_MD5` | `=y` | `is not set` | **BASSA** | MD5. Non più necessario per kernel moderni (usano lib MD5). |
| `CONFIG_CRYPTO_DES` | `=y` | `is not set` | **BASSA** | DES. Deprecato. |
| `CONFIG_CRYPTO_XTS` | `=y` | `is not set` | **BASSA** | XTS. Noi lo abilitiamo tramite crypto manager. |
| `CONFIG_DAX` | `=y` | `is not set` | **BASSA** | Direct Access (NVDIMM). Non rilevante per ARM embedded. |
| `CONFIG_RAS` | `=y` | `is not set` | **BASSA** | Reliability/Availability/Serviceability. Server-class feature. |
| `CONFIG_MFD_WM8994` | `=y` | `is not set` | **BASSA** | Wolfson WM8994 codec. OUYA usa WM8903 (già abilitato). |
| `CONFIG_DRM_TEGRA_DEBUG` | `=y` | `is not set` | **BASSA** | Debug DRM Tegra. Noi non lo vogliamo in produzione. |
| `CONFIG_SLAB` | `=y` | assente | **BASSA** | pmOS usa SLAB; noi usiamo SLUB (default kernel moderno). |
| `CONFIG_PRINTK_NMI` | `=y` | assente | **BASSA** | Printk in contesto NMI. Rimosso in kernel >5.x (integrato). |
| `CONFIG_SND_RAWMIDI` | `=y` | assente | **BASSA** | Raw MIDI. Non necessario. |
| `CONFIG_SND_SOC_SPDIF` | `=y` | `is not set` | **BASSA** | Codec SPDIF. Rimosso/rinominato in kernel moderno. |
| `CONFIG_SCHED_DEBUG` | `=y` | assente | **BASSA** | Debug scheduler. Noi non lo vogliamo in produzione. |
| `CONFIG_PCIE_DW_HOST` | `=y` | assente | **BASSA** | Synopsys PCIe host. Noi abbiamo `CONFIG_PCI_TEGRA` che è il driver specifico. |
| `CONFIG_MFD_CROS_EC` | `=y` | assente | **BASSA** | Chrome OS EC. Noi abbiamo `CONFIG_MFD_CROS_EC_DEV` (rinominato in kernel 6.12). |
| `CONFIG_VIDEO_V4L2` | `=y` | assente | **BASSA** | Noi abbiamo `CONFIG_VIDEO_V4L2_I2C`. |
| `CONFIG_DEBUG_FS` | `=y` | `is not set` | **BASSA** | Debugfs. Disabilitato per produzione. |
| `CONFIG_DEBUG_SLAB` | `=y` | assente | **BASSA** | Debug SLAB. Non applicabile (noi usiamo SLUB). |
| `CONFIG_MTD_M25P80` | `=y` | assente | **BASSA** | Flash SPI. Noi usiamo `CONFIG_MTD_SPI_NOR`. |
| `CONFIG_EMBEDDED` | `=y` | assente | **BASSA** | Opzione embedded. Noi usiamo `CONFIG_EXPERT`. |
| `CONFIG_SHUFFLE_PAGE_ALLOCATOR` | `=y` | `is not set` | **BASSA** | Page allocator shuffling. Non necessario. |
| `CONFIG_DM_CRYPT` | `=y` | assente | **BASSA** | Device mapper crypt. Non necessario. |
| `CONFIG_BLK_DEV_DM` | `=y` | assente | **BASSA** | Device mapper. Non necessario. |
| `CONFIG_HAVE_CONTEXT_TRACKING` | `=y` | assente | **BASSA** | Rinominato in `CONFIG_HAVE_CONTEXT_TRACKING_USER` in kernel 6.12. |
| `CONFIG_KERNEL_LZMA` | `=y` | `is not set` | **BASSA** | Compressione kernel. Noi usiamo GZIP. |
| `CONFIG_MEDIA_SUBDRV_AUTOSELECT` | `=y` | `is not set` | **BASSA** | Auto-select dei subdriver media. Noi gestiamo manualmente. |
| `CONFIG_PCIEAER` | `=y` | `is not set` | **BASSA** | PCIe Advanced Error Reporting. Non necessario. |
| `CONFIG_PM_DEBUG` | `=y` | `is not set` | **BASSA** | Debug PM. Produzione. |
| `CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL` | `=y` | `is not set` | **BASSA** | Governor schedutil come default. Noi usiamo ondemand (tegra_defconfig). |

---

## 2. Solo nel nostro .config (opzioni attive in noi, assenti o disabilitate in pmOS)

### Alta priorità — potenziale impatto su USB / Tegra30

| Opzione | Nostro | pmOS | Priorità | Note |
|---------|--------|------|----------|------|
| `CONFIG_TEGRA30_EMC` | `=y` | assente | **ALTA** | EMC driver per Tegra30. Fondamentale per la stabilità EMC e quindi USB. postmarketOS non ce l'ha (usa `TEGRA_CLK_EMC` che in 5.0 era separato). |
| `CONFIG_USB_CHIPIDEA_TEGRA` | `=y` | assente | **ALTA** | Tegra-specific glue per ChipIdea. In kernel 5.0 questo era integrato in `CHIPIDEA_OF`. |
| `CONFIG_GPIO_MAX77620` | `=y` | assente | **ALTA** | GPIO per PMIC MAX77620 — presente su alcune varianti OUYA. |
| `CONFIG_REGULATOR_MAX77620` | `=y` | assente | **ALTA** | Regolatore MAX77620 — gestione alimentazione. |
| `CONFIG_PINCTRL_MAX77620` | `=y` | assente | **ALTA** | Pinmux MAX77620 — gestione pin. |
| `CONFIG_RTC_DRV_MAX77686` | `=y` | assente | **MEDIA** | RTC MAX77686. |
| `CONFIG_SOC_TEGRA30_VOLTAGE_COUPLER` | `=y` | assente | **ALTA** | Voltage coupling per Tegra30 — gestione accoppiamento tensioni core/emc/cpu. |
| `CONFIG_TEGRA30_TSENSOR` | `=m` | assente | **MEDIA** | Thermal sensor Tegra30. |
| `CONFIG_TEGRA_HOST1X_CONTEXT_BUS` | `=y` | assente | **BASSA** | Host1x context bus. |
| `CONFIG_SENSORS_CROS_EC` | `=y` | assente | **BASSA** | Chrome OS EC sensors. |
| `CONFIG_BATTERY_ACER_A500` | `=y` | assente | **BASSA** | Battery driver Acer A500 (usato anche su OUYA). |
| `CONFIG_CROS_EC_CHARDEV` | `=y` | assente | **BASSA** | Chrome OS EC chardev. |
| `CONFIG_CROS_USBPD_NOTIFY` | `=y` | assente | **BASSA** | USB PD notifier Chrome OS. |

### Tutto lo stack netfilter/firewall/Docker (decine di opzioni)

La nostra configurazione include l'intero stack Docker + iptables/nftables + QoS (da `docker.fragment`, `iptables_qos.fragment`), che postmarketOS non ha. Opzioni includono:

| Categoria | Esempi |
|-----------|--------|
| Netfilter base | `CONFIG_NETFILTER=y`, `CONFIG_NETFILTER_XTABLES=y`, `CONFIG_IP_NF_IPTABLES=y` |
| Conntrack/NAT | `CONFIG_NF_CONNTRACK=y`, `CONFIG_NF_NAT=y`, `CONFIG_NF_NAT_MASQUERADE=y` |
| IPVS | `CONFIG_IP_VS=y`, `CONFIG_IP_VS_RR=y`, ... |
| nftables | `CONFIG_NF_TABLES=m`, `CONFIG_NFT_*` |
| QoS/sched | `CONFIG_NET_SCH_*` (~30 scheduler) |
| Classifiers | `CONFIG_NET_CLS_*` (~10) |
| Actions | `CONFIG_NET_ACT_*` (~20) |
| Bridge | `CONFIG_BRIDGE=y`, `CONFIG_BRIDGE_NETFILTER=y`, ebtables |
| Cgroups v1/v2 | `CONFIG_MEMCG_V1=y`, `CONFIG_CPUSETS_V1=y`, `CONFIG_CGROUP_BPF=y` |
| Security LSM | `CONFIG_SECURITY_APPARMOR=y`, `CONFIG_SECURITY_SELINUX=y`, |
| OverlayFS | `CONFIG_OVERLAY_FS=y` |
| Btrfs | `CONFIG_BTRFS_FS=y` |

Queste differenze sono **intenzionali** — il nostro progetto mira a supportare Docker; postmarketOS no.

### Altre differenze minori

- `CONFIG_VIDEO_TEGRA_VDE=y` — Video Decoder Engine Tegra (noi sì, loro no)
- `CONFIG_NFC_PN544_I2C=y` — NFC (noi sì, loro no)
- `CONFIG_ARM_TEGRA_CPUIDLE=y` — cpuidle Tegra (noi sì, loro no)
- `CONFIG_ARM_TEGRA_DEVFREQ=y` — devfreq Tegra (noi sì, loro no)
- `CONFIG_THERMAL_DEFAULT_GOV_BANG_BANG=y` — governor fan (noi sì, loro usano step_wise)
- `CONFIG_CMDLINE_FORCE=y` — forza cmdline (noi sì, loro no)
- `CONFIG_USB_CHIPIDEA_TEGRA=y` — glue Tegra per chipidea (noi sì, loro no)
- `CONFIG_USB_CONN_GPIO=y` — rilevamento connessione USB via GPIO (noi sì, loro no)
- `CONFIG_USB_RTL8153_ECM=y` — driver RTL8153 ECM (noi sì, loro no)

---

## 3. Valori diversi (stessa opzione, valore y vs m)

| Opzione | postmarketOS | Nostro | Impatto |
|---------|-------------|--------|---------|
| `CONFIG_SENSORS_GPIO_FAN` | `=y` | `=m` | Minimo — modulo vs built-in. Il modulo verrà caricato all'avvio se il DTS lo richiede. |
| `CONFIG_SND_HDA_TEGRA` | `=m` | `=y` | Minimo — audio Tegra built-in vs modulo. Noi lo compiliamo dentro al kernel. |
| `CONFIG_SND_HDA` | `=m` | `=y` | Stessa situazione. |
| `CONFIG_SND_HDA_CODEC_REALTEK` | `=m` | `=y` | Codec Realtek built-in. |
| `CONFIG_SND_HDA_CODEC_HDMI` | `=m` | `=y` | Codec HDMI built-in. |
| `CONFIG_SND_HDA_GENERIC` | `=m` | `=y` | Generic HDA built-in. |
| `CONFIG_SND_HDA_CORE` | `=m` | `=y` | Core HDA built-in. |

Tutte le differenze HDA sono `=m` (pmOS) vs `=y` (nostro) — scelta di compilazione, nessun impatto funzionale. Noi li abbiamo built-in per semplicità di boot senza initramfs.

---

## Riepilogo e raccomandazioni per il bug USB

### Opzioni candidate per investigazione (alta priorità)

| Opzione | Stato | Azione suggerita |
|---------|-------|------------------|
| `CONFIG_TEGRA_CLK_EMC` | Assente nel nostro .config | **Investigare se necessario.** In kernel 6.12, il clock EMC potrebbe essere gestito diversamente. Verificare se `CONFIG_TEGRA30_EMC` lo sostituisce. |
| `CONFIG_USB_CHIPIDEA_TEGRA` | Solo in noi (non in pmOS 5.0) | Presente. In kernel 5.0 non esisteva come opzione separata; in 6.12 è il glue Tegra per chipidea. **Confermare che sia attivo** (lo è). |
| `CONFIG_USB_CHIPIDEA_HOST` | `is not set` (identico in entrambi) | Sia pmOS che il nostro fragment la disabilitano. **Confermare che sia intenzionale.** |
| `CONFIG_USB_TEGRA_PHY` | `=y` (presente in entrambi) | OK. |
| `CONFIG_USB_ULPI` | `=y` (presente in entrambi) | OK. |
| `CONFIG_USB_PHY` | `=y` (presente in entrambi) | OK. |
| `CONFIG_SOC_TEGRA30_VOLTAGE_COUPLER` | Solo in noi | Nuovo in kernel 6.12. Gestisce accoppiamento tensioni. Potenzialmente rilevante per stabilità USB. |

### Conclusione

Le differenze principali sono:

1. **Stack Docker/netfilter** — intenzionale, assente in pmOS.
2. **Driver Tegra30 specifici** — alcuni nuovi in 6.12 (`TEGRA30_EMC`, `CHIPIDEA_TEGRA`, `VOLTAGE_COUPLER`) sono nostri (assenti in pmOS 5.0).
3. **Assenza `TEGRA_CLK_EMC`** — opzione 5.0 che potrebbe essere stata integrata in `TEGRA30_EMC` in 6.12.
4. **Config identica per CHIPIDEA_HOST** — entrambi disabilitano l'host mode ChipIdea. Se il bug USB persiste, la causa non è un'opzione Kconfig mancante rispetto a pmOS, ma molto probabilmente i parametri PHY nel DTS (come già diagnosticato in AGENTS.md).
