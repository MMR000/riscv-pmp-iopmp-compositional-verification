// Simple word-addressable SRAM with observability for security tests.
// Uses addr[15:2] as word index (64 KiB region decode).
`include "bus_pkg.vh"

module sram #(
    parameter DEPTH = 16384
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     req,
    input  wire                     write,
    input  wire [`ADDR_WIDTH-1:0]   addr,
    input  wire [`DATA_WIDTH-1:0]   wdata,
    output reg                      gnt,
    output reg                      valid,
    output reg  [`DATA_WIDTH-1:0]   rdata,
    output reg                      mem_changed,
    output reg  [`ADDR_WIDTH-1:0]   changed_addr,
    output reg  [`DATA_WIDTH-1:0]   changed_wdata,
    input  wire [`ADDR_WIDTH-1:0]   peek_addr,
    output wire [`DATA_WIDTH-1:0]   peek_data
);

    localparam AW = $clog2(DEPTH);

    reg [`DATA_WIDTH-1:0] mem [0:DEPTH-1];
    wire [AW-1:0] word_idx = addr[AW+1:2];
    wire [AW-1:0] peek_idx = peek_addr[AW+1:2];

    assign peek_data = mem[peek_idx];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gnt          <= 1'b0;
            valid        <= 1'b0;
            rdata        <= {`DATA_WIDTH{1'b0}};
            mem_changed  <= 1'b0;
            changed_addr <= 32'h0;
            changed_wdata<= 32'h0;
        end else begin
            gnt         <= 1'b0;
            valid       <= 1'b0;
            mem_changed <= 1'b0;

            if (req) begin
                gnt <= 1'b1;
                if (write) begin
                    mem[word_idx] <= wdata;
                    mem_changed   <= 1'b1;
                    changed_addr  <= addr;
                    changed_wdata <= wdata;
                end else begin
                    rdata <= mem[word_idx];
                end
                valid <= 1'b1;
            end
        end
    end

endmodule
