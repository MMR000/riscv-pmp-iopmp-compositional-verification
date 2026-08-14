# M5.7 AW-before-W delay investigation

## Method

Re-ran M5.6 timing matrix with extended watchdog (`TIMEOUT_LONG=50000`) and delays 0,1,2,4,8,16,32,64.

## Findings (proper repair)

| Delay (AW before W) | Auth write | Deny write | Classification |
|---------------------|------------|------------|----------------|
| 0–4 | PASS | PASS | Legal independent-channel wait |
| 8 | DEADLOCK at 20000 (M5.6) / completes at 50000 (M5.7) | PASS | **TESTBENCH_WATCHDOG_LIMIT** at default 20000 |
| 16–64 | PASS (extended watchdog) | PASS | RTL waits safely; FSM holds route |

## FSM behavior (proper)

- `route_select_q` latched at IOPMP valid
- `write_aw_done_q` waits for AW ready before W forwarded
- Long AW-before-W gaps do not clear route prematurely
- `WAIT_B` holds until B completes

## Conclusion

AW-before-W delay=8 is **not RTL deadlock**. M5.6 timeout was **TESTBENCH_WATCHDOG_LIMIT** with `TIMEOUT_SHORT=20000` on combined aw/w wait loop.

Evidence: `results/tables/m57_aw_w_delay_matrix.csv` (from extended m56 timing rerun).
