# M5 — REF-IOPMP reference model integration

## Source

Official RISC-V IOPMP repository, tag **v0.8.2**, commit `6c5392f2ee103255a0a53a53698d423002c401cc`.

See `docs/m5_external_sources.md` for retrieval metadata.

## Build

```bash
cd third_party/riscv-iopmp-official/iopmp_ref_model
make build model=full_model
```

Environment recorded in `results/m5/reference_model/build.log`.

## Upstream verification

```bash
make run   # within iopmp_ref_model/
```

Result: **58/58 PASS** (`full_model`). Log: `results/m5/reference_model/upstream_tests.txt`.

## Adapter

`m5/adapters/ref_iopmp_adapter.{h,c}` wraps the official C API without modifying upstream sources.

- `m5_ref_create(enable_at_reset)` — reset with `HWCFG0.enable` W1SS default
- `m5_ref_install_policy()` — minimal NA4 entry + SRCMD for one RRID
- `m5_ref_check()` — single transaction via `receiver_port` + `iopmp_validate_access`

## Central `enable` semantics (experimental)

| Config | `HWCFG0.enable` | Pre-config protected write | Post-config auth | Post-config unauth RRID |
|--------|-----------------|----------------------------|------------------|-------------------------|
| REF-C0 | 0 | **ALLOW** (bypass) | ALLOW (bypass) | ALLOW (bypass) |
| REF-C1 | 1 | **DENY** | ALLOW | DENY |

Implementation reference: `iopmp_validate.c` returns success immediately when `enable==0`.

## M5A experiments

Campaign binary: `m5/bin/m5_ref_campaign`

Outputs:

- `results/m5/reference_model/reference_results.csv` — REF-M1 + reset-default
- `results/m5/reference_model/range_results.csv` — boundary spot checks
