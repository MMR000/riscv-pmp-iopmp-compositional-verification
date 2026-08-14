// M5 minimal AXI4 memory slave for RTL-IOPMP initiator port observation.
`timescale 1ns/1ps

module axi_simple_mem #(
    parameter int unsigned ADDR_WIDTH = 64,
    parameter int unsigned DATA_WIDTH = 64,
    parameter int unsigned ID_WIDTH   = 4,
    parameter int unsigned USER_WIDTH = 1,
    parameter int unsigned MEM_BYTES  = 65536,
    parameter logic [ADDR_WIDTH-1:0] BASE_ADDR = 64'h0000_0000_2000_0000
) (
    input  logic clk_i,
    input  logic rst_ni,
    // lint_wrapper master view (IOPMP initiator)
    input  lint_wrapper::req_t   slv_req_i,
    output lint_wrapper::resp_t  slv_rsp_o,
    output logic                 write_occurred_o,
    output logic [ADDR_WIDTH-1:0] last_write_addr_o,
    output logic [DATA_WIDTH-1:0] last_write_data_o,
    output logic                 read_occurred_o,
    output logic [ADDR_WIDTH-1:0] last_read_addr_o
);

  import lint_wrapper::*;

  logic [DATA_WIDTH-1:0] mem [0:MEM_BYTES/8-1];

  typedef enum logic [1:0] {IDLE, W_DATA, W_RESP, R_DATA} st_e;
  st_e state;
  logic w_ready_q;

  logic [ADDR_WIDTH-1:0] awaddr_q;
  logic [ID_WIDTH-1:0]   awid_q;
  logic [ADDR_WIDTH-1:0] araddr_q;
  logic [ID_WIDTH-1:0]   arid_q;

  function automatic logic [63:0] addr_to_idx(input logic [ADDR_WIDTH-1:0] addr);
    logic [63:0] off;
    off = addr - BASE_ADDR;
    return off >> 3;
  endfunction

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state <= IDLE;
      slv_rsp_o.aw_ready <= 1'b0;
      slv_rsp_o.w_ready  <= 1'b0;
      slv_rsp_o.b_valid  <= 1'b0;
      slv_rsp_o.ar_ready <= 1'b0;
      slv_rsp_o.r_valid  <= 1'b0;
      slv_rsp_o.b.id     <= '0;
      slv_rsp_o.b.resp   <= axi_pkg::RESP_OKAY;
      slv_rsp_o.r.id     <= '0;
      slv_rsp_o.r.data   <= '0;
      slv_rsp_o.r.resp   <= axi_pkg::RESP_OKAY;
      slv_rsp_o.r.last   <= 1'b0;
      write_occurred_o   <= 1'b0;
      read_occurred_o    <= 1'b0;
      last_write_addr_o  <= '0;
      last_write_data_o  <= '0;
      last_read_addr_o   <= '0;
    end else begin
      write_occurred_o <= 1'b0;
      read_occurred_o  <= 1'b0;
      slv_rsp_o.b_valid <= 1'b0;
      slv_rsp_o.r_valid <= 1'b0;
      slv_rsp_o.aw_ready <= 1'b0;
      slv_rsp_o.w_ready  <= 1'b0;
      slv_rsp_o.ar_ready <= 1'b0;

      unique case (state)
        IDLE: begin
          if (slv_req_i.aw_valid) begin
            awaddr_q <= slv_req_i.aw.addr;
            awid_q   <= slv_req_i.aw.id;
            slv_rsp_o.aw_ready <= 1'b1;
            state <= W_DATA;
          end else if (slv_req_i.ar_valid) begin
            araddr_q <= slv_req_i.ar.addr;
            arid_q   <= slv_req_i.ar.id;
            slv_rsp_o.ar_ready <= 1'b1;
            state <= R_DATA;
          end
        end
        W_DATA: begin
          slv_rsp_o.w_ready <= 1'b1;
          w_ready_q = slv_rsp_o.w_ready;
          if (slv_req_i.w_valid && w_ready_q) begin
            automatic logic [63:0] idx = addr_to_idx(awaddr_q);
            if (idx < MEM_BYTES/8) begin
              mem[idx] <= slv_req_i.w.data;
            end
            last_write_addr_o <= awaddr_q;
            last_write_data_o <= slv_req_i.w.data;
            write_occurred_o  <= 1'b1;
            slv_rsp_o.b.id    <= awid_q;
            slv_rsp_o.b.resp  <= axi_pkg::RESP_OKAY;
            slv_rsp_o.b_valid <= 1'b1;
            state <= IDLE;
          end
        end
        R_DATA: begin
          automatic logic [63:0] idx = addr_to_idx(araddr_q);
          slv_rsp_o.r.id   <= arid_q;
          slv_rsp_o.r.data <= (idx < MEM_BYTES/8) ? mem[idx] : 64'hDEADBEEFCAFEBABE;
          slv_rsp_o.r.resp <= axi_pkg::RESP_OKAY;
          slv_rsp_o.r.last <= 1'b1;
          slv_rsp_o.r_valid <= 1'b1;
          last_read_addr_o <= araddr_q;
          read_occurred_o  <= 1'b1;
          state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end
  end

endmodule
