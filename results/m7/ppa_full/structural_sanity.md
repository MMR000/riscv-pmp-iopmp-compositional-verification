# M7 J0–J3 structural sanity (SKY130HD / Yosys slang)

Observations from pre-flatten `read_slang --keep-hierarchy` plus ORFS synth statistics.
Memory arrays are handshake-only (`m7_ppa_mem_slave`); no SRAM storage compiled.

## Common

- Frontend: `SYNTH_HDL_FRONTEND=slang`, `-D SYNTHESIS`
- Ibex pin `c61e11c1e416b9ce2d996013b444c8e558d35b2b`
- Live observation outputs on every top: `instr_req_o`, `instr_addr_o`, `data_req_o`, `data_we_o`, `data_addr_o`, `data_err_o`, `core_sleep_o`
- Without those ports, J0 synthesized to 13 cells (CPU optimized away). After the ports, J0 is 15267 synth cells.

## J0 (PMPEnable=0)

- Hierarchy includes `ibex_top` → `ibex_core` (IF/ID/EX/LSU/CSRs/regfile FF) + `bus` + `timer` + mem shells
- `ibex_pmp` **not** instantiated (`g_pmp` generate off)
- No `dma_master`, `iopmp`, `m7_research_arbiter`, `security_config`, `m7_ppa_domain_reset`
- Synth: 15267 cells, 2110 sequential, area 136479.6 µm²

## J1 (PMPEnable=1, 8 regions)

- `ibex_pmp` **present**: `m7_ppa_j1_top.u.u_ibex.u_ibex_core.g_pmp.pmp_i`
- Same non-PMP Ibex parameters as J0
- No DMA/IOPMP composition
- Synth: 25220 cells, 2420 sequential, area 209766.2 µm²
- Physical: detailed place completed; global route **failed** (GRT-0232 congestion)

## J2 (composition, RST-A)

- Present: `dma_master`, `iopmp` (~979 pre-map cells in slang stat), `security_config`, `m7_research_arbiter`, `m7_ibex_data_adapter`
- Policy/transaction inputs retained: `cfg_*`, `dma_*`
- `INCLUDE_DOMAIN_RESET=0` (flat `rst_n`)
- Synth: 28594 cells, 2882 sequential, area 242463.8 µm²
- Physical: GDS generated, DRC 0, **setup timing fail** at 10 ns (WNS −1.278 ns)

## J3 (RST-B + domain reset)

- Same composition as J2 plus `m7_ppa_domain_reset` (`INCLUDE_DOMAIN_RESET=1`)
- `VERILOG_DEFINES=-D RST_B` confirmed in Make (`iopmp_enable` fail-closed reset default)
- Synth: 28130 cells, 2887 sequential, area 242662.7 µm²
- Physical: global route **failed** (GRT-0116 congestion); CTS WNS −1.754 ns

## J4

`NOT_APPLICABLE_TO_REALCORE_TOP` — FIX-2 not added to J3.
