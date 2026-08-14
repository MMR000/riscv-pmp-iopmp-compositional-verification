# M5.9 FIX-0 Formal vs M5.6 Simulation CE Alignment

## Sources

- M5.6 RTL replay: `results/m56/before_fix/M56-BEFORE-CE.txt`
- M5.8/M5.9 FIX-0 formal: `results/formal/m59/m59_original_env0_bmc128/`

## Causal sequence comparison

| Step | M5.6 simulation | M5.8 formal (ENV-0) |
|------|-----------------|---------------------|
| 1. Authorized AW | Yes (policy allow) | Not in witness (anyinit) |
| 2. Route bound allow | Yes | route_sel anyinit=1 |
| 3. Policy deny | Yes (second txn) | grant_allow=0 anyinit |
| 4. Master W | Yes | No src W in witness |
| 5. Stale route | Yes (original RTL) | demux FIFO anyinit path |
| 6. mem_write_event | Yes | ini_w_hs from internal FIFO |

## Classification

**DIFFERENT_COUNTEREXAMPLE** at ENV-0 step 5–10 formal witness vs directed simulation.

Both demonstrate **unauthorized initiator W reaching memory-side handshake**, but formal M5.8 witness is **not cycle-equivalent** to M5.6 directed stimulus — it uses anyinit/internal state.

Verilator full-RTL harness **does** reproduce M5.6-class sequence (COUNTEREXAMPLE at 255000 ps).

## Cross-validation conclusion

Formal BMC confirms property **failability** on original RTL; simulation CE remains the **ground-truth causal trace** for the paper.
