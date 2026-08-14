# M5.8 Formal Properties — M57-FP-04

## Informal statement

A master-side W beat must only occur when the IOPMP grant observer records an authorized decision for the current transaction.

## RTL signals

| Signal | Definition |
|--------|------------|
| `mem_write_event` | `mst_req.w_valid && mst_rsp.w_ready` |
| `grant_allow` | latched `iopmp_allow` at IOPMP valid |
| `grant_seq` | latched `txn_seq` at grant |
| `w_context_ok` | `grant_allow && (grant_seq == txn_seq)` in FORMAL mode |

## Property encoding (Yosys)

```systemverilog
if (formal_reset_phase >= 4 && mem_write_event && !w_context_ok) assert(0);
```

## Sanity

FIX-0 must fail: **confirmed** (`EXPECTED_PRE_FIX_COUNTEREXAMPLE`).

## FIX-2

- Verilator directed: **BOUNDED_PASS**
- SymbiYosys BMC/PDR with minimal assumptions: **COUNTEREXAMPLE** (ASSUMPTION_GAP)
