# Upstream issue draft (DO NOT PUBLISH)

## Title
IOPMP AXI data abstractor: unauthorized write data can reach initiator after prior allowed write

## Commit
a029581351aaf8a71831916aa8877895364e6e98

## Summary
When IOPMP denies a write (`allow_transaction=0`), write data can still reach the initiator
port if a prior transaction in the same session routed AW/W to the initiator. AR/AW channels
are gated during verification but W is not, exposing `axi_demux` W-route FIFO to stale routes.

## Configuration
- NUMBER_MASTERS=2, NUMBER_MDS=16, NUMBER_ENTRIES=32
- SRCMD programmed for NSAID/RRID 0 only; enable=1; NA4/TOR entry at 0x2000_0000

## Steps
1. Authorized AXI write (NSAID=0) → OKAY, memory updates
2. Unauthorized AXI write (NSAID=1, same addr) → OKAY, memory updates (should SLVERR)
3. Unauthorized AXI read (NSAID=1) → SLVERR (correct)

## Logs
See attached `M55-WRITE-CE-BASELINE.txt` — `allow=0`, `ip_mst_w_seen=1`, `mem_eff=1`

## Waveform
`M55-WRITE-CE-BASELINE.vcd`

## Possible root cause
Asymmetric AW vs W gating in `rv_iopmp_data_abstractor_axi.sv` combined with demux W FIFO.

## Status
Unknown upstream — not searched on GitHub issues API in this milestone.
