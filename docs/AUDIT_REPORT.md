# Audit Report — ouya_dev

Generated: 2026-06-26

## 1. Incongruenze README.md vs AGENTS.md vs stato reale

### 1.1 — Versione kernel dichiarata in AGENTS.md

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `AGENTS.md:5` | Dichiara `"Currently tracking kernel v6.6.x LTS"` ma il submodule `linux/` è su `v6.12.91` e `README.md:5` dice 6.12.x. AGENTS.md non è stato aggiornato dopo il revert/re-advance. | **bloccante** (disorienta un nuovo contributor) | Allineare AGENTS.md con README.md: `"Currently tracking kernel v6.12.x LTS"`. |

### 1.2 — docs/ISSUES.md non esiste

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `AGENTS.md:5` | `"(see docs/ISSUES.md)"` — il file non esiste sul disco. | **minore** | Creare `docs/ISSUES.md` con la descrizione del bug USB, oppure rimuovere il riferimento. |

### 1.3 — README.md: merge order non corrisponde al Makefile

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `README.md:134-145` vs `Makefile:100-108` | README elenca l'ordine di merge: docker → iptables_qos → notuner → ouya → usbserial → wireless → bluetooth → usb_gadget → security. Il Makefile merge SECURITY come ultimo (corretto). README è allineato. **Nessuna incongruenza qui.** | — | — |

---

## 2. Opzioni duplicate o in conflitto tra fragment

### 2.1 — docker.fragment vs iptables_qos.fragment: decine di conflitti

`docker.fragment` disabilita esplicitamente (`# CONFIG_... is not set`) decine di opzioni che `iptables_qos.fragment` subito dopo imposta a `=m` o `=y`. Poiché `iptables_qos.fragment` viene merged dopo (riga 101 del Makefile), i suoi valori vincono — ma mantenere i `# is not set` in `docker.fragment` è fuorviante e rumoroso.

Esempi (lista parziale — ogni `# ... is not set` in docker.fragment che confligge con iptables_qos.fragment):

| Opzione | docker.fragment | iptables_qos.fragment |
|---------|----------------|----------------------|
| `CONFIG_BRIDGE_NF_EBTABLES` | `is not set` (L51) | `=m` (L1) |
| `CONFIG_IP6_NF_IPTABLES` | `is not set` (L69) | `=m` (L2) |
| `CONFIG_IP_NF_ARPTABLES` | `is not set` (L73) | `=m` (L3) |
| `CONFIG_IP_NF_MATCH_AH` | `is not set` (L77) | `=m` (L4) |
| `CONFIG_IP_NF_MATCH_ECN` | `is not set` (L78) | `=m` (L5) |
| `CONFIG_IP_NF_MATCH_TTL` | `is not set` (L79) | `=m` (L7) |
| `CONFIG_IP_NF_RAW` | `is not set` (L81) | `=m` (L8) |
| `CONFIG_IP_NF_SECURITY` | `is not set` (L82) | `=m` (L9) |
| `CONFIG_IP_NF_TARGET_NETMAP` | `is not set` (L84) | `=m` (L11) |
| `CONFIG_IP_NF_TARGET_REJECT` | `is not set` (L86) | `=m` (L12) |
| `CONFIG_IP_NF_TARGET_SYNPROXY` | `is not set` (L87) | `=m` (L13) |
| `CONFIG_IP_SET` | `is not set` (L88) | `=m` (L15) |
| `CONFIG_IP_VS_DEBUG` | `is not set` (L90) | `=y` (L16) |
| `CONFIG_IP_VS_IPV6` | `is not set` (L94) | `=y` (L20) |
| `CONFIG_IP_VS_PROTO_AH` | `is not set` (L103) | `=y` (L27) |
| `CONFIG_IP_VS_PROTO_ESP` | `is not set` (L104) | `=y` (L28) |
| `CONFIG_IP_VS_PROTO_SCTP` | `is not set` (L105) | `=y` (L29) |
| `CONFIG_NETFILTER_NETLINK_ACCT` | `is not set` (L126) | `=m` (L35) |
| `CONFIG_NETFILTER_NETLINK_LOG` | `is not set` (L127) | `=m` (L36) |
| ... e molte altre `NETFILTER_XT_*` | tutte `is not set` | tutte `=m` |

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `linux-config/fragment/docker.fragment` (multiple righe) | Contiene `# CONFIG_* is not set` per opzioni che vengono immediatamente sovrascritte da `iptables_qos.fragment`. Inutili e fuorvianti. | **minore** | Rimuovere da `docker.fragment` tutti i `# CONFIG_* is not set` che sono in conflitto con `iptables_qos.fragment`. |

