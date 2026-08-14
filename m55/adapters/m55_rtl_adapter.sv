// M5.5 RTL-IOPMP diagnostic harness — baseline, matrices, internal probes.
`timescale 1ns/1ps

module m55_rtl_adapter;

  import lint_wrapper::*;
  import rv_iopmp_reg_pkg::*;

  localparam int unsigned PROTECT_LO = 32'h2000_0000;
  localparam logic [63:0] PROTECT = 64'h0000_0000_2000_0000;
  localparam logic [3:0] AUTH_NSAID = 4'd0;
  localparam logic [3:0] UNAUTH_NSAID = 4'd1;

  logic clk, rst_n;
  req_t ip_req;
  resp_t ip_rsp;
  req_slv_t cp_req;
  resp_slv_t cp_rsp;
  req_nsaid_t rp_req;
  resp_t rp_rsp;
  logic wsi_wire;
  logic mem_write, mem_read;
  logic [63:0] mem_waddr, mem_wdata, mem_raddr;

  rtl_iopmp_dut_wrapper dut (
    .clk_i(clk), .rst_ni(rst_n),
    .axi_iopmp_ip_req(ip_req), .axi_iopmp_ip_rsp(ip_rsp),
    .axi_iopmp_cp_req(cp_req), .axi_iopmp_cp_rsp(cp_rsp),
    .axi_iopmp_rp_req(rp_req), .axi_iopmp_rp_rsp(rp_rsp),
    .wsi_wire_o(wsi_wire)
  );

  axi_simple_mem #(.BASE_ADDR(PROTECT)) mem (
    .clk_i(clk), .rst_ni(rst_n),
    .slv_req_i(ip_req), .slv_rsp_o(ip_rsp),
    .write_occurred_o(mem_write), .last_write_addr_o(mem_waddr),
    .last_write_data_o(mem_wdata), .read_occurred_o(mem_read),
    .last_read_addr_o(mem_raddr)
  );

  // Hierarchical probes (non-invasive)
  wire [7:0] probe_sid       = dut.i_riscv_iopmp.sid;
  wire       probe_allow     = dut.i_riscv_iopmp.i_rv_iopmp_matching_logic.allow_transaction_o;
  wire       probe_valid     = dut.i_riscv_iopmp.i_rv_iopmp_matching_logic.valid_o;
  wire [2:0] probe_ml_state  = dut.i_riscv_iopmp.i_rv_iopmp_matching_logic.state_q;
  wire       probe_enabled   = dut.i_riscv_iopmp.iopmp_enabled;
  wire       probe_aw_req    = dut.i_riscv_iopmp.i_rv_iopmp_data_abstractor_axi.aw_request_q;
  wire       probe_ar_req    = dut.i_riscv_iopmp.i_rv_iopmp_data_abstractor_axi.ar_request_q;
  wire [3:0] probe_aw_nsaid  = dut.i_riscv_iopmp.receiver_req_i.aw.nsaid;
  wire [3:0] probe_ar_nsaid  = dut.i_riscv_iopmp.receiver_req_i.ar.nsaid;
  wire       probe_err_w      = dut.i_riscv_iopmp.i_rv_iopmp_data_abstractor_axi.i_axi_demux.mst_reqs_o[0].w_valid;
  wire       probe_mst_w      = dut.i_riscv_iopmp.initiator_req_o.w_valid;
  wire       probe_mst_aw     = dut.i_riscv_iopmp.initiator_req_o.aw_valid;
  wire       probe_txn_en    = dut.i_riscv_iopmp.transaction_en;
  wire [2:0] probe_access    = dut.i_riscv_iopmp.access_type;
  wire       probe_has_md    = dut.i_riscv_iopmp.i_rv_iopmp_matching_logic.has_md_q;
  wire       probe_txn_allow = dut.i_riscv_iopmp.i_rv_iopmp_data_abstractor_axi.transaction_allowed_q;
  wire [7:0] probe_sid_reg   = dut.i_riscv_iopmp.i_rv_iopmp_matching_logic.sid_q;
  wire [63:0] probe_srcmd0_md = {32'b0, dut.i_riscv_iopmp.srcmd_table[0].en.md.q};
  wire [63:0] probe_srcmd1_md = {32'b0, dut.i_riscv_iopmp.srcmd_table[1].en.md.q};

  logic probe_armed;
  logic [7:0] captured_sid;
  logic captured_allow, captured_has_md, captured_enabled;
  logic [2:0] captured_ml_state, captured_access;
  logic [3:0] captured_aw_nsaid, captured_ar_nsaid;
  logic captured_ip_aw, captured_txn_allow;

  always_ff @(posedge clk) begin
    if (probe_armed && probe_valid) begin
      captured_sid       <= probe_sid;
      captured_allow     <= probe_allow;
      captured_has_md    <= probe_has_md;
      captured_enabled   <= probe_enabled;
      captured_ml_state  <= probe_ml_state;
      captured_access    <= probe_access;
      captured_aw_nsaid  <= probe_aw_nsaid;
      captured_ar_nsaid  <= probe_ar_nsaid;
      captured_ip_aw     <= probe_mst_aw;
      captured_txn_allow <= probe_txn_allow;
      probe_armed        <= 1'b0;
    end
  end

  initial begin
    clk = 1'b0;
    forever begin #5 clk = ~clk; end
  end

  task automatic tick(input int n = 1);
    repeat (n) @(posedge clk);
  endtask

  task automatic reset_dut;
    rst_n = 1'b0;
    cp_req = '0;
    rp_req = '0;
    probe_armed = 1'b0;
    tick(5);
    rst_n = 1'b1;
    tick(5);
  endtask

  task automatic bus_idle;
    cp_req = '0;
    rp_req = '0;
    tick(1);
  endtask

  task automatic cfg_write(input logic [13:0] off, input logic [31:0] data);
    int timeout;
    logic [63:0] axaddr;
    bus_idle();
    axaddr = {50'b0, off};
    cp_req.aw_valid = 1'b1;
    cp_req.aw.id = '0;
    cp_req.aw.addr = axaddr;
    cp_req.aw.len = '0;
    cp_req.aw.size = 3'd2;
    cp_req.aw.burst = axi_pkg::BURST_INCR;
    cp_req.aw.prot = '0;
    cp_req.w_valid = 1'b1;
    cp_req.w.data = {32'b0, data};
    cp_req.w.strb = 8'h0F;
    cp_req.w.last = 1'b1;
    cp_req.b_ready = 1'b1;
    timeout = 0;
    while (!cp_rsp.aw_ready) begin
      @(posedge clk);
      if (++timeout > 5000) begin $display("TIMEOUT cfg_write aw off=0x%0h", off); $finish(1); end
    end
    timeout = 0;
    while (!cp_rsp.w_ready) begin
      @(posedge clk);
      if (++timeout > 5000) begin $display("TIMEOUT cfg_write w off=0x%0h", off); $finish(1); end
    end
    @(posedge clk);
    cp_req.aw_valid = 1'b0;
    cp_req.w_valid = 1'b0;
    timeout = 0;
    while (!cp_rsp.b_valid) begin
      @(posedge clk);
      if (++timeout > 5000) begin $display("TIMEOUT cfg_write b off=0x%0h", off); $finish(1); end
    end
    @(posedge clk);
    cp_req.b_ready = 1'b0;
    bus_idle();
    tick(10);
  endtask

  task automatic cfg_read(input logic [13:0] off, output logic [31:0] data);
    int timeout;
    logic [63:0] axaddr;
    bus_idle();
    axaddr = {50'b0, off};
    cp_req.ar_valid = 1'b1;
    cp_req.ar.id = '0;
    cp_req.ar.addr = axaddr;
    cp_req.ar.len = '0;
    cp_req.ar.size = 3'd2;
    cp_req.ar.burst = axi_pkg::BURST_INCR;
    cp_req.ar.prot = '0;
    cp_req.r_ready = 1'b1;
    timeout = 0;
    while (!cp_rsp.ar_ready) begin
      @(posedge clk);
      if (++timeout > 5000) begin $display("TIMEOUT cfg_read ar off=0x%0h", off); $finish(1); end
    end
    @(posedge clk);
    cp_req.ar_valid = 1'b0;
    timeout = 0;
    while (!cp_rsp.r_valid) begin
      @(posedge clk);
      if (++timeout > 5000) begin $display("TIMEOUT cfg_read r"); $finish(1); end
    end
    data = cp_rsp.r.data[31:0];
    @(posedge clk);
    cp_req.r_ready = 1'b0;
    bus_idle();
    tick(2);
  endtask

  task automatic set_enable(input logic en);
    if (en) cfg_write(IOPMP_HWCFG0_OFFSET, 32'h8000_0000);
  endtask

  task automatic install_policy(input logic [3:0] nsaid);
    logic [13:0] srcmd_off;
    srcmd_off = IOPMP_SRCMD_EN_OFFSET + (14'(nsaid) << 5);
    cfg_write(IOPMP_MDCFG_OFFSET + 14'd0, 32'd1);
    cfg_write(srcmd_off, 32'h0000_0002);
    cfg_write(IOPMP_ENTRY_ADDR_OFFSET + 14'd0, PROTECT_LO >> 2);
    cfg_write(IOPMP_ENTRY_ADDRH_OFFSET + 14'd0, 32'd0);
    cfg_write(IOPMP_ENTRY_CFG_OFFSET + 14'd0, 32'h0000_0013);
    set_enable(1'b1);
    tick(200);
  endtask

  task automatic install_policy_rw(
    input logic [3:0] nsaid,
    input logic perm_r,
    input logic perm_w
  );
    logic [13:0] srcmd_off;
    logic [31:0] cfg;
    srcmd_off = IOPMP_SRCMD_EN_OFFSET + (14'(nsaid) << 5);
    cfg = {18'b0, 2'b10, 1'b0, perm_w, perm_r}; // NA4 + R/W
    cfg_write(IOPMP_MDCFG_OFFSET + 14'd0, 32'd1);
    cfg_write(srcmd_off, 32'h0000_0002);
    cfg_write(IOPMP_ENTRY_ADDR_OFFSET + 14'd0, PROTECT_LO >> 2);
    cfg_write(IOPMP_ENTRY_ADDRH_OFFSET + 14'd0, 32'd0);
    cfg_write(IOPMP_ENTRY_CFG_OFFSET + 14'd0, cfg);
    set_enable(1'b1);
    tick(200);
  endtask

  task automatic enable_only_no_entry;
    set_enable(1'b1);
    tick(200);
  endtask

  typedef struct {
    logic forwarded;
    logic mem_changed;
    logic [1:0] b_resp;
    logic [1:0] r_resp;
    logic [63:0] rdata;
    logic ip_aw_seen;
    logic ip_w_seen;
    logic err_w_seen;
  } txn_result_t;

  task automatic dev_write(
    input logic [63:0] addr,
    input logic [63:0] data,
    input logic [3:0] nsaid,
    output txn_result_t res
  );
    int timeout;
    res = '{default:'0};
    probe_armed = 1'b1;
    bus_idle();
    rp_req.aw_valid = 1'b1;
    rp_req.aw.id = '0;
    rp_req.aw.addr = addr;
    rp_req.aw.len = '0;
    rp_req.aw.size = 3'd2;
    rp_req.aw.burst = axi_pkg::BURST_INCR;
    rp_req.aw.prot = '0;
    rp_req.aw.nsaid = nsaid;
    rp_req.w_valid = 1'b1;
    rp_req.w.data = data;
    rp_req.w.strb = 8'h0F;
    rp_req.w.last = 1'b1;
    rp_req.b_ready = 1'b1;
    timeout = 0;
    while (!rp_rsp.aw_ready) begin
      if (probe_mst_aw) res.ip_aw_seen = 1'b1;
      if (probe_mst_w) res.ip_w_seen = 1'b1;
      if (probe_err_w) res.err_w_seen = 1'b1;
      @(posedge clk);
      if (++timeout > 50000) begin $display("TIMEOUT dev_write aw"); $finish(1); end
    end
    timeout = 0;
    while (!rp_rsp.w_ready) begin
      if (probe_mst_aw) res.ip_aw_seen = 1'b1;
      if (probe_mst_w) res.ip_w_seen = 1'b1;
      if (probe_err_w) res.err_w_seen = 1'b1;
      @(posedge clk);
      if (++timeout > 50000) begin $display("TIMEOUT dev_write w"); $finish(1); end
    end
    @(posedge clk);
    rp_req.aw_valid = 1'b0;
    rp_req.w_valid = 1'b0;
    timeout = 0;
    while (!rp_rsp.b_valid) begin
      @(posedge clk);
      if (++timeout > 20000) begin $display("TIMEOUT dev_write b"); $finish(1); end
    end
    res.b_resp = rp_rsp.b.resp;
    res.forwarded = (rp_rsp.b.resp == axi_pkg::RESP_OKAY);
    res.mem_changed = mem_write;
    @(posedge clk);
    rp_req.b_ready = 1'b0;
    bus_idle();
    tick(5);
  endtask

  task automatic dev_read(
    input logic [63:0] addr,
    input logic [3:0] nsaid,
    output txn_result_t res
  );
    int timeout;
    res = '{default:'0};
    probe_armed = 1'b1;
    bus_idle();
    rp_req.ar_valid = 1'b1;
    rp_req.ar.id = '0;
    rp_req.ar.addr = addr;
    rp_req.ar.len = '0;
    rp_req.ar.size = 3'd2;
    rp_req.ar.burst = axi_pkg::BURST_INCR;
    rp_req.ar.prot = '0;
    rp_req.ar.nsaid = nsaid;
    rp_req.r_ready = 1'b1;
    timeout = 0;
    while (!rp_rsp.ar_ready) begin
      @(posedge clk);
      if (++timeout > 20000) begin $display("TIMEOUT dev_read ar"); $finish(1); end
    end
    @(posedge clk);
    rp_req.ar_valid = 1'b0;
    timeout = 0;
    while (!rp_rsp.r_valid) begin
      @(posedge clk);
      if (++timeout > 20000) begin $display("TIMEOUT dev_read r"); $finish(1); end
    end
    res.r_resp = rp_rsp.r.resp;
    res.rdata = rp_rsp.r.data;
    res.forwarded = (rp_rsp.r.resp == axi_pkg::RESP_OKAY);
    res.mem_changed = mem_read;
    @(posedge clk);
    rp_req.r_ready = 1'b0;
    bus_idle();
    tick(5);
  endtask

  function automatic string classify_rw(input txn_result_t r, input logic is_write);
    if (is_write) begin
      if (r.mem_changed && r.b_resp == axi_pkg::RESP_OKAY) return "ALLOW";
      if (r.b_resp == axi_pkg::RESP_SLVERR || !r.mem_changed) return "DENY";
    end else begin
      if (r.mem_changed && r.r_resp == axi_pkg::RESP_OKAY) return "ALLOW";
      if (r.r_resp == axi_pkg::RESP_SLVERR || !r.mem_changed) return "DENY";
    end
    return "INCONCLUSIVE";
  endfunction

  task automatic dump_config(input int fd);
    logic [31:0] v;
    cfg_read(IOPMP_HWCFG0_OFFSET, v);
    $fwrite(fd, "HWCFG0=0x%08x enable=%0d\n", v, v[31]);
    cfg_read(IOPMP_HWCFG1_OFFSET, v);
    $fwrite(fd, "HWCFG1=0x%08x sid_num=%0d entry_num=%0d\n", v, v[15:0], v[31:16]);
    cfg_read(IOPMP_MDCFG_OFFSET, v);
    $fwrite(fd, "MDCFG0=0x%08x\n", v);
    cfg_read(IOPMP_SRCMD_EN_OFFSET + 14'h000, v);
    $fwrite(fd, "SRCMD_EN0=0x%08x\n", v);
    cfg_read(IOPMP_SRCMD_EN_OFFSET + 14'h020, v);
    $fwrite(fd, "SRCMD_EN1=0x%08x\n", v);
    cfg_read(IOPMP_ENTRY_ADDR_OFFSET, v);
    $fwrite(fd, "ENTRY0_ADDR=0x%08x\n", v);
    cfg_read(IOPMP_ENTRY_CFG_OFFSET, v);
    $fwrite(fd, "ENTRY0_CFG=0x%08x\n", v);
    $fwrite(fd, "RTL_srcmd_table[0].en.md=0x%07x\n", probe_srcmd0_md[30:0]);
    $fwrite(fd, "RTL_srcmd_table[1].en.md=0x%07x\n", probe_srcmd1_md[30:0]);
  endtask

  task automatic log_probe(input string tag, input logic [3:0] nsaid, input string op, input txn_result_t tr, input int fd);
    string result = classify_rw(tr, op == "WRITE");
    $fwrite(fd, "=== %s ===\n", tag);
    $fwrite(fd, "NSAID=%0d operation=%s observed=%s\n", nsaid, op, result);
    $fwrite(fd, "BRESP/RRESP write=%0d read=%0d mem_eff=%0d\n", tr.b_resp, tr.r_resp, tr.mem_changed);
    $fwrite(fd, "ip_mst_aw_seen=%0d ip_mst_w_seen=%0d ip_err_w_seen=%0d forwarded=%0d\n",
            tr.ip_aw_seen, tr.ip_w_seen, tr.err_w_seen, tr.forwarded);
    $fwrite(fd, "probe_aw_nsaid=%0d probe_ar_nsaid=%0d aw_req_q=%0d ar_req_q=%0d\n",
            probe_aw_nsaid, probe_ar_nsaid, probe_aw_req, probe_ar_req);
    $fwrite(fd, "captured_sid=%0d sid_q=%0d enabled=%0d has_md=%0d allow=%0d ml_state=%0d access=%0d txn_allow_q=%0d\n",
            captured_sid, probe_sid_reg, captured_enabled, captured_has_md, captured_allow,
            captured_ml_state, captured_access, captured_txn_allow);
    $display("M55 %s nsaid=%0d %s sid=%0d allow=%0d has_md=%0d aw_nsaid=%0d ar_nsaid=%0d",
             tag, nsaid, result, captured_sid, captured_allow, captured_has_md,
             captured_aw_nsaid, captured_ar_nsaid);
  endtask

  integer csv, cfg_fd, baseline_fd;
  string mode;
  txn_result_t tr;

  initial begin
    mode = "all";
    void'($value$plusargs("M55_MODE=%s", mode));

    if (mode == "baseline" || mode == "all") begin
      if ($test$plusargs("M55_VCD")) begin
        $dumpfile("results/m55/baseline/M55-WRITE-CE-BASELINE.vcd");
        $dumpvars(0, m55_rtl_adapter);
      end
      baseline_fd = $fopen("results/m55/baseline/M55-WRITE-CE-BASELINE.txt", "w");
      cfg_fd = $fopen("results/m55/config_dump.txt", "w");
      reset_dut();
      install_policy(AUTH_NSAID);
      dump_config(cfg_fd);
      // Exact M5 EV-2 sequence: authorized write BEFORE unauthorized write (no reset)
      dev_write(PROTECT, 64'h0123_4567_89AB_CDEF, AUTH_NSAID, tr);
      log_probe("M55-AUTH-WRITE-CONTROL", AUTH_NSAID, "WRITE", tr, baseline_fd);
      dev_write(PROTECT, 64'hFEDC_BA98_7654_3210, UNAUTH_NSAID, tr);
      log_probe("M55-WRITE-CE-BASELINE", UNAUTH_NSAID, "WRITE", tr, baseline_fd);
      dev_read(PROTECT, UNAUTH_NSAID, tr);
      log_probe("M55-READ-CONTROL", UNAUTH_NSAID, "READ", tr, baseline_fd);
      $fclose(baseline_fd);
      $fclose(cfg_fd);
    end

    if (mode == "nsaid" || mode == "all") begin
      csv = $fopen("results/tables/m55_nsaid_matrix.csv", "w");
      $fwrite(csv, "NSAID,derived_RRID,READ_result,WRITE_result,RRESP,BRESP,read_forwarded,write_forwarded,memory_modified,classification\n");
      reset_dut();
      install_policy(AUTH_NSAID);
      for (int nsaid = 0; nsaid < 16; nsaid++) begin
        txn_result_t tr_r, tr_w;
        string rr, wr;
        reset_dut();
        install_policy(AUTH_NSAID);
        dev_read(PROTECT, 4'(nsaid), tr_r);
        dev_write(PROTECT, 64'h1000 + nsaid, 4'(nsaid), tr_w);
        rr = classify_rw(tr_r, 1'b0);
        wr = classify_rw(tr_w, 1'b1);
        $fwrite(csv, "%0d,%0d,%s,%s,%0d,%0d,%0d,%0d,%0d,%s\n",
                nsaid, nsaid, rr, wr, tr_r.r_resp, tr_w.b_resp,
                tr_r.forwarded, tr_w.forwarded, tr_w.mem_changed,
                (rr == wr) ? "SYMMETRIC" : "ASymmetric");
      end
      $fclose(csv);
    end

    if (mode == "permissions" || mode == "all") begin
      csv = $fopen("results/tables/m55_permission_matrix.csv", "w");
      $fwrite(csv, "perm_r,perm_w,READ_result,WRITE_result,RRESP,BRESP,memory_modified,classification\n");
      for (int pr = 0; pr <= 1; pr++) begin
        for (int pw = 0; pw <= 1; pw++) begin
          txn_result_t tr_r, tr_w;
          string rr, wr;
          reset_dut();
          install_policy_rw(AUTH_NSAID, logic'(pr), logic'(pw));
          dev_read(PROTECT, AUTH_NSAID, tr_r);
          dev_write(PROTECT, 64'hA5A5_0000_0000_0000 + pr + pw, AUTH_NSAID, tr_w);
          rr = classify_rw(tr_r, 1'b0);
          wr = classify_rw(tr_w, 1'b1);
          $fwrite(csv, "%0d,%0d,%s,%s,%0d,%0d,%0d,MAPPED_AUTH\n", pr, pw, rr, wr,
                  tr_r.r_resp, tr_w.b_resp, tr_w.mem_changed);
        end
      end
      $fclose(csv);
    end

    if (mode == "entry" || mode == "all") begin
      csv = $fopen("results/tables/m55_entry_matrix.csv", "w");
      $fwrite(csv, "case,nsaid,READ_result,WRITE_result,RRESP,BRESP,memory_modified\n");
      reset_dut();
      install_policy(AUTH_NSAID);
      dev_read(PROTECT, AUTH_NSAID, tr);
      $fwrite(csv, "matching_entry_auth,%0d,%s,,,%0d,,\n", AUTH_NSAID, classify_rw(tr, 1'b0), tr.r_resp);
      dev_write(PROTECT, 64'h1, AUTH_NSAID, tr);
      $fwrite(csv, "matching_entry_auth,,,%s,,%0d,%0d\n", classify_rw(tr, 1'b1), tr.b_resp, tr.mem_changed);
      dev_read(PROTECT, UNAUTH_NSAID, tr);
      $fwrite(csv, "matching_entry_unauth,%0d,%s,,,%0d,,\n", UNAUTH_NSAID, classify_rw(tr, 1'b0), tr.r_resp);
      dev_write(PROTECT, 64'h2, UNAUTH_NSAID, tr);
      $fwrite(csv, "matching_entry_unauth,,,%s,,%0d,%0d\n", classify_rw(tr, 1'b1), tr.b_resp, tr.mem_changed);
      dev_read(PROTECT + 64'h1000, AUTH_NSAID, tr);
      $fwrite(csv, "no_matching_entry,%0d,%s,,,%0d,,\n", AUTH_NSAID, classify_rw(tr, 1'b0), tr.r_resp);
      dev_write(PROTECT + 64'h1000, 64'h3, AUTH_NSAID, tr);
      $fwrite(csv, "no_matching_entry,,,%s,,%0d,%0d\n", classify_rw(tr, 1'b1), tr.b_resp, tr.mem_changed);
      reset_dut();
      enable_only_no_entry();
      dev_read(PROTECT, AUTH_NSAID, tr);
      $fwrite(csv, "no_entry_enable,%0d,%s,,,%0d,,\n", AUTH_NSAID, classify_rw(tr, 1'b0), tr.r_resp);
      dev_write(PROTECT, 64'h4, AUTH_NSAID, tr);
      $fwrite(csv, "no_entry_enable,,,%s,,%0d,%0d\n", classify_rw(tr, 1'b1), tr.b_resp, tr.mem_changed);
      $fclose(csv);
    end

    if (mode == "config" || mode == "all") begin
      cfg_fd = $fopen("results/m55/config_dump.txt", "w");
      reset_dut();
      install_policy(AUTH_NSAID);
      dump_config(cfg_fd);
      $fclose(cfg_fd);
    end

    if (mode == "random" || mode == "all") begin
      int n = 500;
      int seed = 55;
      void'($value$plusargs("M55_RANDOM_N=%d", n));
      void'($value$plusargs("M55_RANDOM_SEED=%d", seed));
      csv = $fopen("results/m55/m55_random.csv", "w");
      $fwrite(csv, "seed,nsaid,address,operation,configured,observed,bresp,rresp,memory_effect\n");
      for (int i = 0; i < n; i++) begin
        txn_result_t tr_w, tr_r;
        logic [3:0] nsaid;
        reset_dut();
        if ((i % 3) != 0) install_policy(AUTH_NSAID);
        else enable_only_no_entry();
        nsaid = 4'((i + seed) % 16);
        if (i % 2 == 0) begin
          dev_write(PROTECT + ((i * 13) & 64'hFF), 64'(i), nsaid, tr_w);
          $fwrite(csv, "%0d,%0d,0x%016x,write,%0d,%s,%0d,, %0d\n",
                  seed, nsaid, PROTECT + ((i * 13) & 64'hFF), (i % 3) != 0,
                  classify_rw(tr_w, 1'b1), tr_w.b_resp, tr_w.mem_changed);
        end else begin
          dev_read(PROTECT + ((i * 13) & 64'hFF), nsaid, tr_r);
          $fwrite(csv, "%0d,%0d,0x%016x,read,%0d,%s,,%0d,%0d\n",
                  seed, nsaid, PROTECT + ((i * 13) & 64'hFF), (i % 3) != 0,
                  classify_rw(tr_r, 1'b0), tr_r.r_resp, tr_r.mem_changed);
        end
      end
      $fclose(csv);
    end

    $display("M55 diagnostic complete mode=%s", mode);
    $finish(0);
  end

endmodule
