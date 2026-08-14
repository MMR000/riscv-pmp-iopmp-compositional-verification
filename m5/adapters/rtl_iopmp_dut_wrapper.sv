// M5 wrapper around upstream riscv_iopmp (unchanged RTL) with M5 test parameters.
`timescale 1ns/1ps

`include "common_cells/assertions.svh"
`include "register_interface/typedef.svh"

module rtl_iopmp_dut_wrapper (
    input  logic clk_i,
    input  logic rst_ni,

    output lint_wrapper::req_t        axi_iopmp_ip_req,
    input  lint_wrapper::resp_t       axi_iopmp_ip_rsp,

    input  lint_wrapper::req_slv_t    axi_iopmp_cp_req,
    output lint_wrapper::resp_slv_t   axi_iopmp_cp_rsp,

    input  lint_wrapper::req_nsaid_t  axi_iopmp_rp_req,
    output lint_wrapper::resp_t       axi_iopmp_rp_rsp,

    output logic wsi_wire_o
);

  `REG_BUS_TYPEDEF_ALL(iopmp_reg, logic[13:0], logic[31:0], logic[3:0])

  riscv_iopmp #(
    .ADDR_WIDTH (64),
    .DATA_WIDTH (64),
    .ID_WIDTH   (lint_wrapper::IdWidth),
    .ID_SLV_WIDTH (lint_wrapper::IdWidthSlv),
    .USER_WIDTH (1),
    .axi_req_nsaid_t (lint_wrapper::req_nsaid_t),
    .axi_req_t       (lint_wrapper::req_t),
    .axi_rsp_t       (lint_wrapper::resp_t),
    .axi_req_slv_t   (lint_wrapper::req_slv_t),
    .axi_rsp_slv_t   (lint_wrapper::resp_slv_t),
    .axi_aw_chan_t   (lint_wrapper::aw_chan_t),
    .axi_w_chan_t    (lint_wrapper::w_chan_t),
    .axi_b_chan_t    (lint_wrapper::b_chan_t),
    .axi_ar_chan_t   (lint_wrapper::ar_chan_t),
    .axi_r_chan_t    (lint_wrapper::r_chan_t),
    .reg_req_t       (iopmp_reg_req_t),
    .reg_rsp_t       (iopmp_reg_rsp_t),
    .NUMBER_MDS      (16),
    .NUMBER_ENTRIES  (32),
    .NUMBER_MASTERS  (2)
  ) i_riscv_iopmp (
    .clk_i           (clk_i),
    .rst_ni          (rst_ni),
    .control_req_i   (axi_iopmp_cp_req),
    .control_rsp_o   (axi_iopmp_cp_rsp),
    .receiver_req_i  (axi_iopmp_rp_req),
    .receiver_rsp_o  (axi_iopmp_rp_rsp),
    .initiator_req_o (axi_iopmp_ip_req),
    .initiator_rsp_i (axi_iopmp_ip_rsp),
    .wsi_wire_o      (wsi_wire_o)
  );

endmodule