### 2.2 — Duplicato intra-fragment: `CONFIG_PROC_PID_CPUSET`

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `docker.fragment:297` e `docker.fragment:334` | `CONFIG_PROC_PID_CPUSET=y` appare due volte nello stesso file. | **cosmetico** | Rimuovere la riga 334 (duplicato). |

---

## 3. Riferimenti a path, target make o file inesistenti

### 3.1 — `kernel_dtb` path DTB errato per kernel ≥6.x

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `Makefile:173` | `cat $(KERNEL_DTBS)/tegra30-ouya.dtb` — da kernel 6.x i DTB Tegra sono installati in `nvidia/` subdirectory. Il comando `dtbs_install` produce `$(KERNEL_DTBS)/nvidia/tegra30-ouya.dtb`. Il Makefile punta al path sbagliato, quindi `make kernel_dtb` fallirà. | **bloccante** | Correggere in: `cat $(KERNEL_DTBS)/nvidia/tegra30-ouya.dtb` |

### 3.2 — `check-config.sh` non progettato per l'uso come descritto

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `AGENTS.md:18`, `README.md:150` | Raccomandano `bash linux-config/check-config.sh linux-build/.config` come validatore di configurazione. Il file `check-config.sh` è una copia del checker runtime di Docker (verifica cgroup, apparmor_parser, /dev/zfs, /proc mounts) ereditato dal progetto moby. Eseguirlo su un `.config` statico produrrà risultati fuorvianti (maggior parte dei check runtime falliranno o non hanno senso). | **minore** | Sostituire `check-config.sh` con un vero validatore kconfig statico, oppure documentare che va eseguito SOLO sulla macchina target OUYA (non sul build host). |

### 3.3 — `linux-config/check-config.old` file orfano

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `linux-config/check-config.old` | Copia di backup di una versione precedente di `check-config.sh`. Differisce leggermente (include `RT_GROUP_SCHED`, `AUFS_FS`, `BLK_DEV_DM`). Non referenziato da nessuna parte. | **cosmetico** | Rimuovere `check-config.old` o documentarne lo scopo. |

### 3.4 — `docs/BUILD_NOTES.md` path DTB obsoleto

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `docs/BUILD_NOTES.md:15` | `linux-build/arch/arm/boot/dts/tegra30-ouya.dtb` — da kernel 6.x il path reale è `arch/arm/boot/dts/nvidia/tegra30-ouya.dtb`. | **cosmetico** | Aggiornare il path nel commento. |

---

## 4. TODO e note obsolete

### 4.1 — Makefile: TODO iniziali già completati

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `Makefile:1-3` | `# TODO create FULL IPTABLE fragment` — `iptables_qos.fragment` esiste e sembra completo. `# scripts/lts-update.sh for LTS kernel bumps` — `scripts/lts-update.sh` esiste. Entrambi i TODO sono stati implementati. | **cosmetico** | Rimuovere le righe 1-3. |

### 4.2 — Makefile: NPROCS hardcoded a 8

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `Makefile:16` | `export NPROCS:=8` hardcoded, con le righe 18-23 commentate che facevano auto-detection. Su macchine con meno di 8 core, questo può portare a OOM durante la compilazione. Su macchine con più core, lascia performance inutilizzate. | **minore** | Riattivare l'auto-detection commentata (righe 18-23). |

### 4.3 — Makefile: ZFS build comment block

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `Makefile:80-86` | Blocco di commenti sull'integrazione ZFS (righe ZFS + autogen.sh + configure). ZFS non è un prerequisito del progetto. Sembra un esperimento passato. | **cosmetico** | Rimuovere il blocco commentato per pulizia. |

---

## 5. Sovrapposizione fragment / tegra_defconfig (ridondanze)

### 5.1 — Opzioni probabilmente già in tegra_defconfig

Non avendo accesso a `tegra_defconfig` per v6.12.91 in questa sessione, l'analisi si basa su conoscenza storica. Le seguenti opzioni in `ouya.fragment` sono con alta probabilità già incluse in `tegra_defconfig`:

| Opzione | Fragment | Note |
|---------|----------|------|
| `CONFIG_USB_EHCI_TEGRA=y` | `ouya.fragment:18` | Quasi certamente già attivo in tegra_defconfig su arch/arm/configs/tegra_defconfig. |
| `CONFIG_THERMAL_GOV_BANG_BANG=y` | `ouya.fragment:13` | Potrebbe non essere il default, ma tegra_defconfig potrebbe già includerlo. |

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `ouya.fragment:18` | Verificare se `CONFIG_USB_EHCI_TEGRA` è già in `tegra_defconfig`. Se sì, è ridondante. | **cosmetico** | Verificare con `make config && grep CONFIG_USB_EHCI_TEGRA linux-build/.config` senza applicare fragments. |

