# M5 hypotheses (external validation)

These are **hypotheses**, not conclusions.

| ID | Hypothesis |
|----|------------|
| H5-01 | REF-IOPMP `HWCFG0.enable=0` corresponds qualitatively to M4-IOPMP bypass when `iopmp_enable=0` (not M4 C0 reset-default alone). **Experimental: supported with mapping.** |
| H5-02 | REF-IOPMP `HWCFG0.enable=1` at reset corresponds qualitatively to M4-IOPMP fail-closed checking (REF-C1 ≈ M4 C1). **Experimental: supported.** |
| H5-03 | With no valid authorizing entry and `enable=1`, REF-C1 denies protected-region device transactions. **Experimental: supported.** |
| H5-04 | After valid policy installation, authorized RRID transactions are permitted. **Experimental: supported.** |
| H5-05 | REF-C1 satisfies the functional intent of CI-RESET-01A under harness-defined `m5_secure_ready`. **Experimental: partially supported (C1 only).** |

## Harness-only concept: `m5_secure_ready`

Not an architectural IOPMP signal. Defined as:

```text
m5_secure_ready =
    IOPMP HWCFG0.enable == 1
    AND required SRCMD/MDCFG/entry tables initialized
    AND authorizing entry valid for the target RRID/address
```

M4 `secure_ready` is **not** imported into REF-IOPMP unless explicitly modeled by the adapter/harness.
