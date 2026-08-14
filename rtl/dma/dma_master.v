// Abstract DMA master: single-beat read, write, or memory-to-memory word transfer.
`include "bus_pkg.vh"

module dma_master (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,
    input  wire [`ADDR_WIDTH-1:0]   src_addr,
    input  wire [`ADDR_WIDTH-1:0]   dst_addr,
    input  wire [`DATA_WIDTH-1:0]   wdata,
    input  wire [15:0]              length,
    input  wire [7:0]               requester_id,
    input  wire [1:0]               mode,
    output reg                      req,
    output reg  [`ADDR_WIDTH-1:0]   req_addr,
    output reg                      req_write,
    output reg  [`DATA_WIDTH-1:0]   req_wdata,
    output reg  [7:0]               req_requester_id,
    output reg  [15:0]              req_length,
    input  wire                     gnt,
    input  wire                     valid,
    input  wire [`DATA_WIDTH-1:0]   rdata,
    input  wire                     error,
    output reg                      done,
    output reg                      last_error,
    output reg  [`DATA_WIDTH-1:0]   last_rdata
);

    localparam ST_IDLE  = 2'd0;
    localparam ST_XFER  = 2'd1;
    localparam ST_M2M_W = 2'd2;

    reg [1:0] state;
    reg [`DATA_WIDTH-1:0] read_hold;
    wire [15:0] beat_len = (length == 0) ? 16'd4 : length;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= ST_IDLE;
            req              <= 1'b0;
            req_addr         <= 32'h0;
            req_write        <= 1'b0;
            req_wdata        <= 32'h0;
            req_requester_id <= 8'h0;
            req_length       <= 16'h0;
            done             <= 1'b0;
            last_error       <= 1'b0;
            last_rdata       <= 32'h0;
            read_hold        <= 32'h0;
        end else begin
            done <= 1'b0;
            case (state)
                ST_IDLE: begin
                    req <= 1'b0;
                    if (start) begin
                        req_requester_id <= requester_id;
                        req_length       <= beat_len;
                        last_error       <= 1'b0;
                        case (mode)
                            2'd0: begin
                                req_addr  <= src_addr;
                                req_write <= 1'b0;
                                req       <= 1'b1;
                                state     <= ST_XFER;
                            end
                            2'd1: begin
                                req_addr  <= dst_addr;
                                req_write <= 1'b1;
                                req_wdata <= wdata;
                                req       <= 1'b1;
                                state     <= ST_XFER;
                            end
                            default: begin
                                req_addr  <= src_addr;
                                req_write <= 1'b0;
                                req       <= 1'b1;
                                state     <= ST_XFER;
                            end
                        endcase
                    end
                end
                ST_XFER: begin
                    if (gnt)
                        req <= 1'b0;
                    if (valid) begin
                        last_error <= error;
                        last_rdata <= rdata;
                        if (mode == 2'd2 && !error) begin
                            read_hold <= rdata;
                            req_addr  <= dst_addr;
                            req_write <= 1'b1;
                            req_wdata <= rdata;
                            req       <= 1'b1;
                            state     <= ST_M2M_W;
                        end else begin
                            done  <= 1'b1;
                            state <= ST_IDLE;
                        end
                    end
                end
                ST_M2M_W: begin
                    if (gnt)
                        req <= 1'b0;
                    if (valid) begin
                        if (error)
                            last_error <= 1'b1;
                        done  <= 1'b1;
                        state <= ST_IDLE;
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
