// M5.7 full-RTL formal harness — real rv_iopmp_data_abstractor_axi + axi_demux closure.
`timescale 1ns/1ps

module formal_m57_fullrtl_write_path_tb (
    input logic clk,
    input logic rst_n
);

  import lint_wrapper::*;
  import rv_iopmp_pkg::*;

  localparam int unsigned DATA_W = 64;
  localparam int unsigned ADDR_W = 64;
  localparam int unsigned ID_W   = 4;

  req_nsaid_t slv_req;
  resp_t      slv_rsp;
  req_t       mst_req;
  resp_t      mst_rsp;

  logic transaction_en;
  logic [ADDR_W-1:0] txn_addr;
  logic [3:0] txn_sid;
  access_t txn_access;
  logic iopmp_allow;
  logic iopmp_ready;
  logic iopmp_valid;

  // Formal source master (write-only tests)
  logic src_aw_valid;
  logic src_w_valid;
  logic src_b_ready;
  logic [ID_W-1:0] src_aw_id;
  logic [ADDR_W-1:0] src_aw_addr;
  logic [2:0] src_aw_size;
  logic [3:0] src_nsaid;
  logic [DATA_W-1:0] src_w_data;
  logic [DATA_W/8-1:0] src_w_strb;
  logic src_w_last;

  // Downstream initiator environment
  logic ini_aw_ready;
  logic ini_w_ready;
  logic ini_b_valid;
  logic [1:0] ini_b_resp;

  // IOPMP authorization environment (one decision per transaction)
  logic env_allow;
  logic env_grant_valid;
  logic env_grant_ready;

  // ---------------- DUT ----------------
  rv_iopmp_data_abstractor_axi #(
    .SID_WIDTH(8),
    .DATA_WIDTH(DATA_W),
    .ADDR_WIDTH(ADDR_W),
    .ID_WIDTH(ID_W),
    .axi_req_nsaid_t(req_nsaid_t),
    .axi_req_t(req_t),
    .axi_rsp_t(resp_t),
    .axi_aw_chan_t(aw_chan_nsaid_t),
    .axi_w_chan_t(w_chan_t),
    .axi_b_chan_t(b_chan_t),
    .axi_ar_chan_t(ar_chan_t),
    .axi_r_chan_t(r_chan_t)
  ) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .slv_req_i(slv_req),
    .slv_rsp_o(slv_rsp),
    .mst_req_o(mst_req),
    .mst_rsp_i(mst_rsp),
    .transaction_en_o(transaction_en),
    .addr_o(txn_addr),
    .total_length_o(),
    .num_bytes_o(),
    .sid_o(txn_sid),
    .access_type_o(txn_access),
    .iopmp_allow_transaction_i(iopmp_allow),
    .ready_i(iopmp_ready),
    .valid_i(iopmp_valid)
  );

  // Tie source to DUT slave (writes only in this harness)
  assign slv_req.aw_valid = src_aw_valid;
  assign slv_req.aw.id    = src_aw_id;
  assign slv_req.aw.addr  = src_aw_addr;
  assign slv_req.aw.len   = '0;
  assign slv_req.aw.size  = src_aw_size;
  assign slv_req.aw.burst = axi_pkg::BURST_INCR;
  assign slv_req.aw.lock  = 1'b0;
  assign slv_req.aw.cache = '0;
  assign slv_req.aw.prot  = '0;
  assign slv_req.aw.qos   = '0;
  assign slv_req.aw.region= '0;
  assign slv_req.aw.atop  = '0;
  assign slv_req.aw.user  = '0;
  assign slv_req.aw.nsaid = src_nsaid;

  assign slv_req.w_valid = src_w_valid;
  assign slv_req.w.data  = src_w_data;
  assign slv_req.w.strb  = src_w_strb;
  assign slv_req.w.last  = src_w_last;
  assign slv_req.w.user  = '0;

  assign slv_req.b_ready = src_b_ready;
  assign slv_req.ar_valid = 1'b0;
  assign slv_req.r_ready  = 1'b0;

  assign mst_rsp.aw_ready = ini_aw_ready;
  assign mst_rsp.w_ready  = ini_w_ready;
  assign mst_rsp.b_valid  = ini_b_valid;
  assign mst_rsp.b.id     = mst_req.b_ready ? mst_req.aw.id : '0;
  assign mst_rsp.b.resp   = ini_b_resp;
  assign mst_rsp.b.user   = '0;
  assign mst_rsp.ar_ready = 1'b0;
  assign mst_rsp.r_valid  = 1'b0;
  assign mst_rsp.r.data   = '0;
  assign mst_rsp.r.resp   = '0;
  assign mst_rsp.r.last   = '0;
  assign mst_rsp.r.user   = '0;

  // IOPMP grant shim
  assign iopmp_allow = env_allow;
  assign iopmp_ready = env_grant_ready;
  assign iopmp_valid = env_grant_valid;

  // ---------------- Observer ----------------
  logic txn_active;
  logic txn_authorized;
  logic txn_aw_done_src;
  logic txn_w_done_src;
  logic txn_b_done_src;
  logic [7:0] txn_seq;
  logic [7:0] auth_seq;
  logic mem_written;
  logic mem_written_q;

  wire ini_aw_hs = mst_req.aw_valid && mst_rsp.aw_ready;
  wire ini_w_hs  = mst_req.w_valid && mst_rsp.w_ready;
  wire src_aw_hs = slv_req.aw_valid && slv_rsp.aw_ready;
  wire src_w_hs  = slv_req.w_valid && slv_rsp.w_ready;
  wire src_b_hs  = slv_rsp.b_valid && slv_req.b_ready;

`ifdef M57_VARIANT_ORIGINAL
  wire route_sel = dut.transaction_allowed_q;
  wire [2:0] fsm_state = dut.state_q;
