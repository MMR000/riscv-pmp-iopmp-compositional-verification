# Formal model (M3)

## Architecture

The formal harness reuses production RTL modules:

- `pmp.v`, `iopmp.v`, `bus_interconnect`, `security_config.v`, `sram.v`

Masters are **nondeterministic** request/address/data inputs in `formal/harness/*_tb.v` rather than `cpu_master`/`dma_master`. This abstracts traffic generation while keeping security-control logic identical to M2 simulation.

## Abstractions

| Element | Abstraction | Documented in |
|---------|-------------|---------------|
| CPU/DMA masters | Nondeterministic `req/addr/write/data/rid` | FA-02, FA-04 |
| Normal SRAM | Present but not property-critical in integration harness | FA-08 |
| Protected SRAM | 256-word depth (vs 16384 sim) | FA-08 |
| Bus timing | `formal_bus_stub` grants/valid same cycle | FA-07 |
| Configuration | MMIO writes disabled in baseline (`assume !cfg_write`) | FA-01 |
| Reset | Global `rst_n` + optional per-domain in `formal_reset_tb` | SP-08 |

## Verification strategy

1. **Unit**: PMP (SP-02), IOPMP (SP-04–SP-09)
2. **Integration**: compositional harness (SP-10)
3. **Model B contrast**: SP-B01 (expected difference from Model A)
4. **Reset**: RST-A fail-open defaults (SP-08)

Engine: SymbiYosys `smtbmc z3`, bounded depth 16–32. Unbounded `prove` not yet attempted (Boolector unavailable).

## Observability

`secure_ready = pmp_enable && iopmp_enable && rule0_valid` exported from `security_config` for reset experiments (research signal, does not gate traffic in baseline).
