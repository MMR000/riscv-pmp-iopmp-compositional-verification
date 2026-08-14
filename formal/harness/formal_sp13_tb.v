// SP-13: protected DMA must not become effectively usable before enforcing security state.
`include "bus_pkg.vh"
`include "formal_helpers.vh"

module formal_sp13_tb (
    input wire clk,
    input wire rst_n
);

    `FORMAL_RESET_CTRL(clk, dut_rst_n, formal_warmup)

    reg                     dma_req;
    reg [`ADDR_WIDTH-1:0]   dma_addr;
    reg                     dma_write;
    reg [7:0]               dma_requester_id;
    reg [15:0]              dma_length;

    wire pmp_enable, iopmp_enable, secure_ready, rule0_valid;
    wire [`ADDR_WIDTH-1:0] rule0_base, rule0_limit;
    wire [7:0] rule0_rid, security_epoch;
    wire rule0_re, rule0_we;

    wire iopmp_req, iopmp_write, iopmp_gnt, iopmp_valid;
    wire [`ADDR_WIDTH-1:0] iopmp_addr;
    wire [`DATA_WIDTH-1:0] iopmp_wdata, iopmp_rdata;

    wire prot_req, prot_write, prot_gnt, prot_valid, prot_mem_changed;
    wire [`ADDR_WIDTH-1:0] prot_addr;
    wire [`DATA_WIDTH-1:0] prot_wdata, prot_rdata;

    security_config u_sec (
        .clk(clk), .rst_n(rst_n && dut_rst_n),
        .pmp_enable(pmp_enable), .iopmp_enable(iopmp_enable),
        .rule0_base(rule0_base), .rule0_limit(rule0_limit),
        .rule0_rid(rule0_rid), .rule0_re(rule0_re), .rule0_we(rule0_we),
        .rule0_valid(rule0_valid), .secure_ready(secure_ready),
        .security_epoch(security_epoch),
        .cfg_write(1'b0), .cfg_addr(32'h0), .cfg_wdata(32'h0)
    );

    iopmp u_iopmp (
        .clk(clk), .rst_n(rst_n && dut_rst_n),
        .enable(iopmp_enable),
        .dma_req(dma_req), .dma_addr(dma_addr), .dma_write(dma_write),
        .dma_wdata(32'h0), .dma_requester_id(dma_requester_id),
        .dma_length(dma_length),
        .dma_gnt(), .dma_valid(), .dma_rdata(), .dma_error(),
        .dma_req_out(iopmp_req), .dma_addr_out(iopmp_addr),
        .dma_write_out(iopmp_write), .dma_wdata_out(iopmp_wdata),
        .bus_gnt(iopmp_gnt), .bus_valid(iopmp_valid), .bus_rdata(iopmp_rdata),
        .rule0_base(rule0_base), .rule0_limit(rule0_limit),
        .rule0_rid(rule0_rid), .rule0_re(rule0_re), .rule0_we(rule0_we),
        .rule0_valid(rule0_valid),
        .secure_ready(secure_ready), .security_epoch(security_epoch),
        .txn_valid(), .txn_master(), .txn_addr(), .txn_write(),
        .txn_authorized_at_admission(), .txn_requester_id(),
        .txn_length(), .txn_age(), .busy()
    );

    bus_interconnect u_ic (
        .clk(clk), .rst_n(rst_n && dut_rst_n),
        .cpu_req(1'b0), .cpu_addr(32'h0), .cpu_write(1'b0), .cpu_wdata(32'h0),
        .cpu_gnt(), .cpu_valid(), .cpu_rdata(),
        .dma_req(iopmp_req), .dma_addr(iopmp_addr), .dma_write(iopmp_write),
        .dma_wdata(iopmp_wdata),
        .dma_gnt(iopmp_gnt), .dma_valid(iopmp_valid), .dma_rdata(iopmp_rdata),
        .norm_req(), .norm_addr(), .norm_write(), .norm_wdata(),
        .norm_gnt(1'b0), .norm_valid(1'b0), .norm_rdata(32'h0),
        .prot_req(prot_req), .prot_addr(prot_addr), .prot_write(prot_write),
        .prot_wdata(prot_wdata), .prot_gnt(prot_gnt), .prot_valid(prot_valid),
        .prot_rdata(prot_rdata)
    );

    sram #(.DEPTH(256)) u_prot (
        .clk(clk), .rst_n(rst_n && dut_rst_n),
        .req(prot_req), .write(prot_write), .addr(prot_addr), .wdata(prot_wdata),
        .gnt(prot_gnt), .valid(prot_valid), .rdata(prot_rdata),
        .mem_changed(prot_mem_changed), .changed_addr(), .changed_wdata(),
        .peek_addr(`ADDR_PROTECT_SRAM_BASE), .peek_data()
    );

    wire enforcing = secure_ready && iopmp_enable && rule0_valid;
    wire prot_effect = prot_mem_changed && `IN_PROT(prot_addr);

    always @(posedge clk) begin
        if (formal_warmup && !enforcing && prot_effect)
            assert(0);
    end

endmodule
