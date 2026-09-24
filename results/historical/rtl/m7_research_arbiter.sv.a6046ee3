// M7 Phase-B arbiter: Ibex-friendly grant-on-accept, then memory valid.
// Separate from rtl/interconnect/interconnect.v so M1–M5 stay unchanged.
`include "bus_pkg.vh"

module m7_research_arbiter (
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

    localparam S_IDLE = 2'd0;
    localparam S_MEM  = 2'd1;

    reg [1:0] state;
    reg       serve_cpu;
    reg [`ADDR_WIDTH-1:0] a_addr;
    reg                   a_write;
    reg [`DATA_WIDTH-1:0] a_wdata;

    wire hit_n = (a_addr >= `ADDR_NORMAL_SRAM_BASE) && (a_addr <= `ADDR_NORMAL_SRAM_LIMIT);
    wire hit_p = (a_addr >= `ADDR_PROTECT_SRAM_BASE) && (a_addr <= `ADDR_PROTECT_SRAM_LIMIT);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
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

            unique case (state)
                S_IDLE: begin
                    if (cpu_req) begin
                        serve_cpu <= 1'b1;
                        a_addr    <= cpu_addr;
                        a_write   <= cpu_write;
                        a_wdata   <= cpu_wdata;
                        cpu_gnt   <= 1'b1; // grant-on-accept (Ibex LSU)
                        state     <= S_MEM;
                    end else if (dma_req) begin
                        serve_cpu <= 1'b0;
                        a_addr    <= dma_addr;
                        a_write   <= dma_write;
                        a_wdata   <= dma_wdata;
                        dma_gnt   <= 1'b1;
                        state     <= S_MEM;
                    end
                end
                S_MEM: begin
                    if (hit_p) begin
                        prot_req   <= 1'b1;
                        prot_addr  <= a_addr;
                        prot_write <= a_write;
                        prot_wdata <= a_wdata;
                        if (prot_valid) begin
                            if (serve_cpu) begin
                                cpu_valid <= 1'b1;
                                cpu_rdata <= prot_rdata;
                            end else begin
                                dma_valid <= 1'b1;
                                dma_rdata <= prot_rdata;
                            end
                            state <= S_IDLE;
                        end
                    end else if (hit_n) begin
                        norm_req   <= 1'b1;
                        norm_addr  <= a_addr;
                        norm_write <= a_write;
                        norm_wdata <= a_wdata;
                        if (norm_valid) begin
                            if (serve_cpu) begin
                                cpu_valid <= 1'b1;
                                cpu_rdata <= norm_rdata;
                            end else begin
                                dma_valid <= 1'b1;
                                dma_rdata <= norm_rdata;
                            end
                            state <= S_IDLE;
                        end
                    end else begin
                        // Decode miss: complete with zero data
                        if (serve_cpu) begin
                            cpu_valid <= 1'b1;
                            cpu_rdata <= 32'h0;
                        end else begin
                            dma_valid <= 1'b1;
                            dma_rdata <= 32'h0;
                        end
                        state <= S_IDLE;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
