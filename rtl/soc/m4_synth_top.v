// Consistent synthesis top for M4 configuration comparison.
`include "bus_pkg.vh"

module m4_synth_top (
    input wire clk,
    input wire rst_n,
    input wire dma_req_in,
    input wire [`ADDR_WIDTH-1:0] dma_addr_in,
    input wire dma_write_in,
    input wire [7:0] dma_rid_in,
    input wire [15:0] dma_length_in,
    output wire secure_ready,
    output wire [7:0] security_epoch,
    output wire dma_req_to_iopmp,
    output wire admit_blocked,
    output wire iopmp_busy
);

    wire pmp_enable, iopmp_enable, rule0_re, rule0_we, rule0_valid;
    wire [`ADDR_WIDTH-1:0] rule0_base, rule0_limit;
    wire [7:0] rule0_rid;
    wire dma_gnt, dma_valid;

    security_config u_sec (
        .clk(clk), .rst_n(rst_n),
        .pmp_enable(pmp_enable), .iopmp_enable(iopmp_enable),
        .rule0_base(rule0_base), .rule0_limit(rule0_limit),
        .rule0_rid(rule0_rid), .rule0_re(rule0_re), .rule0_we(rule0_we),
        .rule0_valid(rule0_valid),
        .secure_ready(secure_ready), .security_epoch(security_epoch),
        .cfg_write(1'b0), .cfg_addr(32'h0), .cfg_wdata(32'h0)
    );

    wire dma_req_gate;
    wire [`ADDR_WIDTH-1:0] dma_addr_gate;
    wire dma_write_gate;
    wire [7:0] dma_rid_gate;
    wire [15:0] dma_len_gate;

`ifdef RSDG_ADMIT_GATE
    rsdg #(.ADMIT_GATE(1)) u_rsdg (
        .clk(clk), .rst_n(rst_n),
        .secure_ready(secure_ready), .iopmp_busy(iopmp_busy),
        .dma_req_in(dma_req_in), .dma_addr_in(dma_addr_in),
        .dma_write_in(dma_write_in), .dma_wdata_in(32'h0),
        .dma_rid_in(dma_rid_in), .dma_length_in(dma_length_in),
        .dma_gnt_out(dma_gnt), .dma_valid_out(dma_valid), .dma_rdata_out(),
        .dma_gnt_in(1'b0), .dma_valid_in(1'b0), .dma_rdata_in(32'h0),
        .dma_req_out(dma_req_gate), .dma_addr_out(dma_addr_gate),
        .dma_write_out(dma_write_gate), .dma_wdata_out(),
        .dma_rid_out(dma_rid_gate), .dma_length_out(dma_len_gate),
        .admit_blocked(admit_blocked), .gate_open()
    );
    assign dma_req_to_iopmp = dma_req_gate;
`else
    assign dma_req_gate = dma_req_in;
    assign dma_addr_gate = dma_addr_in;
    assign dma_write_gate = dma_write_in;
    assign dma_rid_gate = dma_rid_in;
    assign dma_len_gate = dma_length_in;
    assign admit_blocked = 1'b0;
    assign dma_req_to_iopmp = dma_req_in;
`endif

    iopmp u_iopmp (
        .clk(clk), .rst_n(rst_n), .enable(iopmp_enable),
        .dma_req(dma_req_gate), .dma_addr(dma_addr_gate),
        .dma_write(dma_write_gate), .dma_wdata(32'h0),
        .dma_requester_id(dma_rid_gate), .dma_length(dma_len_gate),
        .dma_gnt(dma_gnt), .dma_valid(dma_valid), .dma_rdata(),
        .dma_error(), .dma_req_out(), .dma_addr_out(),
        .dma_write_out(), .dma_wdata_out(),
        .bus_gnt(1'b0), .bus_valid(1'b0), .bus_rdata(32'h0),
        .rule0_base(rule0_base), .rule0_limit(rule0_limit),
        .rule0_rid(rule0_rid), .rule0_re(rule0_re),
        .rule0_we(rule0_we), .rule0_valid(rule0_valid),
        .secure_ready(secure_ready), .security_epoch(security_epoch),
        .txn_valid(), .txn_master(), .txn_addr(), .txn_write(),
        .txn_authorized_at_admission(), .txn_requester_id(),
        .txn_length(), .txn_age(), .busy(iopmp_busy)
    );

endmodule
