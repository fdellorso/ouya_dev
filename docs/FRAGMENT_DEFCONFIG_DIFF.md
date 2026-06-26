# Fragment vs tegra_defconfig Diff Report

Baseline generata con `make config` (tegra_defconfig → `linux-build/.config`) su kernel v6.12.91.

---

## bluetooth.fragment

### Ridondanti (stesso valore già in tegra_defconfig)

| Opzione | Note |
|---------|------|
| `CONFIG_BT=y` | Già in tegra_defconfig L56 |
| `CONFIG_BT_BREDR=y` | Default Kconfig quando `CONFIG_BT=y` |
| `CONFIG_BT_LE=y` | Default Kconfig quando `CONFIG_BT=y` |
| `CONFIG_BT_RFCOMM=y` | Già in tegra_defconfig L57 |
| `CONFIG_BT_BNEP=y` | Già in tegra_defconfig L58 |
| `CONFIG_BT_HIDP=y` | Già in tegra_defconfig L59 |
| `CONFIG_BT_HCIUART_H4=y` | Default quando `CONFIG_BT_HCIUART=y` |

### Effettivi (fragment cambia il valore)

| Opzione | Default (tegra_defconfig) | Fragment |
|---------|--------------------------|----------|
| `CONFIG_BT_HCIUART` | `=y` (L61 tegra_defconfig) | `=m` |
| `CONFIG_BT_BCM` | `=y` (implicito da BT_HCIUART_BCM=y, non in defconfig raw ma =y in .config) | `=m` |
| `# CONFIG_BT_HCIBTUSB is not set` | `=m` (L60 tegra_defconfig) | `is not set` |

### Nuove (assenti in tegra_defconfig)

Nessuna.

> **Riepilogo:** 3 righe effettive che modificano HCIUART/BCM da built-in a modulo e disabilitano HCIBTUSB. Tutto il resto è ridondante.

---

## docker.fragment

### Ridondanti

Tutte le 150+ righe `# CONFIG_* is not set` sono ridondanti — nessuna di queste opzioni è attiva in tegra_defconfig, quindi il `# is not set` non ha effetto.

Inoltre:
- `CONFIG_TASKS_TRACE_RCU=y` — già `=y` in `.config` (abilitato da `CONFIG_CGROUPS` tramite dependency Kconfig)
- `CONFIG_PROC_PID_CPUSET=y` — DUPLICATO nel fragment stesso (righe 297 e 334)

### Effettivi

Nessuno.

### Nuove (introdotte da docker.fragment, ~90 opzioni)

Categorie principali:
- **Cgroups/Namespace**: `CONFIG_CGROUP_DEVICE`, `CONFIG_CGROUP_PIDS`, `CONFIG_CGROUP_PERF`, `CONFIG_CPUSETS`, `CONFIG_MEMCG`, `CONFIG_MEMCG_KMEM`, `CONFIG_MEMCG_V1`, `CONFIG_CPUSETS_V1`, `CONFIG_CGROUP_BPF`, `CONFIG_CGROUP_WRITEBACK`, `CONFIG_BLK_CGROUP`, `CONFIG_BFQ_GROUP_IOSCHED`, `CONFIG_BLK_DEV_THROTTLING`, `CONFIG_CFS_BANDWIDTH`, ecc.
- **Networking**: `CONFIG_BRIDGE`, `CONFIG_VETH`, `CONFIG_MACVLAN`, `CONFIG_IPVLAN`, `CONFIG_VXLAN`, `CONFIG_VLAN_8021Q`, `CONFIG_NET_SCHED`, `CONFIG_NETFILTER`, `CONFIG_NETFILTER_XTABLES`, `CONFIG_NF_CONNTRACK`, `CONFIG_NF_NAT`, `CONFIG_IP_VS`, ecc.
- **Security**: `CONFIG_SECURITY`, `CONFIG_SECURITYFS`, `CONFIG_SECURITY_APPARMOR`, `CONFIG_SECURITY_SELINUX`, `CONFIG_INTEGRITY`
- **Filesystem**: `CONFIG_OVERLAY_FS`, `CONFIG_BTRFS_FS`
- **BPF**: `CONFIG_BPF_SYSCALL`, `CONFIG_BPF_EVENTS`, `CONFIG_CGROUP_BPF`
- **Varie**: `CONFIG_AUDIT`, `CONFIG_POSIX_MQUEUE`, `CONFIG_RAID6_PQ`, `CONFIG_XOR_BLOCKS`

> **Riepilogo:** ~90 opzioni nuove, 150+ `# is not set` ridondanti. Il fragment è pulito nel suo scopo (Docker runtime).

---

## iptables_qos.fragment

### Ridondanti

| Opzione | Note |
|---------|------|
| `# CONFIG_DEFAULT_CODEL is not set` | Default, non attivo |
| `# CONFIG_DEFAULT_FQ is not set` | Default, non attivo |
| `# CONFIG_DEFAULT_FQ_CODEL is not set` | Default, non attivo |
| `# CONFIG_DEFAULT_FQ_PIE is not set` | Default, non attivo |
| `# CONFIG_DEFAULT_SFQ is not set` | Default, non attivo |
| `# CONFIG_IFB is not set` | Default, non attivo |

