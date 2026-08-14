// Unit-level formal harness for IOPMP (uses production iopmp.v RTL).
`include "bus_pkg.vh"
`include "formal_helpers.vh"

module formal_iopmp_tb (
    input wire clk,
    input wire rst_n
);

    `FORMAL_RESET_CTRL(clk, dut_rst_n, formal_warmup)

    reg                     enable;
    reg                     dma_req;
    reg [`ADDR_WIDTH-1:0]   dma_addr;
    reg                     dma_write;
    reg [`DATA_WIDTH-1:0]   dma_wdata;
    reg [7:0]               dma_requester_id;
    reg [15:0]              dma_length;
    reg [`ADDR_WIDTH-1:0]   rule0_base;
    reg [`ADDR_WIDTH-1:0]   rule0_limit;
    reg [7:0]               rule0_rid;
    reg                     rule0_re;
    reg                     rule0_we;
    reg                     rule0_valid;

    wire dma_gnt, dma_valid, dma_error;
    wire [`DATA_WIDTH-1:0] dma_rdata;
    wire dma_req_out;
    wire [`ADDR_WIDTH-1:0] dma_addr_out;
    wire dma_write_out;
    wire [`DATA_WIDTH-1:0] dma_wdata_out;
    wire bus_gnt, bus_valid;
    wire [`DATA_WIDTH-1:0] bus_rdata;

    wire txn_valid;
    wire [`ADDR_WIDTH-1:0] txn_addr;
    wire txn_write;
    wire txn_authorized_at_admission;
    wire [7:0] txn_requester_id;

    iopmp u_dut (
        .clk(clk), .rst_n(dut_rst_n), .enable(enable),
        .dma_req(dma_req), .dma_addr(dma_addr), .dma_write(dma_write),
        .dma_wdata(dma_wdata), .dma_requester_id(dma_requester_id),
        .dma_length(dma_length),
        .dma_gnt(dma_gnt), .dma_valid(dma_valid), .dma_rdata(dma_rdata),
        .dma_error(dma_error),
        .dma_req_out(dma_req_out), .dma_addr_out(dma_addr_out),
        .dma_write_out(dma_write_out), .dma_wdata_out(dma_wdata_out),
        .bus_gnt(bus_gnt), .bus_valid(bus_valid), .bus_rdata(bus_rdata),
        .rule0_base(rule0_base), .rule0_limit(rule0_limit),
        .rule0_rid(rule0_rid), .rule0_re(rule0_re), .rule0_we(rule0_we),
        .rule0_valid(rule0_valid),
        .secure_ready(1'b1), .security_epoch(8'd0),
        .txn_valid(txn_valid), .txn_master(), .txn_addr(txn_addr),
        .txn_write(txn_write), .txn_authorized_at_admission(txn_authorized_at_admission),
        .txn_requester_id(txn_requester_id), .txn_length(), .txn_age(), .busy()
    );

    formal_bus_stub u_bus (
        .clk(clk), .rst_n(dut_rst_n),
        .req(dma_req_out), .write(dma_write_out),
        .gnt(bus_gnt), .valid(bus_valid), .rdata(bus_rdata)
    );

    wire [1:0] iopmp_state;
    wire iopmp_hold_authorized;
    wire [7:0] iopmp_hold_rid;
    wire [`ADDR_WIDTH-1:0] iopmp_hold_addr;
    wire iopmp_hold_write;

    assign iopmp_state = u_dut.state;
    assign iopmp_hold_authorized = u_dut.hold_authorized;
    assign iopmp_hold_rid = u_dut.hold_rid;
    assign iopmp_hold_addr = u_dut.hold_addr;
    assign iopmp_hold_write = u_dut.hold_write;

    localparam ST_IDLE    = 2'd0;
    localparam ST_HOLD    = 2'd1;
    localparam ST_PENDING = 2'd2;

    wire dma_idle_admit = enable && dma_req && (iopmp_state == ST_IDLE) &&
                          dma_write && `IN_PROT(dma_addr);
    wire dma_unauth_admit = dma_idle_admit &&
                            (dma_requester_id != rule0_rid || !rule0_we || !rule0_valid);
    wire dma_auth_admit = dma_idle_admit &&
                          (dma_requester_id == rule0_rid) && rule0_we && rule0_valid;

    always @(*) assume (enable);
    always @(*) assume (rule0_base == `ADDR_PROTECT_SRAM_BASE);
    always @(*) assume (rule0_limit == `ADDR_PROTECT_SRAM_LIMIT);
    always @(*) assume (`IN_PROT(dma_addr));

    // SP-04/SP-05/SP-07 admission checks live in iopmp.v (`ifdef FORMAL).

    // SP-06: pending transaction retains admitted requester ID at bus commit.
    always @(posedge clk) begin
        if (formal_warmup && iopmp_state == ST_PENDING) begin
            assert(txn_requester_id == iopmp_hold_rid);
            assert(dma_addr_out == iopmp_hold_addr);
            assert(dma_write_out == iopmp_hold_write);
        end
    end

    // SP-09: pending metadata stable from HOLD through PENDING.
    reg [7:0] hold_rid_q;
    reg [`ADDR_WIDTH-1:0] hold_addr_q;
    reg hold_write_q;
    reg hold_auth_q;
    always @(posedge clk) begin
        if (!dut_rst_n) begin
            hold_rid_q <= 8'h0;
            hold_addr_q <= 32'h0;
            hold_write_q <= 1'b0;
            hold_auth_q <= 1'b0;
        end else if (iopmp_state == ST_HOLD) begin
            hold_rid_q <= iopmp_hold_rid;
            hold_addr_q <= iopmp_hold_addr;
            hold_write_q <= iopmp_hold_write;
            hold_auth_q <= iopmp_hold_authorized;
        end else if (formal_warmup && iopmp_state == ST_PENDING) begin
            assert(iopmp_hold_rid == hold_rid_q);
            assert(iopmp_hold_addr == hold_addr_q);
            assert(iopmp_hold_write == hold_write_q);
            assert(iopmp_hold_authorized == hold_auth_q);
        end
    end

    // SP-07 checked in separate policy-transition context; baseline assumes valid rule.
    always @(*) assume (rule0_valid);

    // Policy-revocation cover moved to dedicated SP-B01 task (requires !rule0_valid).
    always @(posedge clk) cover(formal_warmup && iopmp_state == ST_HOLD && iopmp_hold_authorized);
    always @(posedge clk) cover(formal_warmup && dma_unauth_admit);
    always @(posedge clk) cover(formal_warmup && iopmp_state == ST_PENDING);
    always @(posedge clk) cover(formal_warmup && bus_valid && iopmp_hold_authorized);

endmodule
