// One-cycle grant/valid bus stub for unit-level IOPMP/PMP formal tests.
`include "bus_pkg.vh"

module formal_bus_stub (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     req,
    input  wire                     write,
    output reg                      gnt,
    output reg                      valid,
    output reg  [`DATA_WIDTH-1:0]   rdata
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gnt   <= 1'b0;
            valid <= 1'b0;
            rdata <= 32'h0;
        end else begin
            gnt   <= req;
            valid <= req;
            if (req && !write)
                rdata <= 32'hDEAD_BEEF;
        end
    end
endmodule
