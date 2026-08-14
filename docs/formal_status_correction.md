# Formal status correction (M3 → M3.5)

## Background

Milestone M3 used the label **PROVED** for SymbiYosys tasks run with:

```text
mode bmc
depth ≤ 32
solver z3
```

Under the project’s documented semantics, **PROVED** means an unbounded/complete proof without a bounded-only qualification.

Bounded model checking (BMC) success only establishes:

```text
BOUNDED_PASS
```

## Corrections applied in M3.5

| Property / task | M3 label | Corrected M3 label | M3.5 follow-up |
|-----------------|----------|--------------------|----------------|
| SP-04 (sp04_iopmp_unit) | PROVED @ depth 32 | BOUNDED_PASS | prove task attempted |
| SP-05 (with SP-04) | PROVED @ depth 32 | BOUNDED_PASS | prove task attempted |
| SP-06 (with SP-04) | PROVED @ depth 32 | BOUNDED_PASS | prove task attempted |
| SP-09 (with SP-04) | PROVED @ depth 32 | BOUNDED_PASS | prove task attempted |
| SP-02 (sp02_pmp_unit) | COUNTEREXAMPLE / INCONCLUSIVE | INCONCLUSIVE (harness) | **PROVED** (k-induction) + BOUNDED_PASS BMC |
| SP-10 (sp10_integration) | COUNTEREXAMPLE / INCONCLUSIVE | INCONCLUSIVE (harness) | **BOUNDED_PASS** (attribution fixed) |
| SP-04/05/06/09 (sp04_iopmp_unit) | PROVED @ depth 32 | BOUNDED_PASS | **PROVED** (k-induction) + BOUNDED_PASS BMC |
| SP-08 RST-A | COUNTEREXAMPLE | COUNTEREXAMPLE (unchanged) | preserved |
| SP-08 RST-B | not run | — | **BOUNDED_PASS** @ depth 32 |
| SP-B01 | INCONCLUSIVE | INCONCLUSIVE | **COUNTEREXAMPLE** (EXPECTED_MODEL_DIFFERENCE) |

Original M3 artifacts (`results/formal/m3_summary.md`, `m3_runs.csv`, `m3_guarantee_matrix.csv`) are **preserved unchanged** as the historical record.

M3.5 superseding tables live under `results/tables/m35_*` and `results/formal/m35_*`.

## Upgrade rule (M3.5 onward)

A property may be labeled **PROVED** only when a SymbiYosys `mode prove` task (or equivalent complete method) returns PASS without bounded depth qualification.
