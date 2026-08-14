// SP-11: protected-region DMA must not be admitted as authorized while enforcement absent.
`include "bus_pkg.vh"
`include "formal_helpers.vh"

module formal_sp11_rsdg_tb (
    input wire clk,
    input wire rst_n
);

    `FORMAL_RESET_CTRL(clk, dut_rst_n, formal_warmup)

    reg                     dma_req_in;
    reg [`ADDR_WIDTH-1:0]   dma_addr_in;
    reg                     dma_write_in;
    reg [7:0]               dma_rid_in;
    reg [15:0]              dma_length_in;

    wire secure_ready, iopmp_enable, rule0_valid;
    wire [`ADDR_WIDTH-1:0] rule0_base, rule0_limit;
    wire [7:0] rule0_rid;
    wire rule0_re, rule0_we;
    wire [7:0] security_epoch;
    wire iopmp_busy, dma_req_to_iopmp, admit_blocked;
    wire txn_authorized_at_admission;

    security_config u_sec (
        .clk(clk), .rst_n(rst_n && dut_rst_n),
        .pmp_enable(), .iopmp_enable(iopmp_enable),
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
    wire dma_gnt, dma_valid;

`ifdef RSDG_ADMIT_GATE
    rsdg #(.ADMIT_GATE(1)) u_rsdg (
        .clk(clk), .rst_n(rst_n && dut_rst_n),
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
        .clk(clk), .rst_n(rst_n && dut_rst_n),
        .enable(iopmp_enable),
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
        .txn_authorized_at_admission(txn_authorized_at_admission), .txn_requester_id(),
        .txn_length(), .txn_age(), .busy(iopmp_busy)
    );

    wire prot_req = `IN_PROT(dma_addr_in) && dma_req_in && dma_write_in;
    wire authorized_admit = dma_req_to_iopmp && prot_req && txn_authorized_at_admission;

    always @(*) assume (iopmp_enable);

    always @(posedge clk) begin
        if (formal_warmup && !secure_ready && prot_req)
            assert(!authorized_admit);
    end

endmodule
