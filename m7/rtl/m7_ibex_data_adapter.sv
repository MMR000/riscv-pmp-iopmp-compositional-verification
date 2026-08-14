// Bridge Ibex load/store interface to research arbiter (word bus).
// Grant-on-accept from arbiter; rvalid follows one or more cycles later.
`include "m7_composed_map.vh"

module m7_ibex_data_adapter (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        ibex_req_i,
    output logic        ibex_gnt_o,
    output logic        ibex_rvalid_o,
    input  logic        ibex_we_i,
    input  logic [3:0]  ibex_be_i,
    input  logic [31:0] ibex_addr_i,
    input  logic [31:0] ibex_wdata_i,
    output logic [31:0] ibex_rdata_o,
    output logic        ibex_err_o,
    output logic        cpu_req_o,
    output logic [31:0] cpu_addr_o,
    output logic        cpu_write_o,
    output logic [31:0] cpu_wdata_o,
    input  logic        cpu_gnt_i,
    input  logic        cpu_valid_i,
    input  logic [31:0] cpu_rdata_i
);

  typedef enum logic [1:0] {ST_IDLE, ST_WAIT} state_e;
  state_e state;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state         <= ST_IDLE;
      ibex_rvalid_o <= 1'b0;
      ibex_rdata_o  <= 32'h0;
      ibex_err_o    <= 1'b0;
    end else begin
      ibex_rvalid_o <= 1'b0;
      ibex_err_o    <= 1'b0;
      unique case (state)
        ST_IDLE: begin
          if (ibex_req_i && cpu_gnt_i)
            state <= ST_WAIT;
        end
        ST_WAIT: begin
          if (cpu_valid_i) begin
            ibex_rvalid_o <= 1'b1;
            ibex_rdata_o  <= cpu_rdata_i;
            state         <= ST_IDLE;
          end
        end
        default: state <= ST_IDLE;
      endcase
    end
  end

  assign ibex_gnt_o  = (state == ST_IDLE) && ibex_req_i && cpu_gnt_i;
  assign cpu_req_o   = (state == ST_IDLE) && ibex_req_i;
  assign cpu_addr_o  = ibex_addr_i;
  assign cpu_write_o = ibex_we_i;
  assign cpu_wdata_o = ibex_wdata_i;

endmodule
