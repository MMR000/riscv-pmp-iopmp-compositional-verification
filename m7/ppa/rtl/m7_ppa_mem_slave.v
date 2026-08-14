// Phase D: synthesizable memory interface shell (no storage arrays).
// Implements handshake only; excluded from comparative logic-area accounting.
`include "bus_pkg.vh"

module m7_ppa_mem_slave (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     req,
    input  wire                     write,
    input  wire [`ADDR_WIDTH-1:0]   addr,
    input  wire [`DATA_WIDTH-1:0]   wdata,
    output reg                      gnt,
    output reg                      valid,
    output reg  [`DATA_WIDTH-1:0]   rdata
);
    // One-cycle accept; reads return registered address xor (prevents constant-fold of addr path).
    reg [`ADDR_WIDTH-1:0] addr_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gnt    <= 1'b0;
            valid  <= 1'b0;
            rdata  <= 32'h0;
            addr_q <= 32'h0;
        end else begin
            gnt   <= 1'b0;
            valid <= 1'b0;
            if (req) begin
                gnt    <= 1'b1;
                valid  <= 1'b1;
                addr_q <= addr;
                if (!write)
                    rdata <= addr ^ 32'hA5A5_A5A5;
            end
        end
    end
endmodule
