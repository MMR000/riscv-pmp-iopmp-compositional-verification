# M7 reset architecture (Phase B)

## Motivation

M4–M6 used a global `rst_n` with conceptual RST-A/RST-B defaults. M7 adds **independently controllable release** of protection-related domains for latency measurement and journal-grade reset sequencing.

## Domain mapping (research RTL)

| M7 signal | Maps to | Effect in `m7_reset_top` |
|-----------|---------|---------------------------|
| `mem_rst_n` | Global memory / top | Gates `soc_top.rst_n` |
| `cpu_rst_n` | CPU master | Gates `cpu_start` |
| `dma_rst_n` | DMA master | Gates `dma_start` |
| `sec_rst_n` | Security config | Gates `cfg_write` |
| `iopmp_rst_n` | IOPMP path | Reserved (transaction gating via master resets) |
| `ic_rst_n` | Interconnect | Reserved in current wrapper |

RTL: `rtl/soc/m7_reset_top.v` wraps `soc_top.v`.

## Timestamps / metrics (simulation)

Recorded in `results/tables/m7_reset_matrix.csv`:

- `t_reset_assert`, `t_secure_ready`, `t_dma_enable`, `t_first_dma_accept`
- Derived: `protection_init_latency`, `secure_ready_latency`

## RST-A / RST-B preservation

| Config | Define | Default behavior |
|--------|--------|------------------|
| RST-A | (none) | fail-open IOPMP at reset |
| RST-B | `-DRST_B` | fail-closed rule invalid |

Sequences R1, R2, R10, R11 + randomized legal orderings (32 seeds per config in default M7 run).

**Classification discipline:** RST-A reachable unsafe state → `RESET_ASSUMPTION_DEPENDENCY`, not vulnerability.

## Formal harness reference

Independent per-domain resets also modeled in `formal/harness/formal_reset_tb.v` (M5.10 SP-08).
