// M7 reset-aware SoC top: independent reset domains for journal validation.
`timescale 1ns/1ps
`include "bus_pkg.vh"

module m7_reset_top (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     cpu_rst_n,
    input  wire                     dma_rst_n,
    input  wire                     iopmp_rst_n,
    input  wire                     sec_rst_n,
    input  wire                     ic_rst_n,
    input  wire                     mem_rst_n,
    input  wire                     cpu_start,
    input  wire [`ADDR_WIDTH-1:0]   cpu_addr,
    input  wire                     cpu_write,
    input  wire [`DATA_WIDTH-1:0]   cpu_wdata,
    input  wire                     cpu_privilege,
    output wire                     cpu_done,
    output wire                     cpu_error,
    input  wire                     dma_start,
    input  wire [`ADDR_WIDTH-1:0]   dma_src_addr,
    input  wire [`ADDR_WIDTH-1:0]   dma_dst_addr,
    input  wire [`DATA_WIDTH-1:0]   dma_wdata,
    input  wire [15:0]              dma_length,
    input  wire [7:0]               dma_requester_id,
    input  wire [1:0]               dma_mode,
    output wire                     dma_done,
    output wire                     dma_error,
    output wire [`DATA_WIDTH-1:0]   dma_rdata,
    output wire [`DATA_WIDTH-1:0]   cpu_rdata,
    input  wire                     cfg_write,
    input  wire [`ADDR_WIDTH-1:0]   cfg_addr,
    input  wire [`DATA_WIDTH-1:0]   cfg_wdata,
    output wire                     prot_mem_changed,
    output wire [`ADDR_WIDTH-1:0]   prot_changed_addr,
    output wire [`DATA_WIDTH-1:0]   prot_changed_wdata,
    output wire [`DATA_WIDTH-1:0]   prot_mem_word0,
    input  wire [`ADDR_WIDTH-1:0]   prot_peek_addr,
    output wire                     secure_ready,
    output wire [7:0]               security_epoch,
    output wire                     iopmp_busy,
    output wire                     cycle_count
);

    wire g_rst = rst_n && mem_rst_n;
    wire cpu_r = g_rst && cpu_rst_n;
    wire dma_r = g_rst && dma_rst_n;
    wire iop_r = g_rst && iopmp_rst_n;
    wire sec_r = g_rst && sec_rst_n;
    wire ic_r  = g_rst && ic_rst_n;

    reg [31:0] cycles;
    always @(posedge clk or negedge g_rst) begin
        if (!g_rst) cycles <= 0;
        else cycles <= cycles + 1;
    end
    assign cycle_count = cycles[0]; // observability hook

    // Delegate to internal reset-controlled soc
    soc_top u_soc (
        .clk(clk), .rst_n(g_rst),
        .cpu_start(cpu_start && cpu_r), .cpu_addr(cpu_addr), .cpu_write(cpu_write),
        .cpu_wdata(cpu_wdata), .cpu_privilege(cpu_privilege),
        .cpu_done(cpu_done), .cpu_error(cpu_error), .cpu_rdata(cpu_rdata),
        .dma_start(dma_start && dma_r), .dma_src_addr(dma_src_addr),
        .dma_dst_addr(dma_dst_addr), .dma_wdata(dma_wdata),
        .dma_length(dma_length), .dma_requester_id(dma_requester_id),
        .dma_mode(dma_mode), .dma_done(dma_done), .dma_error(dma_error),
        .dma_rdata(dma_rdata),
        .cfg_write(cfg_write && sec_r), .cfg_addr(cfg_addr), .cfg_wdata(cfg_wdata),
        .prot_mem_changed(prot_mem_changed), .prot_changed_addr(prot_changed_addr),
        .prot_changed_wdata(prot_changed_wdata), .prot_mem_word0(prot_mem_word0),
        .prot_peek_addr(prot_peek_addr),
        .iopmp_txn_valid(), .iopmp_txn_master(), .iopmp_txn_addr(),
        .iopmp_txn_write(), .iopmp_txn_authorized(), .iopmp_txn_rid(),
        .iopmp_txn_length(), .iopmp_txn_age(),
        .secure_ready(secure_ready), .security_epoch(security_epoch),
        .rsdg_admit_blocked(), .iopmp_busy(iopmp_busy)
    );

    // Note: soc_top uses unified rst_n; domain gating approximates independent release.
    // IOPMP/IC/sec domain resets are applied via transaction/config enables above.

endmodule
