# Waveform reproduction

Selected M4 waveforms in `results/m4/waveforms/` are small (individual files ≪ 20 MB; total selected set ≈ 92 KB) and are included as compact traces of directed reset/config scenarios.

Large Verilator dumps, FST/VCD from real-Ibex campaigns, and formal engine traces are **not** committed. Regenerate them with the commands below when needed.

## M4 selected dumps (included)

| File | Role |
|------|------|
| `results/m4/waveforms/m4_sp08_rst_a_counterexample.vcd` | RST-A related trace |
| `results/m4/waveforms/m4_r03_c*.fst` | security-config-last directed cases |
| `results/m4/waveforms/m4_r16_c*.fst` | secure-ready deassert |
| `results/m4/waveforms/m4_r09_c1_reset_during_auth_dma.fst` | reset during authorized DMA |
| `results/m4/waveforms/m4_r07_c0_iopmp_disable_bypass.fst` | IOPMP disable/bypass |
| `results/m4/waveforms/m4_r11_c1_pending_write_reset.fst` | pending write vs reset |

SHA-256 of included waveform files is in `results/FROZEN_EVIDENCE_MANIFEST.sha256` when those paths are listed.

## Regeneration

From repository root (Tier 2 / M4 flow):

```bash
make m4-waveforms
```

Expected directory: `results/m4/waveforms/`.

Real-Ibex campaigns do not archive full FSTs in Git. Use the corresponding `make m7-ibex-*` targets and the simulator flags documented in `scripts/run/` / `scripts/analysis/` if a waveform is required for debug.
