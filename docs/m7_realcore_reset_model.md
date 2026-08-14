# M7 real-core reset model (Phase C)

## Mapping from abstract RST-A / RST-B

This document maps the **existing** project RST-A/RST-B semantics onto the
real-Ibex composed system. It does **not** redefine either model.

Source of truth for defaults: `rtl/soc/security_config.v` and
`docs/m510_reset_model_comparison.md`.

| | RST-A (fail-open) | RST-B (fail-closed) |
|--|-------------------|---------------------|
| Compile define | (none) | `-DRST_B` |
| `iopmp_enable` at reset | `0` (bypass) | `1` (enforce) |
| `rule0_valid` at reset | `0` | `0` |
| Early unauthorized DMA before config valid | reachable via IOPMP bypass | denied (`!rule0_valid` ⇒ no match) |
| Classification if early write observed | `RESET_ASSUMPTION_DEPENDENCY` | unexpected → investigate |

`dma_allowed` in `rtl/iopmp/iopmp.v`:

- `!enable` → allow (RST-A fail-open)
- `enable && !rule0_valid` for protected region → deny (RST-B fail-closed)

## Real-Ibex composition

```
real Ibex (internal PMP)
  → m7_ibex_data_adapter
  → m7_research_arbiter  ←── IOPMP ←── dma_master
         │
    normal / protected SRAM (MEM-RET: array not cleared on domain reset)
```

No research `pmp.v` on the CPU path.

## Reset domains (Phase C)

| Signal | Resets |
|--------|--------|
| `cpu_reset_n` | Ibex core only (boot RAM/bus/timer/sim stay on cold `rst_ni`) |
| `dma_reset_n` | `dma_master` |
| `iopmp_reset_n` | `iopmp` |
| `security_config_reset_n` | `security_config` (RST-A/B defaults) |
| `interconnect_reset_n` | `m7_research_arbiter` + data adapter |
| `protected_memory_reset_n` | held **1** in primary experiments (MEM-RET) |

**Harness note:** Ibex is released with the interconnect for recovery tests.
Holding the core in reset for a long time after the boot fabric is live, then
releasing mid-simulation, produced a spurious early exception loop in this
Verilator integration; early-DMA tests still keep the CPU held (no boot required).


## MEM-RET

Protected SRAM **contents are retained** across CPU/DMA/IOPMP/security/interconnect
reset. The `sram` RTL does not clear `mem[]` on `rst_n`. Primary experiments
hold `protected_memory_reset_n=1` and use sentinel `0x5151A5A5`.

## secure_ready (real-core)

Hardware `security_config.secure_ready = pmp_enable && iopmp_enable && rule0_valid`
(research bit `pmp_enable` defaults to 1).

**Real-core system readiness** used by Phase C observability:

```
sys_secure_ready =
    firmware_pmp_ready   // mailbox PMP_READY — not an Ibex HW pin
 && iopmp_enable
 && rule0_valid
 && interconnect_reset_n
```

`PMP_READY` is a **firmware milestone** after CSR PMP programming, not an
architectural Ibex output.

## Trusted configuration

IOPMP rule programming remains harness `TRUSTED_CONFIGURATION` (sideband
`cfg_write`), same as Phase B. Not firmware MMIO.

## Partial reset experiments

- **CPU-only reset:** IOPMP/security stay configured → unauthorized DMA still denied.
- **IOPMP/security reset (RST-A):** fail-open may reappear while CPU stays up.
- **IOPMP/security reset (RST-B):** fail-closed defaults restore deny-until-valid.
