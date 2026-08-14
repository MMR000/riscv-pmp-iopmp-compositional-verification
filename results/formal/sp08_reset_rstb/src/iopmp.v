// Minimal region-based IOPMP with admission pipeline and research observability.
// Authorization semantics: admission-time (see docs/decisions.md).
// length==0: treated as a 4-byte (one word) transfer for range evaluation.
`include "bus_pkg.vh"

module iopmp (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     enable,
    input  wire                     dma_req,
    input  wire [`ADDR_WIDTH-1:0]   dma_addr,
    input  wire                     dma_write,
    input  wire [`DATA_WIDTH-1:0]   dma_wdata,
    input  wire [7:0]               dma_requester_id,
    input  wire [15:0]              dma_length,
    output reg                      dma_gnt,
    output reg                      dma_valid,
    output reg  [`DATA_WIDTH-1:0]   dma_rdata,
    output reg                      dma_error,
    output reg                      dma_req_out,
    output reg  [`ADDR_WIDTH-1:0]   dma_addr_out,
    output reg                      dma_write_out,
    output reg  [`DATA_WIDTH-1:0]   dma_wdata_out,
    input  wire                     bus_gnt,
    input  wire                     bus_valid,
    input  wire [`DATA_WIDTH-1:0]   bus_rdata,
    input  wire [`ADDR_WIDTH-1:0]   rule0_base,
    input  wire [`ADDR_WIDTH-1:0]   rule0_limit,
    input  wire [7:0]               rule0_rid,
    input  wire                     rule0_re,
    input  wire                     rule0_we,
    input  wire                     rule0_valid,
    input  wire                     secure_ready,
    input  wire [7:0]               security_epoch,
    output reg                      txn_valid,
    output reg                      txn_master,
    output reg  [`ADDR_WIDTH-1:0]   txn_addr,
    output reg                      txn_write,
    output reg                      txn_authorized_at_admission,
    output reg  [7:0]               txn_requester_id,
    output reg  [15:0]              txn_length,
    output reg  [3:0]               txn_age,
    output wire                     busy
);

    localparam ST_IDLE    = 2'd0;
    localparam ST_HOLD    = 2'd1;
    localparam ST_PENDING = 2'd2;

    reg [1:0] state;

    reg [`ADDR_WIDTH-1:0]   hold_addr;
    reg                      hold_write;
    reg [`DATA_WIDTH-1:0]    hold_wdata;
    reg [7:0]                hold_rid;
    reg [15:0]               hold_length;
    reg                      hold_authorized;
    reg [7:0]                hold_epoch;

    assign busy = (state != ST_IDLE);
    function [15:0] effective_length;
        input [15:0] length_bytes;
        begin
            effective_length = (length_bytes == 0) ? 16'd4 : length_bytes;
        end
    endfunction

    function has_add_overflow;
        input [`ADDR_WIDTH-1:0] start_addr;
        input [15:0] length_bytes;
        reg [32:0] sum;
        begin
            sum = {1'b0, start_addr} + effective_length(length_bytes) - 33'd1;
            has_add_overflow = sum[32];
        end
    endfunction

    function [`ADDR_WIDTH-1:0] xfer_end_addr;
        input [`ADDR_WIDTH-1:0] start_addr;
        input [15:0] length_bytes;
        reg [32:0] sum;
        begin
            sum = {1'b0, start_addr} + effective_length(length_bytes) - 33'd1;
            xfer_end_addr = sum[31:0];
        end
    endfunction

    function in_range;
        input [`ADDR_WIDTH-1:0] a;
        input [`ADDR_WIDTH-1:0] base;
        input [`ADDR_WIDTH-1:0] limit;
        begin
            in_range = (a >= base) && (a <= limit);
        end
    endfunction

    function xfer_in_region;
        input [`ADDR_WIDTH-1:0] start_addr;
        input [15:0] length_bytes;
        reg [`ADDR_WIDTH-1:0] end_addr;
        begin
            if (has_add_overflow(start_addr, length_bytes))
                xfer_in_region = 1'b1;
            else begin
                end_addr = xfer_end_addr(start_addr, length_bytes);
                xfer_in_region = in_range(start_addr, `ADDR_PROTECT_SRAM_BASE, `ADDR_PROTECT_SRAM_LIMIT) ||
                                 in_range(end_addr,   `ADDR_PROTECT_SRAM_BASE, `ADDR_PROTECT_SRAM_LIMIT) ||
                                 ((start_addr < `ADDR_PROTECT_SRAM_BASE) &&
                                  (end_addr   > `ADDR_PROTECT_SRAM_LIMIT));
            end
        end
    endfunction

    function rule_matches_xfer;
        input [`ADDR_WIDTH-1:0] start_addr;
        input [15:0] length_bytes;
        input [7:0] rid;
        input is_write;
        reg [`ADDR_WIDTH-1:0] end_addr;
        begin
            rule_matches_xfer = 1'b0;
            if (!rule0_valid)
                rule_matches_xfer = 1'b0;
            else if (rule0_rid != rid)
                rule_matches_xfer = 1'b0;
            else if (has_add_overflow(start_addr, length_bytes))
                rule_matches_xfer = 1'b0;
            else begin
                end_addr = xfer_end_addr(start_addr, length_bytes);
                if (start_addr >= rule0_base && end_addr <= rule0_limit) begin
                    if (is_write)
                        rule_matches_xfer = rule0_we;
                    else
                        rule_matches_xfer = rule0_re;
                end
            end
        end
    endfunction

    function dma_allowed;
        input [`ADDR_WIDTH-1:0] start_addr;
        input [15:0] length_bytes;
        input [7:0] rid;
        input is_write;
        begin
            if (!enable)
                dma_allowed = 1'b1;
            else if (has_add_overflow(start_addr, length_bytes))
                dma_allowed = 1'b0;
            else if (!xfer_in_region(start_addr, length_bytes))
                dma_allowed = 1'b1;
            else
                dma_allowed = rule_matches_xfer(start_addr, length_bytes, rid, is_write);
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            dma_req_out   <= 1'b0;
            dma_addr_out  <= 32'h0;
            dma_write_out <= 1'b0;
            dma_wdata_out <= 32'h0;
            dma_gnt       <= 1'b0;
            dma_valid     <= 1'b0;
            dma_rdata     <= 32'h0;
            dma_error     <= 1'b0;
            txn_valid     <= 1'b0;
            txn_master    <= 1'b0;
            txn_addr      <= 32'h0;
            txn_write     <= 1'b0;
            txn_authorized_at_admission <= 1'b0;
            txn_requester_id <= 8'h0;
            txn_length    <= 16'h0;
            txn_age       <= 4'h0;
        end else begin
            dma_gnt     <= 1'b0;
            dma_valid   <= 1'b0;
            dma_error   <= 1'b0;

            case (state)
                ST_IDLE: begin
                    dma_req_out <= 1'b0;
                    txn_valid   <= 1'b0;
                    txn_age     <= 4'h0;
                    if (dma_req) begin
                        if (dma_allowed(dma_addr, dma_length, dma_requester_id, dma_write)) begin
                            hold_addr       <= dma_addr;
                            hold_write      <= dma_write;
                            hold_wdata      <= dma_wdata;
                            hold_rid        <= dma_requester_id;
                            hold_length     <= effective_length(dma_length);
                            hold_authorized <= 1'b1;
                            hold_epoch      <= security_epoch;
                            dma_gnt         <= 1'b1;
                            txn_valid       <= 1'b1;
                            txn_master      <= 1'b1;
                            txn_addr        <= dma_addr;
                            txn_write       <= dma_write;
                            txn_authorized_at_admission <= 1'b1;
                            txn_requester_id <= dma_requester_id;
                            txn_length      <= effective_length(dma_length);
                            txn_age         <= 4'h0;
                            state           <= ST_HOLD;
                        end else begin
                            dma_valid <= 1'b1;
                            dma_error <= 1'b1;
                            dma_gnt   <= 1'b1;
                            txn_valid <= 1'b1;
                            txn_master <= 1'b1;
                            txn_addr  <= dma_addr;
                            txn_write <= dma_write;
                            txn_authorized_at_admission <= 1'b0;
                            txn_requester_id <= dma_requester_id;
                            txn_length <= effective_length(dma_length);
                            txn_age   <= 4'h0;
                        end
                    end
                end
                ST_HOLD: begin
                    dma_req_out <= 1'b0;
                    txn_age     <= 4'h1;
                    state       <= ST_PENDING;
                end
                ST_PENDING: begin
                    txn_age <= 4'h2;
`ifdef RSDG_COMMIT_EPOCH
                    if (hold_write && in_range(hold_addr, rule0_base, rule0_limit) &&
                        (!secure_ready || (hold_epoch != security_epoch))) begin
                        dma_valid   <= 1'b1;
                        dma_error   <= 1'b1;
                        dma_req_out <= 1'b0;
                        txn_valid   <= 1'b0;
                        state       <= ST_IDLE;
                    end else begin
`endif
                    dma_req_out   <= 1'b1;
                    dma_addr_out  <= hold_addr;
                    dma_write_out <= hold_write;
                    dma_wdata_out <= hold_wdata;
                    if (bus_valid) begin
                        dma_valid <= 1'b1;
                        dma_rdata <= bus_rdata;
                        dma_req_out <= 1'b0;
                        txn_valid <= 1'b0;
                        state     <= ST_IDLE;
                    end
`ifdef RSDG_COMMIT_EPOCH
                    end
`endif
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

`ifdef FORMAL
    // SP-04/SP-05: protected DMA write commit requires admission-time authorization.
    always @(posedge clk) begin
        if (rst_n && enable && state == ST_PENDING && bus_valid && hold_write &&
            in_range(hold_addr, rule0_base, rule0_limit))
            assert(hold_authorized);
    end

    // SP-07 Model A: invalid rule denies newly authorized admissions (policy-transition).
`endif

`ifdef FORMAL_POLICY
    always @(posedge clk) begin
        if (rst_n && enable && !rule0_valid && txn_valid && txn_authorized_at_admission)
            assert(1'b0);
    end
`endif

endmodule