`else
  wire route_sel = dut.route_select_q;
  wire write_aw_done = dut.write_aw_done_q;
  wire [2:0] fsm_state = dut.state_q;
`endif

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      txn_active <= 1'b0;
      txn_authorized <= 1'b0;
      txn_aw_done_src <= 1'b0;
      txn_w_done_src <= 1'b0;
      txn_b_done_src <= 1'b0;
      txn_seq <= '0;
      auth_seq <= '0;
      mem_written <= 1'b0;
      mem_written_q <= 1'b0;
      env_grant_ready <= 1'b0;
      env_grant_valid <= 1'b0;
    end else begin
      mem_written_q <= mem_written;
      if (ini_w_hs) mem_written <= 1'b1;

      // IOPMP ready when abstractor requests verification
      if (transaction_en)
        env_grant_ready <= 1'b1;

      // Latch authorization at grant valid (mirrors WAIT_IOPMP -> HANDSHAKE)
      if (env_grant_valid && env_grant_ready) begin
        txn_authorized <= env_allow;
        auth_seq <= txn_seq;
      end

      // Start transaction on first AW valid in IDLE
      if (!txn_active && src_aw_valid && fsm_state == 3'd0) begin
        txn_active <= 1'b1;
        txn_seq <= txn_seq + 8'd1;
        txn_authorized <= 1'b0;
        txn_aw_done_src <= 1'b0;
        txn_w_done_src <= 1'b0;
        txn_b_done_src <= 1'b0;
        mem_written <= 1'b0;
        env_grant_valid <= 1'b0;
      end

      if (src_aw_hs) txn_aw_done_src <= 1'b1;
      if (src_w_hs)  txn_w_done_src <= 1'b1;
      if (src_b_hs) begin
        txn_b_done_src <= 1'b1;
        txn_active <= 1'b0;
        env_grant_ready <= 1'b0;
        env_grant_valid <= 1'b0;
      end

      // Issue authorization decision once in WAIT_IOPMP (bounded)
      if (txn_active && env_grant_ready && !env_grant_valid)
        env_grant_valid <= 1'b1;
    end
  end

  wire txn_denied = txn_active && env_grant_valid && !env_allow;
  wire current_auth = txn_active && (auth_seq == txn_seq) && txn_authorized;

  // ---------------- Assumptions M57-FA ----------------
  default clocking cb @(posedge clk); endclocking
  default disable iff (!rst_n);

  // M57-FA-01: single-beat write
  assume property (@(posedge clk) disable iff (!rst_n) src_w_valid |-> src_w_last);

  // M57-FA-02: stable AW when waiting
  assume property (@(posedge clk) disable iff (!rst_n)
    (src_aw_valid && !slv_rsp.aw_ready) |=> $stable({src_aw_id, src_aw_addr, src_nsaid}));

  // M57-FA-03: stable W when waiting
  assume property (@(posedge clk) disable iff (!rst_n)
    (src_w_valid && !slv_rsp.w_ready) |=> $stable({src_w_data, src_w_strb, src_w_last}));

  // M57-FA-04: no read traffic
  assume property (@(posedge clk) disable iff (!rst_n) !slv_req.ar_valid);

  // M57-FA-05: bounded IOPMP grant after transaction_en
  assume property (@(posedge clk) disable iff (!rst_n)
    transaction_en |-> ##[1:8] env_grant_valid);

  // M57-FA-06: initiator B fairness
  assume property (@(posedge clk) disable iff (!rst_n)
    (mst_req.w_valid && mst_rsp.w_ready) |-> ##[1:16] ini_b_valid);

  // M57-FA-07: no overlapping source write before B
  assume property (@(posedge clk) disable iff (!rst_n)
    txn_active && !txn_b_done_src |-> !(!src_aw_valid && src_aw_valid));

  // ---------------- Safety properties M57-FP ----------------
  // M57-FP-01: denied -> no initiator AW handshake
  assert property (@(posedge clk) disable iff (!rst_n)
    (txn_active && env_grant_valid && !env_allow) |-> !ini_aw_hs);

  // M57-FP-02: denied -> no initiator W handshake
  assert property (@(posedge clk) disable iff (!rst_n)
    (txn_active && auth_seq == txn_seq && !txn_authorized) |-> !ini_w_hs);

  // M57-FP-03: denied -> no memory write
  assert property (@(posedge clk) disable iff (!rst_n)
    (txn_active && auth_seq == txn_seq && !txn_authorized) |-> !mem_written);

  // M57-FP-04 central invariant: initiator W -> authorized context
  assert property (@(posedge clk) disable iff (!rst_n)
    ini_w_hs |-> (txn_active && txn_authorized && auth_seq == txn_seq));

  // M57-FP-06: route select cleared in IDLE (proper variant)
`ifndef M57_VARIANT_ORIGINAL
  assert property (@(posedge clk) disable iff (!rst_n)
    (fsm_state == 3'd0) |-> !route_sel);
`endif

  // M57-FP-15: memory write implies authorized
  assert property (@(posedge clk) disable iff (!rst_n)
    mem_written && !mem_written_q |-> (txn_active && txn_authorized));

  // ---------------- Cover properties ----------------
  cover property (@(posedge clk) disable iff (!rst_n) env_allow && ini_w_hs);
  cover property (@(posedge clk) disable iff (!rst_n) !env_allow && src_b_hs);
  cover property (@(posedge clk) disable iff (!rst_n) fsm_state == 3'd4); // WAIT_B
  cover property (@(posedge clk) disable iff (!rst_n) src_w_valid && !src_aw_valid);
  cover property (@(posedge clk) disable iff (!rst_n) src_aw_valid && !src_w_valid);

endmodule
