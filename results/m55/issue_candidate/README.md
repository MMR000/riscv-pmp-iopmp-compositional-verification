# M5.5 issue candidate — W-channel / write routing defect

## Summary
Unauthorized writes can modify protected memory after a prior authorized write in the same
session, while matching logic returns `allow_transaction=0`.

## Upstream
- Repo: zero-day-labs/riscv-iopmp
- Commit: a029581351aaf8a71831916aa8877895364e6e98

## Minimal reproduction
1. Reset, program policy for NSAID=0 only, enable IOPMP
2. Authorized write NSAID=0 to 0x2000_0000 → ALLOW
3. Unauthorized write NSAID=1 same address → ALLOW (memory modified, BRESP OKAY)
4. Unauthorized read NSAID=1 → DENY

Run: `make m55-baseline`

## Expected
Step 3 denied (SLVERR, no memory change), symmetric with step 4.

## Observed
Step 3 ALLOW; matching `allow=0`, `has_md=0`; initiator W (and AW) observed.

## Evidence
- `results/m55/baseline/M55-WRITE-CE-BASELINE.txt`
- `results/m55/baseline/M55-WRITE-CE-BASELINE.vcd`
- `results/tables/m55_nsaid_matrix.csv` (NSAID=1 symmetric DENY with per-NSAID reset)

## Source trace
- `rv_iopmp_data_abstractor_axi.sv:129` — W always forwarded to demux
- `rv_iopmp_data_abstractor_axi.sv:113` — AW gated to AXI_HANDSHAKE only (asymmetric)
- `vendor/axi_demux.sv` — W routing via `w_select` FIFO from prior AW

## Proposed fix (local patch, not validated)
`patches/zero-day-iopmp/w_channel_gate.patch` — naive W gate causes B-channel timeout on
denied transactions; needs staged W buffering aligned with AW route decision.

## Classification
RTL_IMPLEMENTATION_DEFECT (access-control implementation bug; not rated as exploitable
vulnerability without system context).
