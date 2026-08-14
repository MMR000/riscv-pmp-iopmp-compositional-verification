# M5 — External IOPMP validation

M5 validates M4 reset-default conclusions against external IOPMP implementations without modifying the frozen M4-IOPMP model.

## Terminology

| Name | Object |
|------|--------|
| **M4-IOPMP** | Frozen simplified research RTL (M1–M4) |
| **REF-IOPMP** | Official RISC-V IOPMP v0.8.2 reference model |
| **RTL-IOPMP** | Independent zero-day-labs SystemVerilog implementation |

## Layout

```
m5/
├── adapters/          # Native-semantics adapters (do not patch upstream)
├── tests/             # REF campaign + single-transaction checker
├── analysis/          # Differential campaign generator
└── README.md
```

## Harness concept: `m5_secure_ready`

Not an architectural IOPMP signal. See `docs/m5_hypotheses.md`.

## Mapping REF-C0/C1 to M4 probe

| REF config | M4 probe equivalent |
|------------|---------------------|
| REF-C0 (`enable=0`) | `M5_IOPMP_ENABLE=0` (bypass), not M4 C0 reset-default alone |
| REF-C1 (`enable=1`) | `M4_CONFIG=C1`, `M5_IOPMP_ENABLE=1` |

## Build targets

From repository root:

```bash
make m5-ref-build    # build REF-IOPMP + adapter
make m5-ref-tests    # upstream tests + REF-M1 campaign
make m5-differential # 1000-seed M4 vs REF matrix
make m5              # M5A complete
```
