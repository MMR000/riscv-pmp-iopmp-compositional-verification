# Compositional invariants (M3.5)

## CI-RESET-01 — DMA accept requires enforcing IOPMP

**Statement (evidence-supported):**

> No DMA transaction may cause an authorized protected-memory write before `secure_ready` unless IOPMP is actively enforcing policy with a valid rule configuration.

Equivalently for reset analysis:

```text
DMA protected-memory commit  →  secure_ready  ∨  IOPMP deny (fail-closed default)
```

### RST-A (fail-open)

- Reset default: `iopmp_enable = 0` → IOPMP `enable=0` bypasses in-region filtering.
- **Formal result:** SP-08 **COUNTEREXAMPLE** (`RESET_ASSUMPTION_DEPENDENCY`).
- Counterexample preserved: `results/formal/counterexamples/SP-08/`.

### RST-B (fail-closed)

- Reset default: `iopmp_enable = 1`, `rule0_valid = 0` → in-region DMA denied until trusted init.
- **Formal result (M3.5):** SP-08 RST-B **BOUNDED_PASS** @ BMC depth 32.
- **Formal result (M4):** SP-08 RST-B **PROVED** via k-induction (`sp08_rstb_prove`).

### CI-RESET-01A — Admission invariant (M4)

> Protected-region DMA admission implies an enforcing security state (`secure_ready` or equivalent fail-closed/IOPMP deny path).

```text
protected_dma_admit → security_enforcing
```

### CI-RESET-01B — Commit invariant (M4, conditional)

> Only required when strict SP-12 is mandated beyond Model A SP-09 semantics. Not required for reset/recovery alone when IOPMP reset clears pending state.

```text
protected_dma_commit → security_context_valid
```

### Required assumptions

- FA-01: trusted configuration after reset (when evaluating post-init behavior).
- FA-07: documented reset sequencing / warmup.
- Per-domain reset release may be nondeterministic within harness constraints.

### Notes

This invariant describes **composition and initialization ordering**, not a runtime vulnerability under Model A normal operation (M2 PASS).
