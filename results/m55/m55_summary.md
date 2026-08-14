# M5.5 Summary

## Git
- Branch: m55-write-path-investigation
- HEAD: fd3a8761bd15b5e42ce58c63c4c3785b803e07a4
- Upstream RTL: zero-day-labs/riscv-iopmp @ a029581351aaf8a71831916aa8877895364e6e98

## Primary root cause
**RTL_IMPLEMENTATION_DEFECT** in `rv_iopmp_data_abstractor_axi`: the W beat is presented to
`axi_demux` while AW is still gated during IOPMP verification. After an authorized write routes
AW/W to the initiator, a subsequent denied write can still deliver **W to the initiator** using
the demux route FIFO from the prior transaction. Matching logic correctly returns `allow=0`.

## Original M5 anomaly reproduction
- Sequence: `install_policy(nsaid=0)` → authorized write → unauthorized write (NSAID=1)
- Observed: READ deny / WRITE allow (memory modified, BRESP OKAY)
- Baseline: `results/m55/baseline/M55-WRITE-CE-BASELINE.txt`
- Waveform: `results/m55/baseline/M55-WRITE-CE-BASELINE.vcd`

## Matching read control
- Unauthorized read (NSAID=1) **DENY** with SLVERR when probed after anomalous write
- With per-NSAID reset and no prior auth write in session: NSAID=1 READ/WRITE both **DENY**

## NSAID matrix
- Rows: 16
- Asymmetric rows (stale-session sweep artifact): 0
- Clean NSAID=1 (reset per row): READ=DENY WRITE=DENY

## EV-2 re-evaluation
**EV-2 CONFIRMED_WITH_IMPLEMENTATION_DEFECT** — reset/default enforcement findings stand; M1-03
write-ALLOW is a write-path implementation defect, not spec-compliant authorization.

## Paper impact
**ADDS_IMPLEMENTATION_CASE_STUDY** — conservative access-control defect on W-channel gating.

## Recommended next step
**B** — Formalize confirmed RTL defect (local patch in `patches/zero-day-iopmp/`).
