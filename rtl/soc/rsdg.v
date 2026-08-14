// Reset-Safe DMA Guard (RSDG) — internal M4 research label.
// Gates new DMA admissions until secure_ready; optional commit-epoch validation
// is implemented in IOPMP when RSDG_COMMIT_EPOCH is defined.
`include "bus_pkg.vh"

module rsdg #(
    parameter ADMIT_GATE = 1
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     secure_ready,
    input  wire                     iopmp_busy,
    input  wire                     dma_req_in,
    input  wire [`ADDR_WIDTH-1:0]   dma_addr_in,
    input  wire                     dma_write_in,
    input  wire [`DATA_WIDTH-1:0]   dma_wdata_in,
    input  wire [7:0]               dma_rid_in,
    input  wire [15:0]              dma_length_in,
    output wire                     dma_gnt_out,
    output wire                     dma_valid_out,
    output wire [`DATA_WIDTH-1:0]   dma_rdata_out,
    input  wire                     dma_gnt_in,
    input  wire                     dma_valid_in,
    input  wire [`DATA_WIDTH-1:0]   dma_rdata_in,
    output wire                     dma_req_out,
    output wire [`ADDR_WIDTH-1:0]   dma_addr_out,
    output wire                     dma_write_out,
    output wire [`DATA_WIDTH-1:0]   dma_wdata_out,
    output wire [7:0]               dma_rid_out,
    output wire [15:0]              dma_length_out,
    output wire                     admit_blocked,
    output wire                     gate_open
);

    function in_protected;
        input [`ADDR_WIDTH-1:0] a;
        begin
            in_protected = (a >= `ADDR_PROTECT_SRAM_BASE) &&
                           (a <= `ADDR_PROTECT_SRAM_LIMIT);
        end
    endfunction

    wire admit_ok = !ADMIT_GATE || secure_ready || !in_protected(dma_addr_in) || iopmp_busy;

    assign gate_open     = secure_ready;
    assign admit_blocked = ADMIT_GATE && dma_req_in && !admit_ok;

    assign dma_req_out     = dma_req_in && admit_ok;
    assign dma_addr_out    = dma_addr_in;
    assign dma_write_out   = dma_write_in;
    assign dma_wdata_out   = dma_wdata_in;
    assign dma_rid_out     = dma_rid_in;
    assign dma_length_out  = dma_length_in;

    assign dma_gnt_out   = dma_gnt_in;
    assign dma_valid_out = dma_valid_in;
    assign dma_rdata_out = dma_rdata_in;

endmodule
