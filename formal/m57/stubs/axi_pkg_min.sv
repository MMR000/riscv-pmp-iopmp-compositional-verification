`ifndef AXI_PKG
`define AXI_PKG
package axi_pkg;
  typedef logic [1:0] resp_t;
  typedef logic [7:0] len_t;
  typedef logic [2:0] size_t;
  typedef logic [1:0] burst_t;
  localparam RESP_OKAY   = 2'b00;
  localparam RESP_SLVERR = 2'b10;
  localparam BURST_INCR  = 2'b01;
  function automatic integer num_bytes(input size_t size);
    num_bytes = 1 << size;
  endfunction
endpackage
`endif
