# M5.9 Compositional Contract (evidence-based)

## Contract

Under assumptions **M59-FA-01..12** (ENV-4 minimum for FIX-2 primary closure):

```
AXI master legality (stable AW/W, single-beat, no overlap)
+ derived reset / post-reset idle
+ master quiescence ⇒ no initiator activity
+ IOPMP grant observer semantics (M58 harness)
⇒ M57-FP-04: mem_write_event → w_context_ok
```

For **proper** variant, `w_context_ok ≡ route_select` (RTL FIX-2 binding signal).

## Empirical status

| Variant | Primary M57-FP-04 BMC ENV-4 depth 512 | Verilator directed |
|---------|---------------------------------------|-------------------|
| FIX-0 original | Fail at ENV-0 step 10; ENV-4 secondary-only at ≤1024 | COUNTEREXAMPLE |
| FIX-2 proper | **BOUNDED_PASS** (primary) | BOUNDED_PASS |

**No unbounded FORMAL_PROOF** — ABC PDR failed; yices unavailable.

## Not included

- Full AXI4 burst generality
- Denied-write B-channel liveness (see M5.7 liveness note)
- SoC-wide multi-master arbitration
