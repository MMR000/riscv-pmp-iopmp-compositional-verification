`ifndef RV_IOPMP_PKG
`define RV_IOPMP_PKG
package rv_iopmp_pkg;
  typedef enum logic [2:0] {
    ACCESS_READ  = 3'b001,
    ACCESS_WRITE = 3'b010
  } access_t;
endpackage
`endif
