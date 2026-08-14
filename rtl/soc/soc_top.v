// Research SoC top integrating abstract CPU/DMA masters, PMP, IOPMP, and memories.
`timescale 1ns/1ps
`include "bus_pkg.vh"

module soc_top (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     cpu_start,
    input  wire [`ADDR_WIDTH-1:0]   cpu_addr,
    input  wire                     cpu_write,
    input  wire [`DATA_WIDTH-1:0]   cpu_wdata,
    input  wire                     cpu_privilege,
    output wire                     cpu_done,
    output wire                     cpu_error,
    output wire [`DATA_WIDTH-1:0]   cpu_rdata,
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
    input  wire                     cfg_write,
    input  wire [`ADDR_WIDTH-1:0]   cfg_addr,
    input  wire [`DATA_WIDTH-1:0]   cfg_wdata,
    output wire                     prot_mem_changed,
    output wire [`ADDR_WIDTH-1:0]   prot_changed_addr,
    output wire [`DATA_WIDTH-1:0]   prot_changed_wdata,
    output wire [`DATA_WIDTH-1:0]   prot_mem_word0,
    input  wire [`ADDR_WIDTH-1:0]   prot_peek_addr,
    // IOPMP transaction observability (M2)
    output wire                     iopmp_txn_valid,
    output wire                     iopmp_txn_master,
    output wire [`ADDR_WIDTH-1:0]   iopmp_txn_addr,
    output wire                     iopmp_txn_write,
    output wire                     iopmp_txn_authorized,
    output wire [7:0]               iopmp_txn_rid,
    output wire [15:0]              iopmp_txn_length,
    output wire [3:0]               iopmp_txn_age,
    output wire                     secure_ready,
    output wire [7:0]               security_epoch,
    output wire                     rsdg_admit_blocked,
    output wire                     iopmp_busy
);

    wire cpu_req, cpu_req_write, cpu_req_privilege;
    wire [`ADDR_WIDTH-1:0] cpu_req_addr;
    wire [`DATA_WIDTH-1:0] cpu_req_wdata;
    wire cpu_gnt, cpu_valid, cpu_master_error;
    wire [`DATA_WIDTH-1:0] cpu_bus_rdata;

    wire dma_req, dma_req_write;
    wire [`ADDR_WIDTH-1:0] dma_req_addr;
    wire [`DATA_WIDTH-1:0] dma_req_wdata;
    wire [7:0] dma_req_rid;
    wire [15:0] dma_req_len;
    wire dma_gnt, dma_valid, dma_master_error;
    wire [`DATA_WIDTH-1:0] dma_bus_rdata;

    wire pmp_req, pmp_write, pmp_gnt, pmp_valid, pmp_error;
    wire [`ADDR_WIDTH-1:0] pmp_addr;
    wire [`DATA_WIDTH-1:0] pmp_wdata, pmp_rdata;

    wire iopmp_req, iopmp_write, iopmp_gnt, iopmp_valid, iopmp_error;
    wire [`ADDR_WIDTH-1:0] iopmp_addr;
    wire [`DATA_WIDTH-1:0] iopmp_wdata, iopmp_rdata;

    wire norm_req, norm_write, norm_gnt, norm_valid;
    wire [`ADDR_WIDTH-1:0] norm_addr;
    wire [`DATA_WIDTH-1:0] norm_wdata, norm_rdata;

    wire prot_req, prot_write, prot_gnt, prot_valid;
    wire [`ADDR_WIDTH-1:0] prot_addr;
    wire [`DATA_WIDTH-1:0] prot_wdata, prot_rdata;

    wire pmp_enable, iopmp_enable;
    wire [`ADDR_WIDTH-1:0] rule0_base, rule0_limit;
    wire [7:0] rule0_rid;
    wire rule0_re, rule0_we, rule0_valid;

    cpu_master u_cpu (
        .clk(clk), .rst_n(rst_n),
        .start(cpu_start), .addr(cpu_addr), .write(cpu_write),
        .wdata(cpu_wdata), .privilege(cpu_privilege),
        .req(cpu_req), .req_addr(cpu_req_addr), .req_write(cpu_req_write),
        .req_wdata(cpu_req_wdata), .req_privilege(cpu_req_privilege),
        .gnt(cpu_gnt), .valid(cpu_valid), .rdata(cpu_bus_rdata), .error(cpu_master_error),
        .done(cpu_done), .last_error(cpu_error), .last_rdata(cpu_rdata)
    );

    dma_master u_dma (
        .clk(clk), .rst_n(rst_n),
        .start(dma_start), .src_addr(dma_src_addr), .dst_addr(dma_dst_addr),
        .wdata(dma_wdata), .length(dma_length), .requester_id(dma_requester_id),
        .mode(dma_mode),
        .req(dma_req), .req_addr(dma_req_addr), .req_write(dma_req_write),
        .req_wdata(dma_req_wdata), .req_requester_id(dma_req_rid),
        .req_length(dma_req_len),
        .gnt(dma_gnt), .valid(dma_valid), .rdata(dma_bus_rdata), .error(dma_master_error),
        .done(dma_done), .last_error(dma_error), .last_rdata(dma_rdata)
    );

    wire dma_to_iopmp_req, dma_to_iopmp_write;
    wire [`ADDR_WIDTH-1:0] dma_to_iopmp_addr;
    wire [`DATA_WIDTH-1:0] dma_to_iopmp_wdata;
    wire [7:0] dma_to_iopmp_rid;
    wire [15:0] dma_to_iopmp_len;
    wire dma_from_iopmp_gnt, dma_from_iopmp_valid;
    wire [`DATA_WIDTH-1:0] dma_from_iopmp_rdata;

    security_config u_sec (
        .clk(clk), .rst_n(rst_n),
        .pmp_enable(pmp_enable), .iopmp_enable(iopmp_enable),
        .rule0_base(rule0_base), .rule0_limit(rule0_limit),
        .rule0_rid(rule0_rid), .rule0_re(rule0_re), .rule0_we(rule0_we),
        .rule0_valid(rule0_valid),
        .secure_ready(secure_ready),
        .security_epoch(security_epoch),
        .cfg_write(cfg_write), .cfg_addr(cfg_addr), .cfg_wdata(cfg_wdata)
    );

    pmp u_pmp (
        .clk(clk), .rst_n(rst_n), .enable(pmp_enable),
        .cpu_req(cpu_req), .cpu_addr(cpu_req_addr), .cpu_write(cpu_req_write),
        .cpu_wdata(cpu_req_wdata), .cpu_privilege(cpu_req_privilege),
        .cpu_gnt(cpu_gnt), .cpu_valid(cpu_valid), .cpu_rdata(cpu_bus_rdata),
        .cpu_error(cpu_master_error),
        .cpu_req_out(pmp_req), .cpu_addr_out(pmp_addr), .cpu_write_out(pmp_write),
        .cpu_wdata_out(pmp_wdata),
        .bus_gnt(pmp_gnt), .bus_valid(pmp_valid), .bus_rdata(pmp_rdata)
    );

