// Simple two-master interconnect with fixed decode.
`include "bus_pkg.vh"

module bus_interconnect (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     cpu_req,
    input  wire [`ADDR_WIDTH-1:0]   cpu_addr,
    input  wire                     cpu_write,
    input  wire [`DATA_WIDTH-1:0]   cpu_wdata,
    output reg                      cpu_gnt,
    output reg                      cpu_valid,
    output reg  [`DATA_WIDTH-1:0]   cpu_rdata,
    input  wire                     dma_req,
    input  wire [`ADDR_WIDTH-1:0]   dma_addr,
    input  wire                     dma_write,
    input  wire [`DATA_WIDTH-1:0]   dma_wdata,
    output reg                      dma_gnt,
    output reg                      dma_valid,
    output reg  [`DATA_WIDTH-1:0]   dma_rdata,
    output reg                      norm_req,
    output reg  [`ADDR_WIDTH-1:0]   norm_addr,
    output reg                      norm_write,
    output reg  [`DATA_WIDTH-1:0]   norm_wdata,
    input  wire                     norm_gnt,
    input  wire                     norm_valid,
    input  wire [`DATA_WIDTH-1:0]   norm_rdata,
    output reg                      prot_req,
    output reg  [`ADDR_WIDTH-1:0]   prot_addr,
    output reg                      prot_write,
    output reg  [`DATA_WIDTH-1:0]   prot_wdata,
    input  wire                     prot_gnt,
    input  wire                     prot_valid,
    input  wire [`DATA_WIDTH-1:0]   prot_rdata
);

    localparam ARB_IDLE      = 2'd0;
    localparam ARB_SERVE_CPU = 2'd1;
    localparam ARB_SERVE_DMA = 2'd2;

    reg [1:0] arb;
    reg serve_cpu;
    reg [`ADDR_WIDTH-1:0] active_addr;
    reg active_write;
    reg [`DATA_WIDTH-1:0] active_wdata;

    function hit_normal;
        input [`ADDR_WIDTH-1:0] a;
        begin
            hit_normal = (a >= `ADDR_NORMAL_SRAM_BASE) && (a <= `ADDR_NORMAL_SRAM_LIMIT);
        end
    endfunction

    function hit_protected;
        input [`ADDR_WIDTH-1:0] a;
        begin
            hit_protected = (a >= `ADDR_PROTECT_SRAM_BASE) && (a <= `ADDR_PROTECT_SRAM_LIMIT);
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arb       <= ARB_IDLE;
            serve_cpu <= 1'b0;
            cpu_gnt   <= 1'b0;
            dma_gnt   <= 1'b0;
            cpu_valid <= 1'b0;
            dma_valid <= 1'b0;
            cpu_rdata <= 32'h0;
            dma_rdata <= 32'h0;
            norm_req  <= 1'b0;
            prot_req  <= 1'b0;
        end else begin
            cpu_gnt   <= 1'b0;
            dma_gnt   <= 1'b0;
            cpu_valid <= 1'b0;
            dma_valid <= 1'b0;
            norm_req  <= 1'b0;
            prot_req  <= 1'b0;

            case (arb)
                ARB_IDLE: begin
                    if (cpu_req) begin
                        serve_cpu    <= 1'b1;
                        active_addr  <= cpu_addr;
                        active_write <= cpu_write;
                        active_wdata <= cpu_wdata;
                        arb          <= ARB_SERVE_CPU;
                    end else if (dma_req) begin
                        serve_cpu    <= 1'b0;
                        active_addr  <= dma_addr;
                        active_write <= dma_write;
                        active_wdata <= dma_wdata;
                        arb          <= ARB_SERVE_DMA;
                    end
                end
                ARB_SERVE_CPU: begin
                    if (hit_protected(active_addr)) begin
                        prot_req   <= 1'b1;
                        prot_addr  <= active_addr;
                        prot_write <= active_write;
                        prot_wdata <= active_wdata;
                        if (serve_cpu) begin
                            cpu_gnt <= prot_gnt;
                            if (prot_valid) begin
                                cpu_valid <= 1'b1;
                                cpu_rdata <= prot_rdata;
                                arb       <= ARB_IDLE;
                            end
                        end else begin
                            dma_gnt <= prot_gnt;
                            if (prot_valid) begin
                                dma_valid <= 1'b1;
                                dma_rdata <= prot_rdata;
                                arb       <= ARB_IDLE;
                            end
                        end
                    end else if (hit_normal(active_addr)) begin
                        norm_req   <= 1'b1;
                        norm_addr  <= active_addr;
                        norm_write <= active_write;
                        norm_wdata <= active_wdata;
                        if (serve_cpu) begin
                            cpu_gnt <= norm_gnt;
                            if (norm_valid) begin
                                cpu_valid <= 1'b1;
                                cpu_rdata <= norm_rdata;
                                arb       <= ARB_IDLE;
                            end
                        end else begin
                            dma_gnt <= norm_gnt;
                            if (norm_valid) begin
                                dma_valid <= 1'b1;
                                dma_rdata <= norm_rdata;
                                arb       <= ARB_IDLE;
                            end
                        end
                    end else begin
                        if (serve_cpu) begin
                            cpu_gnt   <= 1'b1;
                            cpu_valid <= 1'b1;
                            cpu_rdata <= 32'h0;
                        end else begin
                            dma_gnt   <= 1'b1;
                            dma_valid <= 1'b1;
                            dma_rdata <= 32'h0;
                        end
                        arb <= ARB_IDLE;
                    end
                end
                ARB_SERVE_DMA: begin
                    if (hit_protected(active_addr)) begin
                        prot_req   <= 1'b1;
                        prot_addr  <= active_addr;
                        prot_write <= active_write;
                        prot_wdata <= active_wdata;
                        if (serve_cpu) begin
                            cpu_gnt <= prot_gnt;
                            if (prot_valid) begin
                                cpu_valid <= 1'b1;
                                cpu_rdata <= prot_rdata;
                                arb       <= ARB_IDLE;
                            end
                        end else begin
                            dma_gnt <= prot_gnt;
                            if (prot_valid) begin
                                dma_valid <= 1'b1;
                                dma_rdata <= prot_rdata;
                                arb       <= ARB_IDLE;
                            end
                        end
                    end else if (hit_normal(active_addr)) begin
                        norm_req   <= 1'b1;
                        norm_addr  <= active_addr;
                        norm_write <= active_write;
                        norm_wdata <= active_wdata;
                        if (serve_cpu) begin
                            cpu_gnt <= norm_gnt;
                            if (norm_valid) begin
                                cpu_valid <= 1'b1;
                                cpu_rdata <= norm_rdata;
                                arb       <= ARB_IDLE;
                            end
                        end else begin
                            dma_gnt <= norm_gnt;
                            if (norm_valid) begin
                                dma_valid <= 1'b1;
                                dma_rdata <= norm_rdata;
                                arb       <= ARB_IDLE;
                            end
                        end
                    end else begin
                        if (serve_cpu) begin
                            cpu_gnt   <= 1'b1;
                            cpu_valid <= 1'b1;
                            cpu_rdata <= 32'h0;
                        end else begin
                            dma_gnt   <= 1'b1;
                            dma_valid <= 1'b1;
                            dma_rdata <= 32'h0;
                        end
                        arb <= ARB_IDLE;
                    end
                end
                default: arb <= ARB_IDLE;
            endcase
        end
    end

endmodule
