# M7 PPA memory policy

## Policy name

**LOGIC-ONLY / MEMORY-BLACKBOX**

## Included in comparative logic PPA

- Real pinned Ibex core (`ibex_top`, internal architectural PMP when enabled)
- `m7_ibex_data_adapter` (composition path)
- `dma_master`
- Research `iopmp` (`rtl/iopmp/iopmp.v`)
- `m7_research_arbiter`
- `security_config` (RST-A / RST-B via `RST_B` macro)
- `m7_ppa_domain_reset` (J3 independent domain release coordination)
- `timer` (minimal peripheral retained for realistic bus decode)
- `bus` interconnect decode (Ibex boot path)

## Excluded from reported logic overhead

- Instruction/data RAM arrays (`ram_2p`, behavioral `sram` storage)
- Protected/normal SRAM storage arrays
- Simulation-only peripherals: `simulator_ctrl`, `m7_test_sync`, harnesses, event monitors, target delay
- Cocotb / Verilator DPI / trace / `$finish` support

## Implementation

`m7_ppa_mem_slave` provides handshake-only memory interface shells at subsystem boundaries. No `reg [...] mem[...]` arrays are synthesized for PPA variants.

> Memory arrays and simulation-only peripherals are excluded from the comparative logic PPA results.

## Reporting rule

Area/cell metrics compare **standard-cell logic** mapped through the physical flow. Blackboxed memory interfaces are not counted as security-logic overhead.
