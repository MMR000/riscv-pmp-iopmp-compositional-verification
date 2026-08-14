# M5 — M4-IOPMP vs REF-IOPMP specification alignment

Machine-readable matrix: `docs/m5_spec_alignment.csv`  
Summary table: `results/tables/m5_spec_alignment.csv`

## Key findings

### Default checking (`enable`)

- **REF-IOPMP:** `HWCFG0.enable=0` bypasses all checks; `enable=1` enforces table lookup.
- **M4-IOPMP:** Separate knobs — `iopmp_enable` (SoC bypass) and `RST_B` (fail-open vs fail-closed reset defaults inside IOPMP when enabled).
- **Equivalence:** Qualitative C0/C1 distinction exists in both, but **not isomorphic**. REF-C0 ≈ M4 with `iopmp_enable=0`, not M4 C0 with IOPMP in-path.

### Requester ID

- M4: single 8-bit `dma_requester_id` matched against rule0.
- REF: SRCMD tables per RRID (up to 64 in full_model config).
- M5 adapter maps AUTH=1, UNAUTH=2.

### Memory domain

- M4: implicit single protected region.
- REF: explicit MD/SRCMD association.
- Classified as **ABSTRACTION_DIFFERENCE**; no security claim transfer without adapter policy.

### Partial match / transaction length

- M4: end-address check against rule limit.
- REF: granularity, NA4/TOR/NAPOT, transaction size fields.
- M5 range spot checks show same ALLOW/DENY for exact-hit and wrong-RRID cases; cross-boundary campaign deferred to differential sampling.

### Reset / configuration lifecycle

- Neither M4 harness nor REF adapter models full SoC reset sequencing.
- `m5_secure_ready` is harness-only (see `docs/m5_hypotheses.md`).

## External validation gate (M5A)

**Result A (partial):** REF-IOPMP supports qualitative C0/C1 `enable` distinction. Proceed to RTL-IOPMP characterization with version-gap documentation.
