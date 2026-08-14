// J3: J2 + fail-closed RST-B security_config + independent domain reset coordination.
// Synthesize with -DRST_B
module m7_ppa_j3_top (
    input  logic clk,
    input  logic rst_n,
    input  logic cfg_write_i,
    input  logic [31:0] cfg_addr_i,
    input  logic [31:0] cfg_wdata_i,
    input  logic dma_start_i,
    input  logic [31:0] dma_src_addr_i,
    input  logic [31:0] dma_dst_addr_i,
    input  logic [31:0] dma_wdata_i,
    input  logic [15:0] dma_length_i,
    input  logic [7:0]  dma_requester_id_i,
    input  logic [1:0]  dma_mode_i,
    input  logic cpu_release_i,
    input  logic dma_release_i,
    input  logic iopmp_release_i,
    input  logic sec_release_i,
    input  logic ic_release_i,
    output logic secure_ready_o,
    output logic [7:0] security_epoch_o,
    output logic iopmp_busy_o,
    output logic dma_done_o,
    output logic dma_error_o,
    output logic instr_req_o,
    output logic [31:0] instr_addr_o,
    output logic data_req_o,
    output logic data_we_o,
    output logic [31:0] data_addr_o,
    output logic data_err_o,
    output logic core_sleep_o
);
    m7_ppa_top #(.PMPEnable(1'b1), .INCLUDE_COMPOSITION(1'b1), .INCLUDE_DOMAIN_RESET(1'b1)) u (.*);
endmodule