### 5.2 — `CONFIG_USB_CHIPIDEA_HOST is not set` in ouya.fragment

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `ouya.fragment:19` | Imposta `# CONFIG_USB_CHIPIDEA_HOST is not set`, disabilitando esplicitamente il driver host del controller ChipIdea. Se questo è il controller dell'unica porta USB esterna dell'OUYA, potrebbe essere la causa (o un workaround) del bug USB descritto in AGENTS.md. AGENTS.md attribuisce il problema a parametri PHY mancanti nel DTS senza menzionare questa impostazione. | **minore** | Documentare in AGENTS.md o in una nota nel fragment se `CHIPIDEA_HOST` è disabilitato intenzionalmente o se è un workaround temporaneo. |

---

## 6. Altri problemi

### 6.1 — Makefile `submodule-linux` hardcoded tag

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `Makefile:195` | `git checkout v6.12.91` hardcoded. Il `.gitmodules` ha `branch = linux-6.12.y`. Quando `lts-update.sh` cambia versione, aggiorna `.gitmodules` ma NON il Makefile. Il Makefile rimarrà su v6.12.91. | **minore** | Modificare `submodule-linux` per leggere il branch da `.gitmodules` con `git config -f .gitmodules submodule.linux.branch` e fare checkout del tag più recente su quel branch. |

### 6.2 — Makefile `submodule-mkbootimg` non usa branch tracking

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `Makefile:200` | `git checkout master` hardcoded, ignora `.gitmodules` che ha `branch = master` per mkbootimg. Funziona ma è incoerente con la gestione del submodule linux. | **cosmetico** | Leggere il branch da `.gitmodules` come per linux. |

### 6.3 — Makefile `reset_kernel` comando pericoloso

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `Makefile:243` | `git clean -fxd :/` — il path specifier `:/` significa dalla root del repository, e `-fxd` rimuove tutto (file non tracciati, directory, file ignorati). Un errore di esecuzione potrebbe cancellare l'intero working tree. | **minore** | Sostituire con `git -C $(LINUX_DIR) reset --hard && git -C $(LINUX_DIR) clean -fdx` (senza `:` e nel submodule corretto). |

### 6.4 — `lts-update.sh` messaggio e URL non allineati

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `scripts/lts-update.sh:54` | Messaggio: `"Fetching release info from endoflife.date..."` ma la variabile `EOL_URL` alla riga 55 usa `https://endoflife.date/api/linux.json`. Il nome del dominio è `endoflife.date` — il messaggio lo tronca. Minimo, ma potrebbe confondere. | **cosmetico** | Correggere il messaggio in `"Fetching release info from endoflife.date..."`. |

### 6.5 — `ouya_load_boot.sh` non verifica che zImage esista

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `scripts/ouya_load_boot.sh:5` | Accetta un path zImage come argomento ma non verifica che il file esista prima di lanciare `fastboot boot`. Se il file non esiste, `fastboot` darà un errore criptico. | **minore** | Aggiungere `[ -f "$ZIMAGE" ] || die "File not found: $ZIMAGE"` dopo la riga 5. |

### 6.6 — dockcross/Dockerfile installa pacchetti non necessari

| File | Problema | Severità | Suggerimento |
|------|----------|----------|--------------|
| `dockcross/Dockerfile:4` | `apt-get install -y libgmp-dev libmpc-dev libssl-dev` — `libssl-dev` è necessario per la compilazione del kernel (per `CONFIG_SYSTEM_TRUSTED_KEYS`). `libgmp-dev` e `libmpc-dev` sono dipendenze del toolchain GCC ma dockcross/linux-armv7 include già GCC precompilato. Vanno verificati. | **cosmetico** | Verificare se `libgmp-dev` e `libmpc-dev` sono effettivamente necessari al build del kernel (non lo sono tipicamente). Se non servono, rimuoverli. |

---

## Riepilogo per severità

| Severità | Conteggio | Azione raccomandata |
|----------|-----------|---------------------|
| **Bloccante** | 2 | 1) AGENTS.md versione kernel errata; 2) `kernel_dtb` path DTB rotto su v6.12 |
| **Minore** | 7 | Conflitti fragment, USB_CHIPIDEA_HOST, NPROCS, submodule-linux hardcoded, check-config.sh fuorviante, reset_kernel pericoloso, ouya_load_boot.sh senza validazione |
| **Cosmetico** | 5 | TODO rimossi, check-config.old orfano, BUILD_NOTES path, dup PROC_PID_CPUSET, messaggio lts-update.sh, ZFS comment block |
