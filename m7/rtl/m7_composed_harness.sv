// Simulation harness: trusted IOPMP init + DMA orchestration for IBEX-COMP-*.
// Classified as TRUSTED_CONFIGURATION (not firmware MMIO programming).
`include "bus_pkg.vh"
`include "m7_composed_map.vh"

module m7_composed_harness #(
    parameter int unsigned LogCycles = 1
) (
    input  wire                     clk,
    input  wire                     rst_n,
    output reg                      cfg_write,
    output reg  [`ADDR_WIDTH-1:0]   cfg_addr,
    output reg  [`DATA_WIDTH-1:0]   cfg_wdata,
    output reg                      dma_start,
    output reg  [`ADDR_WIDTH-1:0]   dma_src_addr,
    output reg  [`ADDR_WIDTH-1:0]   dma_dst_addr,
    output reg  [`DATA_WIDTH-1:0]   dma_wdata,
    output reg  [15:0]              dma_length,
    output reg  [7:0]               dma_requester_id,
    output reg  [1:0]               dma_mode,
    input  wire                     dma_done,
    input  wire                     dma_error,
    output reg  [`ADDR_WIDTH-1:0]   prot_peek_addr,
    input  wire [`DATA_WIDTH-1:0]   prot_mem_word0,
    input  wire                     prot_mem_changed,
    input  wire [31:0]              test_ready,
    input  wire                     go_pulse,
    output reg  [31:0]              harness_result,
    output reg  [31:0]              harness_dma_cycle,
    output reg  [31:0]              harness_cpu_cycle,
    output reg                      harness_go_set,
    input  wire                     iopmp_txn_valid,
    input  wire                     iopmp_txn_authorized,
    input  wire [7:0]               iopmp_txn_rid
);

    localparam [`ADDR_WIDTH-1:0] PROT_WORD = `M7_PROTECT_SRAM_BASE + `M7_PROTECT_TEST_OFF;

    typedef enum logic [3:0] {
        HS_RESET,
        HS_CFG_IOPMP,
        HS_IDLE,
        HS_WAIT_READY,
        HS_DMA_ARM,
        HS_SET_GO,
        HS_DMA_WAIT,
        HS_DONE
    } hs_e;

    hs_e hs;
    reg [31:0] cycle;
    reg [7:0]  cfg_step;
    integer log_fd;
    reg need_dma;

    task automatic cfg_wr(input [`ADDR_WIDTH-1:0] a, input [`DATA_WIDTH-1:0] d);
        begin
            cfg_write <= 1'b1;
            cfg_addr  <= a;
            cfg_wdata <= d;
        end
    endtask

    initial begin
        log_fd = $fopen("m7_composed_harness.log", "w");
    end

    final begin
        $fclose(log_fd);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hs                <= HS_RESET;
            cycle             <= 32'h0;
            cfg_write         <= 1'b0;
            dma_start         <= 1'b0;
            harness_go_set    <= 1'b0;
            harness_result    <= 32'h0;
            harness_dma_cycle <= 32'h0;
            harness_cpu_cycle <= 32'h0;
            prot_peek_addr    <= PROT_WORD;
            cfg_step          <= 8'h0;
            need_dma          <= 1'b0;
        end else begin
            cycle          <= cycle + 32'h1;
            cfg_write      <= 1'b0;
            dma_start      <= 1'b0;
            harness_go_set <= 1'b0;

            case (hs)
                HS_RESET: begin
                    hs <= HS_CFG_IOPMP;
                    cfg_step <= 8'h0;
                end
                HS_CFG_IOPMP: begin
                    // Trusted IOPMP rule: protected region, authorized RID=0x01
                    unique case (cfg_step)
                        8'd0: begin cfg_wr(`ADDR_SEC_CFG_BASE + 32'h4, 32'h0); cfg_step <= 8'd1; end
                        8'd1: begin cfg_wr(`ADDR_SEC_CFG_BASE + 32'h100, `ADDR_PROTECT_SRAM_BASE); cfg_step <= 8'd2; end
                        8'd2: begin cfg_wr(`ADDR_SEC_CFG_BASE + 32'h104, `ADDR_PROTECT_SRAM_LIMIT); cfg_step <= 8'd3; end
                        8'd3: begin cfg_wr(`ADDR_SEC_CFG_BASE + 32'h108, 32'h0000_0701); cfg_step <= 8'd4; end
                        8'd4: begin cfg_wr(`ADDR_SEC_CFG_BASE + 32'h4, 32'h1); hs <= HS_IDLE; end
                        default: hs <= HS_IDLE;
                    endcase
                end
                HS_IDLE: hs <= HS_WAIT_READY;
                HS_WAIT_READY: begin
                    if (test_ready != 32'h0) begin
                        harness_cpu_cycle <= cycle;
                        unique case (test_ready)
                            32'd2, 32'd3: begin
                                need_dma <= 1'b0;
                                hs <= HS_SET_GO;
                            end
                            32'd4, 32'd5: begin
                                need_dma <= 1'b1;
                                hs <= HS_DMA_ARM;
                            end
                            32'd6, 32'd7, 32'd8: begin
                                // Start DMA before GO so concurrent tests do not
                                // sim_halt before the DMA transaction is issued.
                                need_dma <= 1'b1;
                                hs <= HS_DMA_ARM;
                            end
                            default: begin
                                need_dma <= 1'b0;
                                hs <= HS_DONE;
                            end
                        endcase
                    end
                end
                HS_DMA_ARM: begin
                    dma_dst_addr    <= PROT_WORD;
                    dma_length      <= 16'd4;
                    dma_mode        <= 2'd1;
                    dma_src_addr    <= 32'h0;
                    unique case (test_ready)
                        32'd4: begin
                            dma_wdata <= `M7_DMA_VAL_UNAUTH;
                            dma_requester_id <= `M7_UNAUTH_RID;
                        end
                        32'd5: begin
                            dma_wdata <= 32'hA11D0005;
                            dma_requester_id <= `M7_AUTH_RID;
                        end
                        32'd6: begin
                            dma_wdata <= `M7_DMA_VAL_UNAUTH;
                            dma_requester_id <= `M7_UNAUTH_RID;
                        end
                        32'd7: begin
                            dma_wdata <= `M7_DMA_VAL_AUTH;
                            dma_requester_id <= `M7_AUTH_RID;
                        end
                        32'd8: begin
                            dma_wdata <= `M7_DMA_VAL_UNAUTH;
                            dma_requester_id <= `M7_UNAUTH_RID;
                        end
                        default: begin
                            dma_wdata <= 32'h0;
                            dma_requester_id <= `M7_UNAUTH_RID;
                        end
                    endcase
                    dma_start <= 1'b1;
                    // For concurrent CPU+DMA tests, release GO after DMA start.
                    if (test_ready == 32'd6 || test_ready == 32'd7 || test_ready == 32'd8)
                        hs <= HS_SET_GO;
                    else
                        hs <= HS_DMA_WAIT;
                end
                HS_SET_GO: begin
                    harness_go_set <= 1'b1;
                    if (need_dma && (test_ready == 32'd6 || test_ready == 32'd7 ||
                                     test_ready == 32'd8 || test_ready == 32'd4 ||
                                     test_ready == 32'd5))
                        hs <= HS_DMA_WAIT;
                    else begin
                        // Non-DMA tests: publish HRESULT so trap handler does not spin.
                        harness_result <= 32'h600D00FF;
                        hs <= HS_DONE;
                    end
                end
                HS_DMA_WAIT: begin
                    if (dma_done) begin
                        harness_dma_cycle <= cycle;
                        if (dma_error)
                            harness_result <= 32'hDEAD0001; // DENY
                        else
                            harness_result <= 32'h600D0001; // ALLOW
                        if (LogCycles != 0) begin
                            $fwrite(log_fd,
                                    "TEST=%0d DMA_CYCLE=%0d ERR=%0d AUTH=%0d RID=0x%02x PEEK=0x%08x\n",
                                    test_ready, cycle, dma_error,
                                    iopmp_txn_authorized, iopmp_txn_rid, prot_mem_word0);
                        end
                        hs <= HS_DONE;
                    end
                end
                HS_DONE: ;
                default: hs <= HS_IDLE;
            endcase
        end
    end

endmodule