`ifdef RSDG_ADMIT_GATE
    rsdg #(
        .ADMIT_GATE(1)
    ) u_rsdg (
        .clk(clk), .rst_n(rst_n),
        .secure_ready(secure_ready),
        .iopmp_busy(iopmp_busy),
        .dma_req_in(dma_req), .dma_addr_in(dma_req_addr),
        .dma_write_in(dma_req_write), .dma_wdata_in(dma_req_wdata),
        .dma_rid_in(dma_req_rid), .dma_length_in(dma_req_len),
        .dma_gnt_out(dma_gnt), .dma_valid_out(dma_valid),
        .dma_rdata_out(dma_bus_rdata),
        .dma_gnt_in(dma_from_iopmp_gnt), .dma_valid_in(dma_from_iopmp_valid),
        .dma_rdata_in(dma_from_iopmp_rdata),
        .dma_req_out(dma_to_iopmp_req), .dma_addr_out(dma_to_iopmp_addr),
        .dma_write_out(dma_to_iopmp_write), .dma_wdata_out(dma_to_iopmp_wdata),
        .dma_rid_out(dma_to_iopmp_rid), .dma_length_out(dma_to_iopmp_len),
        .admit_blocked(rsdg_admit_blocked), .gate_open()
    );
`else
    assign dma_to_iopmp_req    = dma_req;
    assign dma_to_iopmp_addr   = dma_req_addr;
    assign dma_to_iopmp_write  = dma_req_write;
    assign dma_to_iopmp_wdata  = dma_req_wdata;
    assign dma_to_iopmp_rid    = dma_req_rid;
    assign dma_to_iopmp_len    = dma_req_len;
    assign dma_gnt             = dma_from_iopmp_gnt;
    assign dma_valid           = dma_from_iopmp_valid;
    assign dma_bus_rdata       = dma_from_iopmp_rdata;
    assign rsdg_admit_blocked  = 1'b0;
