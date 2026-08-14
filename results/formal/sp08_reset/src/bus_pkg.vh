// Shared bus and memory-map constants for the research testbed.
// Do not change silently; update docs/architecture.md when modified.

`ifndef BUS_PKG_VH
`define BUS_PKG_VH

// Fixed memory map (Phase 1)
`define ADDR_NORMAL_SRAM_BASE   32'h1000_0000
`define ADDR_NORMAL_SRAM_LIMIT  32'h1000_FFFF
`define ADDR_PROTECT_SRAM_BASE  32'h2000_0000
`define ADDR_PROTECT_SRAM_LIMIT 32'h2000_FFFF
`define ADDR_DMA_REGS_BASE      32'h3000_0000
`define ADDR_DMA_REGS_LIMIT     32'h3000_0FFF
`define ADDR_SEC_CFG_BASE       32'h4000_0000
`define ADDR_SEC_CFG_LIMIT      32'h4000_0FFF

`define DATA_WIDTH 32
`define ADDR_WIDTH 32

`endif
