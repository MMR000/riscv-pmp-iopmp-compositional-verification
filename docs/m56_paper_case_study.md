# M5.6 paper case study evidence (structured)

## A. Defect mechanism

- Matching logic returns correct DENY (`allow=0`)
- W channel reaches initiator via stale `axi_demux` W-route FIFO

## B. Minimal trigger

Authorized write → denied write (same session, no reset)

## C. Root cause

AW authorization route and W route not transaction-bound in original RTL

## D. Repair principle

Latch route decision at IOPMP valid; phase AW then W; gate W to HANDSHAKE; WAIT_B before IDLE

## E. Before/after comparison

| Configuration | R3 unauth memory effect | Denied B completes |
|---------------|-------------------------|-------------------|
| Original (FIX-0) | Yes | Yes (incorrect ALLOW) |
| Naive W-gate (FIX-1) | Reduced | B timeout risk |
| Proper binding (FIX-2) | No | SLVERR |

See `results/tables/m56_fix_comparison.csv`

## F. Formalized properties

WP-01..WP-12, F-WP-01..F-WP-09 — see `docs/m56_write_path_contract.md`

## G. Quantitative cost

See `results/tables/m56_latency.csv`

## H. Limitations

- Single-outstanding FSM scope
- Simulation-first evidence on Verilator harness
- Formal: abstract binder model (M56-FA-08)
- No Ibex/FPGA/PPA

## Terminology

Use: implementation defect, write-path enforcement defect, authorization/data-path inconsistency, AXI transaction-binding defect

Avoid: zero-day, exploit, CVE (until external validation)
