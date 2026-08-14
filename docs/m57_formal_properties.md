# M5.7 formal properties

| ID | Statement |
|----|-----------|
| M57-FP-01 | Denied transaction: no initiator AW handshake |
| M57-FP-02 | Denied transaction: no initiator W handshake |
| M57-FP-03 | Denied transaction: no abstract memory write |
| M57-FP-04 | Initiator W handshake → active authorized write context |
| M57-FP-05 | Initiator W uses route of current authorized transaction |
| M57-FP-06 | Completed transaction clears route state |
| M57-FP-07 | Authorized write can reach initiator (cover) |
| M57-FP-08 | Denied transaction completes with error B (bounded liveness) |
| M57-FP-09 | Authorized transaction completes with OKAY B (bounded liveness) |
| M57-FP-10 | After completion, no stale route active at IDLE |
| M57-FP-11 | W-before-AW cannot bypass authorization |
| M57-FP-12 | AW-before-W cannot bypass authorization |
| M57-FP-13 | Backpressure cannot convert DENY into initiator write |
| M57-FP-14 | Prior ALLOW cannot cause following DENY to reuse route |
| M57-FP-15 | Memory write event → authorized write context |

Implemented in `formal/harness/formal_m57_fullrtl_write_path_tb.sv` (subset M57-FP-01..04,06,15 + covers).
