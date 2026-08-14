// M7 composed Ibex + DMA memory map (Phase B).
// Documented in docs/m7_ibex_composed_architecture.md
`ifndef M7_COMPOSED_MAP_VH
`define M7_COMPOSED_MAP_VH

// Ibex local subsystem (instruction fetch + boot/data during M-mode setup)
`define M7_IBEX_RAM_BASE        32'h0010_0000
`define M7_IBEX_RAM_MASK        32'hFFF0_0000  // 1 MiB (matches simple_system)

`define M7_SIM_CTRL_BASE        32'h0002_0000
`define M7_SIM_CTRL_MASK        32'hFFFF_FC00

`define M7_TIMER_BASE           32'h0003_0000
`define M7_TIMER_MASK           32'hFFFF_FC00

// Research shared memory map (bus_pkg.vh compatible)
`define M7_NORMAL_SRAM_BASE     32'h1000_0000
`define M7_NORMAL_SRAM_LIMIT    32'h1000_FFFF
`define M7_PROTECT_SRAM_BASE    32'h2000_0000
`define M7_PROTECT_SRAM_LIMIT   32'h2000_FFFF
`define M7_DMA_REGS_BASE        32'h3000_0000
`define M7_SEC_CFG_BASE         32'h4000_0000
`define M7_TEST_SYNC_BASE       32'h5000_0000
`define M7_TEST_SYNC_LIMIT      32'h5000_0FFF

// Test word offsets within shared SRAM banks
`define M7_NORMAL_TEST_OFF      32'h0000_0100
`define M7_PROTECT_TEST_OFF     32'h0000_0100

`define M7_AUTH_RID             8'h01
`define M7_UNAUTH_RID           8'h02

`define M7_CPU_VAL_CPU          32'hCAFE0007
`define M7_DMA_VAL_AUTH         32'hD00D0007
`define M7_DMA_VAL_UNAUTH        32'hBAD00007

`endif
