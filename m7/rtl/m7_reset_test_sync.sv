// Phase C mailbox: Phase B sync + PMP_READY firmware milestone.
`include "m7_composed_map.vh"

module m7_reset_test_sync (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        req_i,
    input  logic        we_i,
    input  logic [3:0]  be_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic        rvalid_o,
    output logic [31:0] rdata_o,
    output logic [31:0] test_ready_o,
    output logic        go_o,
    input  logic        go_set_i,
    input  logic [31:0] harness_result_i,
    input  logic [31:0] harness_dma_cycle_i,
    input  logic [31:0] harness_cpu_cycle_i,
    output logic        pmp_ready_o
);

  localparam int unsigned OFF_READY     = 32'h00;
  localparam int unsigned OFF_GO        = 32'h04;
  localparam int unsigned OFF_RESULT    = 32'h08;
  localparam int unsigned OFF_DMA_CYC   = 32'h0C;
  localparam int unsigned OFF_CPU_CYC   = 32'h10;
  localparam int unsigned OFF_HRESULT   = 32'h14;
  localparam int unsigned OFF_PMP_READY = 32'h28;

  logic [31:0] test_ready, test_result;
  logic        go, pmp_ready, rvalid_q;

  assign test_ready_o = test_ready;
  assign go_o         = go;
  assign pmp_ready_o  = pmp_ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      test_ready  <= 32'h0;
      go          <= 1'b0;
      test_result <= 32'h0;
      pmp_ready   <= 1'b0;
      rvalid_q    <= 1'b0;
      rdata_o     <= 32'h0;
    end else begin
      rvalid_q <= req_i;
      if (go_set_i) go <= 1'b1;
      if (req_i && we_i && be_i[0]) begin
        unique case (addr_i[7:0])
          OFF_READY[7:0]:     test_ready  <= wdata_i;
          OFF_GO[7:0]:        go          <= (wdata_i[0] != 1'b0);
          OFF_RESULT[7:0]:    test_result <= wdata_i;
          OFF_PMP_READY[7:0]: pmp_ready   <= (wdata_i[0] != 1'b0);
          default: ;
        endcase
      end
      if (req_i && !we_i) begin
        unique case (addr_i[7:0])
          OFF_READY[7:0]:     rdata_o <= test_ready;
          OFF_GO[7:0]:        rdata_o <= {31'h0, go};
          OFF_RESULT[7:0]:    rdata_o <= test_result;
          OFF_DMA_CYC[7:0]:   rdata_o <= harness_dma_cycle_i;
          OFF_CPU_CYC[7:0]:   rdata_o <= harness_cpu_cycle_i;
          OFF_HRESULT[7:0]:   rdata_o <= harness_result_i;
          OFF_PMP_READY[7:0]: rdata_o <= {31'h0, pmp_ready};
          default:            rdata_o <= 32'h0;
        endcase
      end
    end
  end

  assign rvalid_o = rvalid_q;

endmodule
