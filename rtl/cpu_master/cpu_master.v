// Abstract CPU bus master for research testbed (Phase 1).
`include "bus_pkg.vh"

module cpu_master (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,
    input  wire [`ADDR_WIDTH-1:0]   addr,
    input  wire                     write,
    input  wire [`DATA_WIDTH-1:0]   wdata,
    input  wire                     privilege,
    output reg                      req,
    output reg  [`ADDR_WIDTH-1:0]   req_addr,
    output reg                      req_write,
    output reg  [`DATA_WIDTH-1:0]   req_wdata,
    output reg                      req_privilege,
    input  wire                     gnt,
    input  wire                     valid,
    input  wire [`DATA_WIDTH-1:0]   rdata,
    input  wire                     error,
    output reg                      done,
    output reg                      last_error,
    output reg  [`DATA_WIDTH-1:0]   last_rdata
);

    localparam ST_IDLE = 2'd0;
    localparam ST_REQ  = 2'd1;
    localparam ST_WAIT = 2'd2;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            req           <= 1'b0;
            req_addr      <= 32'h0;
            req_write     <= 1'b0;
            req_wdata     <= 32'h0;
            req_privilege <= 1'b0;
            done          <= 1'b0;
            last_error    <= 1'b0;
            last_rdata    <= 32'h0;
        end else begin
            done <= 1'b0;
            case (state)
                ST_IDLE: begin
                    req <= 1'b0;
                    if (start) begin
                        req_addr      <= addr;
                        req_write     <= write;
                        req_wdata     <= wdata;
                        req_privilege <= privilege;
                        req           <= 1'b1;
                        state         <= ST_REQ;
                    end
                end
                ST_REQ: begin
                    if (gnt) begin
                        req   <= 1'b0;
                        state <= ST_WAIT;
                    end
                end
                ST_WAIT: begin
                    if (valid) begin
                        last_error <= error;
                        last_rdata <= rdata;
                        done       <= 1'b1;
                        state      <= ST_IDLE;
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
