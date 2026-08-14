# M5.10 INCONCLUSIVE / Harness Issue Closure

## Closed or classified

| Issue | Prior status | M5.10 classification | Action |
|-------|--------------|------------------------|--------|
| FIX-2 M5.8 BMC CE | ASSUMPTION_GAP | **HARNESS_ARTIFACT (anyinit)** | Closed M5.9 |
| FIX-2 ENV-4 primary | INCONCLUSIVE | **BOUNDED_EVIDENCE** | Closed M5.9 |
| SP-08 RST-A CE | COUNTEREXAMPLE | **RESET_ASSUMPTION_DEPENDENCY** | Preserved, reconfirmed |
| SP-08 RST-B | BOUNDED_PASS | **FORMAL_PROOF** | Reconfirmed M5.10 |
| Yices PDR replay | blocked | **TOOLCHAIN_LIMITATION** | Optional; skipped |

## Remaining INCONCLUSIVE (documented, not mislabeled)

| Issue | Classification | Notes |
|-------|--------------|-------|
| SP-11 `sp11_rsdg_prove` PREUNSAT | **FORMAL_HARNESS_BUG** | Assumptions unsatisfiable at step 0; `dma_addr_gate` undriven warnings |
| M57-FP-04 secondary assert ENV-4 step 10 | **FORMAL_HARNESS_BUG** | Observer anyinit edge; primary property passes |
| FIX-0 primary under ENV-4 BMC ≤1024 | **INCONCLUSIVE** | Reachability depth; ENV-0 + Verilator detect defect |
| M57-FP-04 PDR FIX-2 | **TOOLCHAIN_LIMITATION** | ABC PDR fail; no yices witness |
| SP-14 recovery liveness | **NOT_RUN** | Out of M5.10 safety scope |

## Not treated as RTL defects

- RST-A DMA-before-secure_ready
- M5.8 FIX-2 anyinit counterexample
- SP-B01 model contrast CE (EXPECTED_MODEL_DIFFERENCE)
