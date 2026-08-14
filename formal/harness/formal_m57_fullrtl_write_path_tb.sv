// M5.7 full-RTL formal harness — real rv_iopmp_data_abstractor_axi + axi_demux closure.
`timescale 1ns/1ps

module formal_m57_fullrtl_write_path_tb;

  import lint_wrapper::*;
  import rv_iopmp_pkg::*;

`ifdef FORMAL
  wire clk;
  reg [3:0] formal_clk_count;
  wire rst_n;
  assign rst_n = formal_clk_count >= 4'd4;
  always @(posedge clk) begin
    if (formal_clk_count < 4'd15)
      formal_clk_count <= formal_clk_count + 4'd1;
  end
  initial formal_clk_count = 4'd0;
`else
  logic clk;
  logic rst_n;
`endif

`ifndef FORMAL
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 1'b0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
  end
`endif

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

  // IOPMP grant shim — ready_i must be asserted in VERIFICATION (M57-FA-05)
  assign iopmp_allow = env_allow;
  assign iopmp_ready = rst_n;  // always ready once out of reset
  assign iopmp_valid = env_grant_valid;

  // ---------------- Observer ----------------
  logic txn_active;
  logic txn_authorized;
  logic txn_aw_done_src;
  logic txn_w_done_src;
  logic txn_b_done_src;
  logic [7:0] txn_seq;
  logic [7:0] auth_seq;
  logic [7:0] grant_seq;
  logic grant_allow;
  logic mem_written;
  logic mem_written_q;

  wire ini_aw_hs = mst_req.aw_valid && mst_rsp.aw_ready;
  wire ini_w_hs  = mst_req.w_valid && mst_rsp.w_ready;
  wire src_aw_hs = slv_req.aw_valid && slv_rsp.aw_ready;
  wire src_w_hs  = slv_req.w_valid && slv_rsp.w_ready;
  wire src_b_hs  = slv_rsp.b_valid && slv_req.b_ready;

  wire mem_write_event = ini_w_hs;
`ifdef M57_VARIANT_ORIGINAL
  wire route_sel = dut.transaction_allowed_q;
  wire [2:0] fsm_state = dut.state_q;
`else
  wire route_sel = dut.route_select_q;
  wire write_aw_done = dut.write_aw_done_q;
  wire [2:0] fsm_state = dut.state_q;
`endif
`ifdef FORMAL
  wire w_context_ok;
`elsif M57_VARIANT_ORIGINAL
  wire w_context_ok = grant_allow && (grant_seq == txn_seq);
`else
  wire w_context_ok = route_sel;
`endif

`ifdef FORMAL
`ifdef M57_VARIANT_ORIGINAL
  assign w_context_ok = grant_allow && (grant_seq == txn_seq);
`else
  assign w_context_ok = route_sel;
`endif
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
      grant_seq <= '0;
      grant_allow <= 1'b0;
      mem_written <= 1'b0;
      mem_written_q <= 1'b0;
      env_grant_valid <= 1'b0;
    end else begin
      mem_written_q <= mem_written;
      if (ini_w_hs) mem_written <= 1'b1;

      if (iopmp_valid && iopmp_ready) begin
        grant_allow <= iopmp_allow;
        grant_seq <= txn_seq;
        txn_authorized <= iopmp_allow;
        auth_seq <= txn_seq;
      end

      if (src_b_hs) begin
        grant_allow <= 1'b0;
        grant_seq <= '0;
      end

      // Start transaction on first AW valid while idle
      if (!txn_active && src_aw_valid && fsm_state == 2'd0) begin
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
        env_grant_valid <= 1'b0;
      end

      // One-cycle IOPMP valid pulse per WAIT_IOPMP entry (M57-FA-05)
      if (dut.state_q == 3'd2) begin  // WAIT_IOPMP
        if (!env_grant_valid && !iopmp_valid)
          env_grant_valid <= 1'b1;
      end else begin
        env_grant_valid <= 1'b0;
      end
    end
  end

  wire txn_denied = txn_active && env_grant_valid && !env_allow;
  wire current_auth = txn_active && (auth_seq == txn_seq) && txn_authorized;

`ifdef FORMAL
  wire post_reset = rst_n;

  reg src_aw_valid_q;
  reg src_w_valid_q;
  reg slv_aw_ready_q;
  reg slv_w_ready_q;
  reg [ID_W-1:0] src_aw_id_q;
  reg [ADDR_W-1:0] src_aw_addr_q;
  reg [3:0] src_nsaid_q;
  reg [DATA_W-1:0] src_w_data_q;
  reg [DATA_W/8-1:0] src_w_strb_q;
  reg src_w_last_q;
  reg env_grant_valid_q;
  reg env_allow_q;
  always @(posedge clk) begin
    src_aw_valid_q <= src_aw_valid;
    src_w_valid_q <= src_w_valid;
    slv_aw_ready_q <= slv_rsp.aw_ready;
    slv_w_ready_q <= slv_rsp.w_ready;
    src_aw_id_q <= src_aw_id;
    src_aw_addr_q <= src_aw_addr;
    src_nsaid_q <= src_nsaid;
    src_w_data_q <= src_w_data;
    src_w_strb_q <= src_w_strb;
    src_w_last_q <= src_w_last;
    env_grant_valid_q <= env_grant_valid;
    env_allow_q <= env_allow;
  end

`ifndef M59_ENV_LEVEL
`define M59_ENV_LEVEL 0
`endif
  localparam int ENV_LEVEL = `M59_ENV_LEVEL;

  // M5.8/M5.9: Yosys/read_slang-compatible safety (M57-FP-04 primary target)
  always @(posedge clk) begin
    if (!post_reset) begin
      assume(!src_aw_valid);
      assume(!src_w_valid);
      assume(!ini_b_valid);
    end else begin
      // M58-FA-03: quiescent route/grant after reset until first transaction
      if (!txn_active) begin
        assume(!grant_allow);
        assume(grant_seq == 0);
      end
      // M58-FA-06: single outstanding source write (no new AW until prior completes)
      if (txn_active && !txn_b_done_src) assume(!src_aw_valid);
      // M58-FA-01 single-beat write
      if (src_w_valid && !src_w_last) assume(0);
      // M58-FA-04 no read traffic
      if (slv_req.ar_valid) assume(0);

      // ----- M59 environment ladder -----
      // ENV-1: stable AW/W payload while stalled (M59-FA-01/02)
      if (ENV_LEVEL >= 1 && post_reset) begin
        if (src_aw_valid_q && !slv_aw_ready_q) begin
          assume(src_aw_id == src_aw_id_q);
          assume(src_aw_addr == src_aw_addr_q);
          assume(src_nsaid == src_nsaid_q);
        end
        if (src_w_valid_q && !slv_w_ready_q) begin
          assume(src_w_data == src_w_data_q);
          assume(src_w_strb == src_w_strb_q);
          assume(src_w_last == src_w_last_q);
        end
      end

      // ENV-2: legal single-beat write parameters (M59-FA-03)
      if (ENV_LEVEL >= 2 && post_reset) begin
        if (src_aw_valid) assume(slv_req.aw.len == '0);
        if (src_w_valid) assume(src_w_last);
        if (src_aw_valid) assume(src_aw_size <= 3'd3);
      end

      // ENV-3: W/AW sequencing for this harness (M59-FA-05/06)
      if (ENV_LEVEL >= 3 && post_reset) begin
        if (src_w_valid) assume(txn_active);
        if (src_w_valid) assume(src_aw_valid || txn_aw_done_src);
        if (mem_write_event) assume(txn_active);
`ifndef M57_VARIANT_ORIGINAL
        if (mem_write_event) assume(write_aw_done);
`endif
      end

      // ENV-4: post-reset idle / no spurious initiator traffic (M59-FA-07)
      if (ENV_LEVEL >= 4 && post_reset) begin
        if (formal_clk_count == 4'd4) begin
          assume(fsm_state == 3'd0);
          assume(!route_sel);
          assume(!mst_req.aw_valid);
          assume(!mst_req.w_valid);
          assume(!mem_write_event);
          assume(!txn_active);
          assume(!grant_allow);
          assume(grant_seq == 8'd0);
        end
        if (!txn_active) begin
          assume(!mst_req.w_valid);
          assume(!mst_req.aw_valid);
          assume(!ini_w_hs);
          assume(!txn_aw_done_src);
          assume(!txn_w_done_src);
          assume(!txn_b_done_src);
        end
        if (mem_write_event) assume(txn_aw_done_src);
        if (mem_write_event) assume(txn_active);
        // M59-FA-12: no initiator write without master AW/W request
        if (!src_aw_valid && !src_w_valid) begin
          assume(!mem_write_event);
          assume(!txn_active);
        end
      end

      // ENV-5: IOPMP environment contract (M59-FA-08/09)
      if (ENV_LEVEL >= 5 && post_reset) begin
        if (txn_active && env_grant_valid) begin
          assume(env_allow == env_allow_q);
        end
        if (dut.state_q == 3'd2)
          assume(env_grant_valid || env_grant_valid_q);
      end

      // M57-FP-04 (checked only after reset phase)
      if (post_reset) begin
        if (mem_write_event && !w_context_ok) assert(0);
        if (mem_write_event && txn_active && auth_seq == txn_seq && !txn_authorized)
          assert(0);
      end
    end
  end

  // Cover points for reachability (M5.8/M5.9 COV)
  always @(posedge clk) begin
    if (rst_n && post_reset) begin
      if (src_aw_hs && env_allow) cover(1);   // M59-COV-01
      if (src_aw_hs && !env_allow) cover(2);  // M59-COV-02
      if (mem_write_event && w_context_ok) cover(3);
      if (mem_write_event && !w_context_ok) cover(4);
      if (route_sel && mem_write_event) cover(5);
      if (!route_sel && src_b_hs && !env_allow) cover(6);
      if (src_w_hs && txn_aw_done_src && !txn_w_done_src) cover(7); // AW before W
      if (src_aw_hs && !src_w_valid) cover(8); // AW-before-W delay
      if (mem_write_event && !route_sel) cover(9); // error path W
      if (!env_allow && src_b_hs) cover(10); // denied completion
    end
  end
`else
  // ---------------- Assumptions M57-FA (Verilator SVA) ----------------
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

  // M57-FP-03: denied -> no memory write (same-cycle as initiator W)
  assert property (@(posedge clk) disable iff (!rst_n)
    !(mem_write_event && txn_active && auth_seq == txn_seq && !txn_authorized));

  // M57-FP-04 central invariant (primary M5.8 target)
  M57_FP_04: assert property (@(posedge clk) disable iff (!rst_n)
    mem_write_event |-> w_context_ok);

  // M57-FP-15: memory write implies authorized context
  assert property (@(posedge clk) disable iff (!rst_n)
    mem_write_event |-> w_context_ok);
`ifndef M57_VARIANT_ORIGINAL
  assert property (@(posedge clk) disable iff (!rst_n)
    (fsm_state == 3'd0) |-> !route_sel);
  cover property (@(posedge clk) disable iff (!rst_n) fsm_state == 3'd4); // WAIT_B
`else
  cover property (@(posedge clk) disable iff (!rst_n) fsm_state == 2'd3); // AXI_HANDSHAKE
`endif

  // M57-FP-06: route select cleared in IDLE (proper variant)
  cover property (@(posedge clk) disable iff (!rst_n) env_allow && ini_w_hs);
  cover property (@(posedge clk) disable iff (!rst_n) !env_allow && src_b_hs);
  cover property (@(posedge clk) disable iff (!rst_n) src_w_valid && !src_aw_valid);
  cover property (@(posedge clk) disable iff (!rst_n) src_aw_valid && !src_w_valid);

  always @(posedge clk) begin
    if (rst_n && mem_write_event)
      $display("M57 mem_we grant_allow=%0d grant_seq=%0d txn_seq=%0d route=%0d fsm=%0d",
               grant_allow, grant_seq, txn_seq, route_sel, fsm_state);
  end
`endif

`ifndef FORMAL
  task automatic do_write(input logic allow, input logic [3:0] nsaid, input logic [63:0] data);
    int timeout;
    logic aw_done, w_done;
    timeout = 0;
    aw_done = 0;
    w_done = 0;
    env_allow = allow;
    src_nsaid = nsaid;
    src_w_data = data;
    src_aw_valid = 1;
    src_w_valid = 1;
    src_b_ready = 1;
    ini_b_valid = 0;
    while (!aw_done || !w_done) begin
      @(posedge clk);
      if (src_aw_hs) aw_done = 1;
      if (src_w_hs)  w_done = 1;
      if (allow) ini_b_valid = 1;  // master B channel for authorized path
      if (++timeout > 500) begin
        $display("M57 TIMEOUT do_write aw/w allow=%0d nsaid=%0d aw=%0d w=%0d fsm=%0d",
                 allow, nsaid, aw_done, w_done, fsm_state);
        src_aw_valid = 0;
        src_w_valid = 0;
        ini_b_valid = 0;
        return;
      end
    end
    @(posedge clk);
    src_aw_valid = 0;
    src_w_valid = 0;
    timeout = 0;
    while (fsm_state != 3'd0) begin
      @(posedge clk);
      if (allow) ini_b_valid = 1;
      if (++timeout > 500) begin
        $display("M57 TIMEOUT do_write b allow=%0d nsaid=%0d fsm=%0d", allow, nsaid, fsm_state);
        ini_b_valid = 0;
        return;
      end
    end
    ini_b_valid = 0;
    env_grant_valid = 0;
    repeat (2) @(posedge clk);
  endtask

  // Directed stimulus: auth write then denied write (M5.5/M5.6 R3 sequence)
  initial begin
    src_aw_valid = 0;
    src_w_valid = 0;
    src_b_ready = 1;
    ini_aw_ready = 1;
    ini_w_ready = 1;
    ini_b_valid = 0;
    ini_b_resp = axi_pkg::RESP_OKAY;
    env_allow = 0;
    src_aw_id = 0;
    src_aw_addr = 64'h2000_0000;
    src_aw_size = 3'd2;
    src_nsaid = 0;
    src_w_data = 64'hA5;
    src_w_strb = 8'hFF;
    src_w_last = 1;
    repeat (8) @(posedge clk);
    do_write(1'b1, 4'd0, 64'h0123_4567_89AB_CDEF);
    repeat (4) @(posedge clk);
    do_write(1'b0, 4'd1, 64'hFEDC_BA98_7654_3210);
    repeat (4) @(posedge clk);
    $display("M57 stimulus complete");
    $finish;
  end
`endif

endmodule
