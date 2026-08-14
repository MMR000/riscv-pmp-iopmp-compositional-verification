# M5 — RTL-IOPMP integration (M5B complete)

## Status: FUNCTIONAL

| Item | Status |
|------|--------|
| AXI adapter | `m5/adapters/rtl_iopmp_adapter.sv` |
| Memory model | `m5/adapters/axi_simple_mem.sv` |
| DUT wrapper | `m5/adapters/rtl_iopmp_dut_wrapper.sv` (upstream RTL unmodified) |
| Simulator | Verilator 5.050 `--timing` |
| Lint | PASS (upstream Makefile) |
| Directed tests | PASS (`results/m5/rtl/rtl_results.csv`) |

## Build / run

```bash
make m5-rtl-build
make m5-rtl-directed
make m5-rtl-random   # 500-transaction campaign
```

## Known harness findings

- Unauthorized **write** with unmapped NSAID=1 observed ALLOW while unauthorized **read** DENY — documented in three-way comparison; not classified as vulnerability.
- SRCMD MD index encoding: MDn requires bit (n+1) set in SRCMD_EN register.
