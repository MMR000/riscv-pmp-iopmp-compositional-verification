// Phase D J3: production domain reset coordination (no test sequencer).
// Mirrors reset-composed top domain split without harness timing.
`include "bus_pkg.vh"

module m7_ppa_domain_reset (
    input  wire clk,
    input  wire rst_n,
    input  wire cpu_release_i,
    input  wire dma_release_i,
    input  wire iopmp_release_i,
    input  wire sec_release_i,
    input  wire ic_release_i,
    output reg  cpu_reset_n,
    output reg  dma_reset_n,
    output reg  iopmp_reset_n,
    output reg  security_config_reset_n,
    output reg  interconnect_reset_n
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_reset_n               <= 1'b0;
            dma_reset_n               <= 1'b0;
            iopmp_reset_n             <= 1'b0;
            security_config_reset_n   <= 1'b0;
            interconnect_reset_n      <= 1'b0;
        end else begin
            if (cpu_release_i)   cpu_reset_n             <= 1'b1;
            if (dma_release_i)   dma_reset_n             <= 1'b1;
            if (iopmp_release_i) iopmp_reset_n           <= 1'b1;
            if (sec_release_i)   security_config_reset_n <= 1'b1;
            if (ic_release_i)    interconnect_reset_n    <= 1'b1;
        end
    end
endmodule