### Effettivi

Nessuno — tutte le opzioni `CONFIG_*=m/y` non presenti in tegra_defconfig sono "nuove".

### Nuove (~290 opzioni)

L'intero stack iptables/nftables/QoS: `CONFIG_IP_NF_*`, `CONFIG_IP6_NF_*`, `CONFIG_NETFILTER_XT_*`, `CONFIG_NF_TABLES`, `CONFIG_NFT_*`, `CONFIG_NET_SCH_*`, `CONFIG_NET_CLS_*`, `CONFIG_NET_ACT_*`, `CONFIG_IP_SET_*`, eBridge ebtables.

> **Riepilogo:** ~290 opzioni tutte nuove. Fragment massiccio ma corretto. Le 6 righe `is not set` sono ridondanti e eliminabili.

---

## notuner.fragment

### Ridondanti

Nessuna.

### Effettivi (tutte le 150 righe)

Ogni `# CONFIG_DVB_* is not set` e `# CONFIG_MEDIA_TUNER_* is not set` disabilita driver che `tegra_defconfig` lascia a `=m`. Esempi:

| Opzione | Default (.config) | Fragment |
|---------|------------------|----------|
| `CONFIG_DVB_A8293` | `=m` | `is not set` |
| `CONFIG_DVB_AF9013` | `=m` | `is not set` |
| `CONFIG_DVB_PLL` | `=m` | `is not set` |
| `CONFIG_MEDIA_TUNER_SIMPLE` | `=m` | `is not set` |
| ... *(150 righe totali)* | `=m` | `is not set` |

### Nuove

Nessuna.

> **Riepilogo:** 150 righe effettive — disabilitano tutti i DVB/media tuner che tegra_defconfig imposta a modulo. Categoria "effettivo" al 100%.

---

## ouya.fragment

### Ridondanti

| Opzione | Note |
|---------|------|
| `# CONFIG_ARM_ATAG_DTB_COMPAT is not set` | Già non impostato in tegra_defconfig |
| `# CONFIG_CMDLINE_EXTEND is not set` | Già non impostato |
| `# CONFIG_CMDLINE_FROM_BOOTLOADER is not set` | Già non impostato |
| `# CONFIG_INITRAMFS_FORCE is not set` | Già non impostato |

### Effettivi

| Opzione | Default (tegra_defconfig) | Fragment |
|---------|--------------------------|----------|
| `CONFIG_ATAGS` | `=y` (abilitato in tegra_defconfig per ARM) | `is not set` |
| `CONFIG_CMDLINE` | `=""` (vuoto) | `="android.kerneltype=normal ..."` |
| `CONFIG_USB_CHIPIDEA_HOST` | `=y` (L255 tegra_defconfig) | `is not set` |
| `CONFIG_USB_CHIPIDEA_GENERIC` | `=y` (default quando CHIPIDEA=y) | `is not set` |
| `CONFIG_USB_CHIPIDEA_IMX` | `=y` (default quando CHIPIDEA=y) | `is not set` |
| `CONFIG_USB_CHIPIDEA_MSM` | `=y` (default quando CHIPIDEA=y) | `is not set` |
| `CONFIG_USB_CHIPIDEA_NPCM` | `=y` (default quando CHIPIDEA=y) | `is not set` |
| `CONFIG_USB_ROLE_SWITCH` | `=y` (default) | `is not set` |

### Nuove

| Opzione | Note |
|---------|------|
| `CONFIG_ARM_APPENDED_DTB=y` | Necessario per OUYA (bootloader non passa DTB) |
| `CONFIG_AUTOFS_FS=y` | Supporto autofs |
| `CONFIG_SENSORS_GPIO_FAN=m` | Ventola OUYA (GPIO) |
| `CONFIG_SENSORS_PWM_FAN=m` | Ventola OUYA (PWM) |
| `CONFIG_CMDLINE_FORCE=y` | Intenzionale — cmdline OUYA hardcoded |
| `CONFIG_THERMAL_GOV_BANG_BANG=y` | Governor termico per ventola on/off |
| `CONFIG_THERMAL_DEFAULT_GOV_BANG_BANG=y` | Default governor |
| `CONFIG_USB_EHCI_TEGRA=y` | Controller USB EHCI Tegra |

> **Riepilogo:** 8 righe effettive (disabilitano ATAGS, CHIPIDEA_HOST, e cmdline), 8 righe nuove, 4 ridondanti. Nota: `CONFIG_USB_CHIPIDEA_HOST is not set` è un cambiamento significativo — disabilita l'host mode del ChipIdea controller che tegra_defconfig abilita.

---

## security.fragment

### Ridondanti

| Opzione | Note |
|---------|------|
| `# CONFIG_SECURITY_IPE is not set` | Già non impostato in tegra_defconfig |

### Effettivi

Nessuno.

### Nuove

| Opzione | Note |
|---------|------|
| `CONFIG_LSM="landlock,lockdown,yama,safesetid,apparmor,selinux,bpf"` | Ordine di inizializzazione LSM |

