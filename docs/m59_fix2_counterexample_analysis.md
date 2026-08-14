# M5.9 FIX-2 Formal Counterexample Analysis

## Source trace

`results/formal/m58/m58_proper_bmc64/engine_0/trace.vcd` (M5.8 ENV-0, step 5)

## Compact trace table (M5.8 baseline)

| Cycle | rst_n | src AWVALID | src WVALID | AW hs | W hs | ini W hs | grant_allow | route_sel | txn_active | FSM | Notes |
|-------|-------|-------------|------------|-------|------|----------|-------------|-----------|------------|-----|-------|
| 0–4 | 0→1 | 0 | 0 | 0 | 0 | 0 | *anyinit* | *anyinit=1* | *anyinit=0* | *anyinit=1* | No cycle stimulus in witness |
| 5 | 1 | 0 | 0 | 0 | 0 | **1** | 0 | 1 | 0 | 001 | **Assert fail** — mem_write without w_context_ok |

## Key observations (no interpretation in trace section)

1. Witness contains **80+ `anyinit_driver_*`** assignments on DUT/harness registers at time 0.
2. **No AWVALID/WVALID** assignments in per-cycle stimulus (trace_tb.v cycles empty).
3. `formal_reset_phase` / reset counter were **anyinit-corrupted** in M5.8 (value 11 at t=0).
4. Internal **axi_demux W FIFO** preloaded (status_cnt≠0, mem entries all 1).
5. `route_select_q=1`, `write_aw_done_q=1`, `state_q≠IDLE` before any master transaction.
6. Violation is **ini_w_hs** with `grant_allow=0` — not a master-presented AW/W sequence.

## M5.9 follow-up (derived rst_n + ENV-4)

After M5.9 harness fixes, CE moves to **step 10**. Decoded proper ENV-4 trace:

| Cycle | src AW/W | AW hs | ini W hs | route_sel | grant_allow | txn_active | txn_auth |
|-------|----------|-------|----------|-----------|-------------|------------|----------|
| 0–9 | 0/0 | 0 | 0→1 pulse | 0→1 | 0 | 0→1 | 0 |

Secondary assert (denied + mem_write) fires when `txn_active=1`, `!txn_authorized`, brief `ini_w_hs` — still **without sustained master AW/W**.

## Preliminary classification

**PROTOCOL_ILLEGAL_COUNTEREXAMPLE** / **HARNESS_ARTIFACT** — dominated by Yosys `anyinit`, not a master-legal AXI write sequence.