`endif

    iopmp u_iopmp (
        .clk(clk), .rst_n(rst_n), .enable(iopmp_enable),
        .dma_req(dma_to_iopmp_req), .dma_addr(dma_to_iopmp_addr),
        .dma_write(dma_to_iopmp_write), .dma_wdata(dma_to_iopmp_wdata),
        .dma_requester_id(dma_to_iopmp_rid), .dma_length(dma_to_iopmp_len),
        .dma_gnt(dma_from_iopmp_gnt), .dma_valid(dma_from_iopmp_valid),
        .dma_rdata(dma_from_iopmp_rdata), .dma_error(dma_master_error),
        .dma_req_out(iopmp_req), .dma_addr_out(iopmp_addr),
        .dma_write_out(iopmp_write), .dma_wdata_out(iopmp_wdata),
        .bus_gnt(iopmp_gnt), .bus_valid(iopmp_valid), .bus_rdata(iopmp_rdata),
        .rule0_base(rule0_base), .rule0_limit(rule0_limit), .rule0_rid(rule0_rid),
        .rule0_re(rule0_re), .rule0_we(rule0_we), .rule0_valid(rule0_valid),
        .secure_ready(secure_ready), .security_epoch(security_epoch),
        .txn_valid(iopmp_txn_valid), .txn_master(iopmp_txn_master),
        .txn_addr(iopmp_txn_addr), .txn_write(iopmp_txn_write),
        .txn_authorized_at_admission(iopmp_txn_authorized),
        .txn_requester_id(iopmp_txn_rid), .txn_length(iopmp_txn_length),
        .txn_age(iopmp_txn_age), .busy(iopmp_busy)
    );

    bus_interconnect u_ic (
        .clk(clk), .rst_n(rst_n),
        .cpu_req(pmp_req), .cpu_addr(pmp_addr), .cpu_write(pmp_write),
        .cpu_wdata(pmp_wdata),
        .cpu_gnt(pmp_gnt), .cpu_valid(pmp_valid), .cpu_rdata(pmp_rdata),
        .dma_req(iopmp_req), .dma_addr(iopmp_addr), .dma_write(iopmp_write),
        .dma_wdata(iopmp_wdata),
        .dma_gnt(iopmp_gnt), .dma_valid(iopmp_valid), .dma_rdata(iopmp_rdata),
        .norm_req(norm_req), .norm_addr(norm_addr), .norm_write(norm_write),
        .norm_wdata(norm_wdata), .norm_gnt(norm_gnt), .norm_valid(norm_valid),
        .norm_rdata(norm_rdata),
        .prot_req(prot_req), .prot_addr(prot_addr), .prot_write(prot_write),
        .prot_wdata(prot_wdata), .prot_gnt(prot_gnt), .prot_valid(prot_valid),
        .prot_rdata(prot_rdata)
    );

    sram #(.DEPTH(16384)) u_norm_sram (
        .clk(clk), .rst_n(rst_n),
        .req(norm_req), .write(norm_write), .addr(norm_addr), .wdata(norm_wdata),
        .gnt(norm_gnt), .valid(norm_valid), .rdata(norm_rdata),
        .mem_changed(), .changed_addr(), .changed_wdata(),
        .peek_addr(32'h0), .peek_data()
    );

    sram #(.DEPTH(16384)) u_prot_sram (
        .clk(clk), .rst_n(rst_n),
        .req(prot_req), .write(prot_write), .addr(prot_addr), .wdata(prot_wdata),
        .gnt(prot_gnt), .valid(prot_valid), .rdata(prot_rdata),
        .mem_changed(prot_mem_changed), .changed_addr(prot_changed_addr),
        .changed_wdata(prot_changed_wdata),
        .peek_addr(prot_peek_addr), .peek_data(prot_mem_word0)
    );

endmodule
