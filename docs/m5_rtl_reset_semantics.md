# M5 — RTL-IOPMP reset semantics

## Observed RTL behavior (Verilator harness)

| State after reset release | Value / effect |
|---------------------------|----------------|
| `HWCFG0.enable` | **0** (checking bypassed) |
| IOPMP entries | Cleared (BRAM reset) |
| SRCMD / MDCFG | Cleared |
| Pre-config protected write | **ALLOW** (memory modified, AXI OKAY) |
| After `enable=1`, no policy | **DENY** (SLVERR, no memory effect) |
| After policy + `enable=1` | Authorized ALLOW / unauthorized read DENY |
| Reset after configuration | `enable` → 0 again → **bypass** (RTL-RST-03) |

## Native classification

| Phase | M5 class |
|-------|----------|
| Reset, enable=0 | **RTL-DEFAULT-BYPASS** |
| enable=1, no entry | **RTL-DEFAULT-DENY** |
| Configured authorized | **RTL-AUTHORIZED** |

## Documented upstream intent

README describes mandatory draft5 features; reset default for `enable` not prominently documented separately from register RESVAL.

## Spec interpretation

Draft5 RTL uses **enable=0 at reset** (fail-open bypass), unlike REF-IOPMP v0.8.2 adapter default **enable=1** (fail-closed). Classified as **SPEC_REVISION_DIFFERENCE** / implementation configuration difference.

## Security implication

SoC must **explicitly set `HWCFG0.enable=1`** before relying on IOPMP enforcement. Reset alone does not provide deny-by-default on RTL-IOPMP.