> **Riepilogo:** 1 riga nuova (la stringa LSM ordering), 1 ridondante. Fragment molto snello.

---

## usb_gadget.fragment

### Ridondanti

Tutte le 19 righe `# CONFIG_USB_CONFIGFS_* is not set` e `# CONFIG_NVME_TARGET is not set` — già non impostate in tegra_defconfig.

### Effettivi

Nessuno.

### Nuove

| Opzione | Note |
|---------|------|
| `CONFIG_USB_LIBCOMPOSITE=y` | Libreria composite gadget |
| `CONFIG_USB_U_ETHER=y` | Utility ethernet gadget |
| `CONFIG_USB_F_RNDIS=y` | Funzione RNDIS |
| `CONFIG_USB_CONFIGFS=y` | Framework configfs |
| `CONFIG_USB_CONFIGFS_RNDIS=y` | RNDIS via configfs |

> **Riepilogo:** 5 opzioni nuove (stack RNDIS gadget), 19 `is not set` ridondanti. Notevole: `CONFIG_USB_GADGET` è già `=y` in tegra_defconfig (L256), ma il fragment aggiunge i sub-options specifici RNDIS.

---

## usbserial.fragment

### Ridondanti

Tutte le 49 righe `# CONFIG_USB_SERIAL_* is not set` — praticamente tutti i driver seriali USB alternativi sono già non impostati in tegra_defconfig.

### Effettivi

Nessuno.

### Nuove

| Opzione | Note |
|---------|------|
| `CONFIG_USB_SERIAL=m` | Framework USB serial (come modulo) |
| `CONFIG_USB_SERIAL_CH341=m` | Adattatore CH341 |
| `CONFIG_USB_SERIAL_CP210X=m` | Adattatore CP210x |

> **Riepilogo:** 3 opzioni nuove (framework + 2 driver), 49 `is not set` ridondanti.

---

## wireless.fragment

### Ridondanti — **TUTTE e 10 le righe**

| Opzione | Note |
|---------|------|
| `CONFIG_CFG80211=y` | Già in tegra_defconfig L63 |
| `CONFIG_MAC80211=y` | Già in tegra_defconfig L64 |
| `CONFIG_RFKILL=y` | Già in tegra_defconfig L65 |
| `CONFIG_RFKILL_INPUT=y` | Già in tegra_defconfig L66 |
| `CONFIG_RFKILL_GPIO=y` | Già in tegra_defconfig L67 |
| `CONFIG_BRCMFMAC=m` | Già in tegra_defconfig L105 |
| `CONFIG_BRCMFMAC_PROTO_BCDC=y` | Default quando BRCMFMAC=m |
| `CONFIG_BRCMFMAC_SDIO=y` | Default quando BRCMFMAC=m |
| `# CONFIG_BRCM_TRACING is not set` | Già non impostato |
| `# CONFIG_BRCMDBG is not set` | Già non impostato |

### Effettivi

Nessuno.

### Nuove

Nessuna.

> **⚠ Riepilogo: wireless.fragment è INTERAMENTE RIDONDANTE.** Ogni singola opzione è già presente con lo stesso valore in tegra_defconfig. Può essere rimosso senza alcun effetto sul `.config` finale.

---

## Riepilogo generale

| Fragment | Ridondanti | Effettivi | Nuove | Valutazione |
|----------|-----------|-----------|-------|-------------|
| wireless.fragment | **10** (100%) | 0 | 0 | 🟢 **Completamente eliminabile** |
| bluetooth.fragment | 8 | 3 | 0 | 🟡 Da sfoltire |
| docker.fragment | 150+ | 0 | ~90 | 🟡 `# is not set` rumorosi da rimuovere |
| iptables_qos.fragment | 6 | 0 | ~290 | 🟡 6 righe ridondanti |
| notuner.fragment | 0 | 150 | 0 | 🟢 Corretto (tutto effettivo) |
| ouya.fragment | 4 | 8 | 8 | 🟢 Corretto (maggioranza effettivo/nuovo) |
| security.fragment | 1 | 0 | 1 | 🟢 Corretto |
| usb_gadget.fragment | 19 | 0 | 5 | 🟡 19 righe ridondanti |
| usbserial.fragment | 49 | 0 | 3 | 🟡 49 righe ridondanti |

### Raccomandazioni

1. **wireless.fragment**: rimuovere completamente (100% overlap con tegra_defconfig).
2. **docker.fragment**, **usb_gadget.fragment**, **usbserial.fragment**: rimuovere tutte le righe `# CONFIG_* is not set` che non hanno effetto (sono già "not set" di default). Mantenere solo le righe `CONFIG_*=y/m` nuove e le righe `# CONFIG_* is not set` che effettivamente **disabilitano** qualcosa (tipo quelle in `notuner.fragment` e `ouya.fragment`).
3. **bluetooth.fragment**: rimuovere le 8 righe ridondanti, tenere solo le 3 effettive.
4. Verificare che `CONFIG_USB_CHIPIDEA_HOST is not set` in `ouya.fragment` sia intenzionale — tegra_defconfig lo imposta a `=y` e il fragment lo disabilita.
