// Model B (strong revocation) semantic demonstration on Model A RTL.
`include "bus_pkg.vh"
`include "formal_helpers.vh"

module formal_model_b_tb (
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
    wire [`DATA_WIDTH-1:0] dma_wdata_out;
    wire bus_gnt, bus_valid;
    wire [`DATA_WIDTH-1:0] bus_rdata;
    wire txn_valid;
    wire txn_authorized_at_admission;

    iopmp u_dut (
        .clk(clk), .rst_n(dut_rst_n), .enable(enable),
        .dma_req(dma_req), .dma_addr(dma_addr), .dma_write(dma_write),
        .dma_wdata(dma_wdata), .dma_requester_id(dma_requester_id),
        .dma_length(dma_length),
        .dma_gnt(dma_gnt), .dma_valid(dma_valid), .dma_rdata(dma_rdata),
        .dma_error(dma_error),
        .dma_req_out(dma_req_out), .dma_addr_out(),
        .dma_write_out(), .dma_wdata_out(dma_wdata_out),
        .bus_gnt(bus_gnt), .bus_valid(bus_valid), .bus_rdata(bus_rdata),
        .rule0_base(rule0_base), .rule0_limit(rule0_limit),
        .rule0_rid(rule0_rid), .rule0_re(rule0_re), .rule0_we(rule0_we),
        .rule0_valid(rule0_valid),
        .secure_ready(1'b1), .security_epoch(8'd0),
        .txn_valid(txn_valid), .txn_master(), .txn_addr(), .txn_write(),
        .txn_authorized_at_admission(txn_authorized_at_admission),
        .txn_requester_id(), .txn_length(), .txn_age(), .busy()
    );

    formal_bus_stub u_bus (
        .clk(clk), .rst_n(dut_rst_n),
        .req(dma_req_out), .write(dma_write),
        .gnt(bus_gnt), .valid(bus_valid), .rdata(bus_rdata)
    );

    wire [1:0] iopmp_state;
    wire iopmp_hold_authorized;
    assign iopmp_state = u_dut.state;
    assign iopmp_hold_authorized = u_dut.hold_authorized;

    localparam ST_HOLD    = 2'd1;
    localparam ST_PENDING = 2'd2;

    reg rule0_valid_q;
    reg admitted_allow;
    reg saw_revoke_during_pending;

    always @(posedge clk) begin
        if (!dut_rst_n) begin
            rule0_valid_q <= 1'b0;
            admitted_allow <= 1'b0;
            saw_revoke_during_pending <= 1'b0;
        end else begin
            if (iopmp_state == ST_HOLD && rule0_valid && txn_authorized_at_admission)
                admitted_allow <= 1'b1;
            if (admitted_allow && rule0_valid_q && !rule0_valid &&
                (iopmp_state == ST_PENDING))
                saw_revoke_during_pending <= 1'b1;
            rule0_valid_q <= rule0_valid;
        end
    end

    always @(*) assume (enable);
    always @(*) assume (rule0_base == `ADDR_PROTECT_SRAM_BASE);
    always @(*) assume (rule0_limit == `ADDR_PROTECT_SRAM_LIMIT);
    always @(*) assume (dma_write);
    always @(*) assume (`IN_PROT(dma_addr));
    always @(*) assume (dma_requester_id == rule0_rid);
    always @(*) assume (rule0_we);

    // T0-T4 semantic sequence reachability (Model A vs Model B).
    wire seq_t0_allow = formal_warmup && rule0_valid;
    wire seq_t1_admit = formal_warmup && dma_req && (iopmp_state == ST_IDLE) && rule0_valid;
    wire seq_t2_pending = formal_warmup && (iopmp_state == ST_PENDING) && admitted_allow;
    wire seq_t3_revoke = formal_warmup && rule0_valid_q && !rule0_valid && (iopmp_state == ST_PENDING);
    wire seq_t4_commit = formal_warmup && saw_revoke_during_pending && dma_req_out;

    always @(posedge clk) cover(seq_t0_allow);
    always @(posedge clk) cover(seq_t1_admit);
    always @(posedge clk) cover(seq_t2_pending);
    always @(posedge clk) cover(seq_t3_revoke);
    always @(posedge clk) cover(seq_t4_commit);

    // SP-B01 Model B: after DENY effective, pending txn must not commit (expect fail on Model A).
    always @(posedge clk) begin
        if (formal_warmup && saw_revoke_during_pending && iopmp_state == ST_PENDING)
            assert(!dma_req_out);
    end

endmodule
