# Audit Report V2 — ouya_dev

Generated: 2026-08-20

This report supersedes `AUDIT_REPORT.md` (generated 2026-06-26). It corrects errors found in the previous report and incorporates cross-validation with an independent audit.

---

## Correzioni rispetto ad AUDIT_REPORT.md

### 1. kernel_dtb path — NON è un bug

AUDIT_REPORT.md issue 3.1 afferma che `Makefile:173` ha un path DTB errato (`tegra30-ouya.dtb` vs `nvidia/tegra30-ouya.dtb`).

**Questo è SBAGLIATO.** Su ARM, `CONFIG_ARCH_WANT_FLAT_DTB_INSTALL` è `def_bool y` (arch/arm/Kconfig:1403). Questo abilita il flattening in `scripts/Makefile.dtbinst`:

```makefile
ifdef CONFIG_ARCH_WANT_FLAT_DTB_INSTALL
dtbs := $(notdir $(dtbs))    # rimuove la sottodirectory
endif
```

Risultato: `dtbs_install` installa `nvidia/tegra30-ouya.dtb` come `$(INSTALL_DTBS_PATH)/tegra30-ouya.dtb` (senza `nvidia/`).

Il Makefile:173 è CORRETTO:
```makefile
cat $(KERNEL_DTBS)/tegra30-ouya.dtb >> ./zImage-$(VERSION).$(PATCHLEVEL).$(SUBLEVEL)
```

### 2. USB PHY parameters — NON sono mancanti nel DTS

Un audit indipendente ha affermato con confidenza HIGH che i parametri `nvidia,xcvr-*` sono mancanti da `tegra30-ouya.dts` e che questo causa probe failure/reset-loop USB.

**Questo è SBAGLIATO.** I parametri sono definiti in `tegra30.dtsi` (il file base incluso da `tegra30-ouya.dts`):

```
# tegra30.dtsi:1168-1193  (phy2: usb-phy@7d004000)
nvidia,xcvr-setup = <51>;
nvidia,xcvr-setup-use-fuses;
nvidia,xcvr-lsfslew = <2>;
nvidia,xcvr-lsrslew = <2>;
nvidia,xcvr-hsslew = <32>;
nvidia,hssquelch-level = <2>;
nvidia,hsdiscon-level = <5>;
```

`tegra30-ouya.dts` fa un overlay che aggiunge `vbus-supply` e `status = "okay"`. In DTS, l'overlay **merge** le proprietà — i parametri PHY dal base sono ereditati.

La frase in AGENTS.md:
> "present in the community decatf/postmarketOS fork DTS but absent from mainline tegra30-ouya.dts"

è **tecnicamente corretta ma fuorviante**: i parametri sono assenti da `tegra30-ouya.dts` perché sono in `tegra30.dtsi`. Il DTS finale li contiene comunque.

**Nota:** il problema USB potrebbe comunque derivare dai **valori** di questi parametri (potrebbero servire valori diversi per l'OUYA rispetto ai default del mainline). Questo va verificato confrontando con il fork decatf.

---

## Issues corrette

### ISSUE-01 — USB PHY tuning parameters (RIVISTO)

- **Severità precedente:** HIGH/CRITICAL (mancanti)
- **Severità corretta:** MEDIUM (potenzialmente valori errati)
- **Confidenza:** MEDIUM
- **Problema:** I parametri PHY esistono nel DTS finale (ereditati da tegra30.dtsi), ma i valori potrebbero non essere ottimali per l'hardware OUYA specifico. Il fork community (decatf) potrebbe usare valori diversi.
- **Azione:** Confrontare i valori `nvidia,xcvr-*` tra `tegra30.dtsi` mainline e il fork decatf. Se diversi, sovrascriverli in `tegra30-ouya.dts`.

### ISSUE-02 — kernel_dtb path (RIMOSSO)

Non è un bug. Vedi sezione "Correzioni" sopra.

### ISSUE-03 — CONFIG_USB_EHCI_TEGRA nel .config

- **Severità:** MEDIUM
- **Confidenza:** HIGH
- **Problema:** Un audit indipendente ha trovato `# CONFIG_USB_EHCI_TEGRA is not set` nel `linux-build/.config`. Il fragment `ouya.fragment` lo imposta a `=y`. La discrepanza suggerisce che il .config è stato generato quando `ouya.fragment` era troncato (il fenomeno di "spontaneous truncation" è documentato nei handoff).
- **Azione:** Rigenerare il .config con `make config && make config_patch` e verificare che `CONFIG_USB_EHCI_TEGRA=y` sia presente.

---

## Issue confermate (invariate)

Le seguenti issue del mio audit originale restano valide:

| ID | Severità | Problema | File |
|----|----------|----------|------|
| ISSUE-05 | HIGH | `submodule-linux` hardcoded `v6.12.91` | Makefile:195 |
| ISSUE-08 | MEDIUM | Serial number hardcoded nel CMDLINE | ouya.fragment:4 |
| ISSUE-09 | MEDIUM | No initramfs, brcmfmac è modulo | N/A |
| ISSUE-10 | MEDIUM | `reset_kernel` pericoloso (`git clean -fxd :/`) | Makefile:243 |
| ISSUE-11 | MEDIUM | ouya.fragment truncation risk | ouya.fragment |
| ISSUE-04 | LOW | `docs/ISSUES.md` inesistente | AGENTS.md:5 |
| ISSUE-05b | LOW | wireless.fragment 100% ridondante | wireless.fragment |
| ISSUE-06 | LOW | PROC_PID_CPUSET duplicato | docker.fragment:107,130 |
| ISSUE-07 | LOW | PWM fan configurato ma non nel DTS | ouya.fragment:6 |
| ISSUE-12 | LOW | check-config.sh fuorviante | check-config.sh |

---

## Verdetto aggiornato

**NEARLY READY** (confermato)

I blocker effettivi sono:
1. **HIGH** — Verificare/aggiustare i valori PHY per USB host (confronto con decatf)
2. **HIGH** — Aggiornare Makefile:195 (submodule-linux hardcoded)
3. **MEDIUM** — Rigenerare .config per confermare fragment non troncati
4. **MEDIUM** — Investigare ouya.fragment spontaneous truncation
