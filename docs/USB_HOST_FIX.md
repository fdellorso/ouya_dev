# Fix USB Host Reset-Loop su Tegra30 (OUYA)

## Problema

Il kernel Linux ≥6.6.2 causa un **reset-loop sulla porta USB host** della console OUYA (Tegra30/ARMv7). Quando una periferica USB viene collegata alla porta host, il controller USB entra in un ciclo infinito di reset, rendendo la periferica inutilizzabile.

Questo problema non si presenta con kernel ≤6.6.1.

## Root cause

Il problema è stato introdotto dal commit `38a41a0c0272` ("usb: chipidea: Fix DMA overwrite for Tegra"), backportato in v6.6.2. Questo commit ha modificato il meccanismo di bounce buffer DMA nel driver chipidea host (`drivers/usb/chipidea/host.c`):

**Prima (v6.6.1):** il bounce buffer veniva allocato solo quando il puntatore del buffer non era allineato a 32 byte.

**Dopo (v6.6.2+):** il bounce buffer viene allocato anche quando la lunghezza del buffer non è multipla di 4. Questo causa molte più allocazioni di bounce buffer, che il controller USB Tegra30 EHCI non gestisce correttamente.

## Soluzione

Due modifiche al kernel:

1. **Patch 1** (`0001-usb-chipidea-tegra-remove-REQUIRES_ALIGNED_DMA.patch`): rimuove il flag `CI_HDRC_REQUIRES_ALIGNED_DMA` dai dati platform di Tegra30 in `ci_hdrc_tegra.c`. Questo disabilita il meccanismo di bounce buffer per Tegra30.

2. **Patch 2** (`0002-usb-chipidea-host-revert-DMA-alignment-to-v6.6.1.patch`): riporta il codice DMA alignment in `host.c` allo stato di v6.6.1 (struct originale, bail-out a 32-byte, PTR_ALIGN).

## Come applicare

```bash
# 1. Checkout del kernel
make submodule-linux

# 2. Applicazione delle patch
make apply_patches

# 3. Configurazione e build
make config
make config_patch
make kernel
make kernel_dtb
make kernel_bootimg
```

## Versioni testate

| Versione | Stato |
|---|---|
| v6.6.1 | Funziona senza patch |
| v6.6.2 | Reset-loop (risolto con patch) |
| v6.12.104 | Reset-loop (risolto con patch) |

## File coinvolti

| File | Modifica |
|---|---|
| `drivers/usb/chipidea/ci_hdrc_tegra.c` | Rimuove `CI_HDRC_REQUIRES_ALIGNED_DMA` da `tegra30_ehci_soc_info` |
| `drivers/usb/chipidea/host.c` | Revert completo del codice DMA alignment a v6.6.1 |

## Note

- La patch 2 è necessaria perché il revert del flag da solo non risolve il problema. Il codice DMA in host.c deve essere riportato a v6.6.1.
- Le patch sono state testate su v6.6.2 e v6.12.104. Per v7.1.x è necessario un approccio diverso (revert parziale di host.c).
- `wireless.fragment` è 100% ridondante con `tegra_defconfig` ed è stato rimosso dal `config_patch`.
