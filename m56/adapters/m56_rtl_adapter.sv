// M5.6 RTL-IOPMP write-path repair validation harness.
`timescale 1ns/1ps

module m56_rtl_adapter;

  import lint_wrapper::*;
  import rv_iopmp_reg_pkg::*;

  localparam int unsigned PROTECT_LO = 32'h2000_0000;
  localparam logic [63:0] PROTECT = 64'h0000_0000_2000_0000;
  localparam logic [3:0] AUTH_NSAID = 4'd0;
  localparam logic [3:0] UNAUTH_NSAID = 4'd1;

  localparam int TIMEOUT_SHORT = 20000;
  localparam int TIMEOUT_LONG  = 50000;

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
  int unsigned mem_write_count;
  int unsigned mem_read_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_write_count <= 0;
      mem_read_count  <= 0;
    end else begin
      if (mem_write) mem_write_count <= mem_write_count + 1;
      if (mem_read)  mem_read_count  <= mem_read_count + 1;
    end
  end

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
  wire       probe_allow     = dut.i_riscv_iopmp.i_rv_iopmp_matching_logic.allow_transaction_o;
  wire       probe_valid     = dut.i_riscv_iopmp.i_rv_iopmp_matching_logic.valid_o;
  wire       probe_enabled   = dut.i_riscv_iopmp.iopmp_enabled;
  wire       probe_err_w     = dut.i_riscv_iopmp.i_rv_iopmp_data_abstractor_axi.i_axi_demux.mst_reqs_o[0].w_valid;
  wire       probe_mst_w     = dut.i_riscv_iopmp.initiator_req_o.w_valid;
  wire       probe_mst_aw    = dut.i_riscv_iopmp.initiator_req_o.aw_valid;
  wire       probe_txn_allow = dut.i_riscv_iopmp.i_rv_iopmp_data_abstractor_axi.transaction_allowed_q;
  // route_select_q exists only in proper repair RTL; use transaction_allowed_q for all builds.
  wire       probe_route_select = probe_txn_allow;

  logic probe_armed;
  logic captured_allow;
  logic captured_valid;

  always_ff @(posedge clk) begin
    if (probe_armed && probe_valid) begin
      captured_allow <= probe_allow;
      captured_valid <= 1'b1;
      probe_armed    <= 1'b0;
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
    captured_valid = 1'b0;
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
    cfg = {18'b0, 2'b10, 1'b0, perm_w, perm_r};
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
    logic dst_aw;
    logic dst_w;
    logic allow_captured;
    logic completed;
    logic deadlock;
  } txn_result_t;

  task automatic sample_probes(input txn_result_t cur, output txn_result_t nxt);
    nxt = cur;
    if (probe_mst_aw) nxt.dst_aw = 1'b1;
    if (probe_mst_w)  nxt.dst_w  = 1'b1;
    if (probe_armed && probe_valid) nxt.allow_captured = probe_allow;
  endtask

  task automatic dev_write_timed(
    input logic [63:0] addr,
    input logic [63:0] data,
    input logic [3:0] nsaid,
    input int aw_delay,
    input int w_delay,
    input logic hold_b,
    output txn_result_t res
  );
    int timeout;
    int cycle;
    logic aw_hs, w_hs;
    int unsigned wc_start;
    txn_result_t cur;
    cur = '{default:'0};
    res = '{default:'0};
    probe_armed = 1'b1;
    captured_allow = 1'b0;
    captured_valid = 1'b0;
    bus_idle();

    rp_req.aw.id = '0;
    rp_req.aw.addr = addr;
    rp_req.aw.len = '0;
    rp_req.aw.size = 3'd2;
    rp_req.aw.burst = axi_pkg::BURST_INCR;
    rp_req.aw.prot = '0;
    rp_req.aw.nsaid = nsaid;
    rp_req.w.data = data;
    rp_req.w.strb = 8'h0F;
    rp_req.w.last = 1'b1;
    rp_req.aw_valid = 1'b0;
    rp_req.w_valid = 1'b0;
    rp_req.b_ready = 1'b0;

    aw_hs = 1'b0;
    w_hs = 1'b0;
    wc_start = mem_write_count;
    cycle = 0;
    timeout = 0;

    while (!aw_hs || !w_hs) begin
      if (cycle >= aw_delay) rp_req.aw_valid = 1'b1;
      if (cycle >= w_delay)  rp_req.w_valid = 1'b1;
      sample_probes(cur, cur);
      if (probe_valid && !res.allow_captured) res.allow_captured = probe_allow;
      if (rp_req.aw_valid && rp_rsp.aw_ready) aw_hs = 1'b1;
      if (rp_req.w_valid && rp_rsp.w_ready) w_hs = 1'b1;
      res.dst_aw = cur.dst_aw;
      res.dst_w  = cur.dst_w;
      if (!res.allow_captured && captured_valid) res.allow_captured = captured_allow;
      cycle = cycle + 1;
      if (++timeout > TIMEOUT_LONG) begin
        res.deadlock = 1'b1;
        $display("TIMEOUT dev_write_timed aw/w addr=0x%016x nsaid=%0d", addr, nsaid);
        rp_req.aw_valid = 1'b0;
        rp_req.w_valid = 1'b0;
        bus_idle();
        return;
      end
      @(posedge clk);
    end

    @(posedge clk);
    rp_req.aw_valid = 1'b0;
    rp_req.w_valid = 1'b0;

    if (hold_b) tick(8);
    rp_req.b_ready = 1'b1;

    timeout = 0;
    while (!rp_rsp.b_valid) begin
      sample_probes(cur, cur);
      res.dst_aw = cur.dst_aw;
      res.dst_w  = cur.dst_w;
      if (++timeout > TIMEOUT_LONG) begin
        res.deadlock = 1'b1;
        $display("TIMEOUT dev_write_timed b addr=0x%016x nsaid=%0d", addr, nsaid);
        rp_req.b_ready = 1'b0;
        bus_idle();
        return;
      end
      @(posedge clk);
    end

    res.b_resp = rp_rsp.b.resp;
    res.forwarded = (rp_rsp.b.resp == axi_pkg::RESP_OKAY);
    res.mem_changed = (mem_write_count != wc_start);
    res.completed = 1'b1;
    if (!res.allow_captured && captured_valid) res.allow_captured = captured_allow;

    @(posedge clk);
    rp_req.b_ready = 1'b0;
    bus_idle();
    tick(3);
  endtask

  task automatic dev_read_timed(
    input logic [63:0] addr,
    input logic [3:0] nsaid,
    input int ar_delay,
    output txn_result_t res
  );
    int timeout;
    int unsigned rc_start;
    res = '{default:'0};
    probe_armed = 1'b1;
    captured_allow = 1'b0;
    captured_valid = 1'b0;
    bus_idle();

    rp_req.ar.id = '0;
    rp_req.ar.addr = addr;
    rp_req.ar.len = '0;
    rp_req.ar.size = 3'd2;
    rp_req.ar.burst = axi_pkg::BURST_INCR;
    rp_req.ar.prot = '0;
    rp_req.ar.nsaid = nsaid;
    rp_req.ar_valid = 1'b0;
    rp_req.aw_valid = 1'b0;
    rp_req.w_valid = 1'b0;
    rp_req.r_ready = 1'b1;

    rc_start = mem_read_count;
    if (ar_delay > 0) tick(ar_delay);

    rp_req.ar_valid = 1'b1;
    timeout = 0;
    while (!rp_rsp.ar_ready) begin
      if (probe_valid && !res.allow_captured) res.allow_captured = probe_allow;
      @(posedge clk);
      if (++timeout > TIMEOUT_LONG) begin
        res.deadlock = 1'b1;
        $display("TIMEOUT dev_read_timed ar addr=0x%016x nsaid=%0d", addr, nsaid);
        rp_req.ar_valid = 1'b0;
        rp_req.r_ready = 1'b0;
        bus_idle();
        return;
      end
    end
    if (!res.allow_captured && captured_valid) res.allow_captured = captured_allow;

    @(posedge clk);
    rp_req.ar_valid = 1'b0;

    timeout = 0;
    while (!rp_rsp.r_valid) begin
      if (probe_valid && !res.allow_captured) res.allow_captured = probe_allow;
      @(posedge clk);
      if (++timeout > TIMEOUT_LONG) begin
        res.deadlock = 1'b1;
        $display("TIMEOUT dev_read_timed r addr=0x%016x nsaid=%0d", addr, nsaid);
        rp_req.r_ready = 1'b0;
        bus_idle();
        return;
      end
    end

    res.r_resp = rp_rsp.r.resp;
    res.rdata = rp_rsp.r.data;
    res.forwarded = (rp_rsp.r.resp == axi_pkg::RESP_OKAY);
    res.mem_changed = (mem_read_count != rc_start);
    res.completed = 1'b1;
    if (!res.allow_captured && captured_valid) res.allow_captured = captured_allow;

    @(posedge clk);
    rp_req.r_ready = 1'b0;
    bus_idle();
    tick(3);
  endtask

  task automatic dev_write(
    input logic [63:0] addr,
    input logic [63:0] data,
    input logic [3:0] nsaid,
    output txn_result_t res
  );
    dev_write_timed(addr, data, nsaid, 0, 0, 1'b0, res);
  endtask

  task automatic dev_read(
    input logic [63:0] addr,
    input logic [3:0] nsaid,
    output txn_result_t res
  );
    dev_read_timed(addr, nsaid, 0, res);
  endtask

  function automatic string classify_write(input txn_result_t r);
    if (r.deadlock) return "DEADLOCK";
    if (r.mem_changed && r.b_resp == axi_pkg::RESP_OKAY) return "ALLOW";
    if (r.b_resp == axi_pkg::RESP_SLVERR || !r.mem_changed) return "DENY";
    return "INCONCLUSIVE";
  endfunction

  function automatic string classify_read(input txn_result_t r);
    if (r.deadlock) return "DEADLOCK";
    if (r.r_resp == axi_pkg::RESP_OKAY && r.completed) return "ALLOW";
    if (r.r_resp == axi_pkg::RESP_SLVERR) return "DENY";
    return "INCONCLUSIVE";
  endfunction

  function automatic string bresp_str(input logic [1:0] resp);
    if (resp == axi_pkg::RESP_OKAY) return "OKAY";
    if (resp == axi_pkg::RESP_SLVERR) return "SLVERR";
    return $sformatf("%0d", resp);
  endfunction

  function automatic string get_fix_mode;
    string fix;
    fix = "proper";
    void'($value$plusargs("M56_FIX=%s", fix));
    return fix;
  endfunction

  function automatic string get_git_commit;
    string c;
    c = "unknown";
    void'($value$plusargs("M56_GIT_COMMIT=%s", c));
    return c;
  endfunction

  task automatic log_txn(
    input string tag,
    input logic [3:0] nsaid,
    input string op,
    input txn_result_t tr,
    input int fd
  );
    string observed;
    if (op == "WRITE") observed = classify_write(tr);
    else observed = classify_read(tr);
    $fwrite(fd, "=== %s ===\n", tag);
    $fwrite(fd, "NSAID=%0d operation=%s observed=%s fix=%s\n", nsaid, op, observed, get_fix_mode());
    $fwrite(fd, "BRESP=%s RRESP=%0d mem_changed=%0d forwarded=%0d completed=%0d deadlock=%0d\n",
            bresp_str(tr.b_resp), tr.r_resp, tr.mem_changed, tr.forwarded, tr.completed, tr.deadlock);
    $fwrite(fd, "dst_aw=%0d dst_w=%0d err_w=%0d allow=%0d route_select=%0d\n",
            tr.dst_aw, tr.dst_w, probe_err_w, probe_allow, probe_route_select);
    $fwrite(fd, "allow_captured=%0d\n", tr.allow_captured);
    $display("M56 %s nsaid=%0d %s dst_aw=%0d dst_w=%0d allow_cap=%0d",
             tag, nsaid, observed, tr.dst_aw, tr.dst_w, tr.allow_captured);
  endtask

  task automatic run_r3_sequence(input int fd);
    txn_result_t tr;
    reset_dut();
    install_policy(AUTH_NSAID);
    dev_write(PROTECT, 64'h0123_4567_89AB_CDEF, AUTH_NSAID, tr);
    log_txn("M56-AUTH-WRITE-CONTROL", AUTH_NSAID, "WRITE", tr, fd);
    dev_write(PROTECT, 64'hFEDC_BA98_7654_3210, UNAUTH_NSAID, tr);
    log_txn("M56-UNAUTH-WRITE-CE", UNAUTH_NSAID, "WRITE", tr, fd);
    dev_read(PROTECT, UNAUTH_NSAID, tr);
    log_txn("M56-READ-CONTROL", UNAUTH_NSAID, "READ", tr, fd);
  endtask

  function automatic logic write_expect_pass(
    input string test_id,
    input txn_result_t tr,
    input logic expect_allow
  );
    string obs;
    obs = classify_write(tr);
    if (tr.deadlock) return 1'b0;
    if (expect_allow) return (obs == "ALLOW");
    return (obs == "DENY" && !tr.mem_changed);
  endfunction

  function automatic logic read_expect_pass(
    input txn_result_t tr,
    input logic expect_allow
  );
    string obs;
    obs = classify_read(tr);
    if (tr.deadlock) return 1'b0;
    if (expect_allow) return (obs == "ALLOW");
    return (obs == "DENY");
  endfunction

  task automatic write_regression_row(
    input int fd,
    input string test_id,
    input string configuration,
    input string prev_txn,
    input string cur_txn,
    input logic [3:0] nsaid,
    input string authorization,
    input int aw_timing,
    input int w_timing,
    input string backpressure,
    input string expected_bresp,
    input txn_result_t tr,
    input string property_id,
    input string git_commit,
    input string notes,
    input logic is_write
  );
    string observed;
    string result_s;
    string resp_s;
    if (is_write) begin
      observed = classify_write(tr);
      resp_s = bresp_str(tr.b_resp);
    end else begin
      observed = classify_read(tr);
      resp_s = bresp_str(tr.r_resp);
    end
    if (tr.deadlock) result_s = "DEADLOCK";
    else if ((expected_bresp == "OKAY" && observed == "ALLOW") ||
             (expected_bresp == "SLVERR" && observed == "DENY")) result_s = "PASS";
    else result_s = "FAIL";
    $fwrite(fd, "%s,%s,%s,%s,%0d,%s,%0d,%0d,%s,%s,%s,%0d,%0d,%0d,%s,%s,%s,%s\n",
            test_id, configuration, prev_txn, cur_txn, nsaid, authorization,
            aw_timing, w_timing, backpressure, expected_bresp, resp_s,
            tr.dst_aw, tr.dst_w, tr.mem_changed, property_id, result_s, git_commit, notes);
  endtask

  task automatic run_write_regression(input int fd, input string fix_mode, input string git_commit);
    txn_result_t tr, tr2;
    reset_dut();
    install_policy(AUTH_NSAID);
    dev_write(PROTECT, 64'h1111_1111_1111_1111, AUTH_NSAID, tr);
    write_regression_row(fd, "R1", fix_mode, "none", "auth_write", AUTH_NSAID, "ALLOW",
                         0, 0, "none", "OKAY", tr, "WP-07", git_commit, "fresh auth write", 1'b1);

    reset_dut();
    install_policy(AUTH_NSAID);
    dev_write(PROTECT, 64'h2222_2222_2222_2222, UNAUTH_NSAID, tr);
    write_regression_row(fd, "R2", fix_mode, "none", "unauth_write", UNAUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr, "WP-02,WP-03", git_commit, "fresh unauth write", 1'b1);

    reset_dut();
    install_policy(AUTH_NSAID);
    dev_write(PROTECT, 64'h0123_4567_89AB_CDEF, AUTH_NSAID, tr);
    dev_write(PROTECT, 64'hFEDC_BA98_7654_3210, UNAUTH_NSAID, tr2);
    write_regression_row(fd, "R3", fix_mode, "auth_write", "unauth_write", UNAUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr2, "WP-04,WP-09", git_commit, "M5.5 CE sequence", 1'b1);

    reset_dut();
    install_policy(AUTH_NSAID);
    dev_write(PROTECT, 64'h3333_3333_3333_3333, UNAUTH_NSAID, tr);
    dev_write(PROTECT, 64'h4444_4444_4444_4444, AUTH_NSAID, tr2);
    write_regression_row(fd, "R4", fix_mode, "unauth_write", "auth_write", AUTH_NSAID, "ALLOW",
                         0, 0, "none", "OKAY", tr2, "WP-09", git_commit, "unauth then auth", 1'b1);

    reset_dut();
    install_policy(AUTH_NSAID);
    dev_write(PROTECT, 64'h5555_5555_5555_5555, AUTH_NSAID, tr);
    dev_write(PROTECT, 64'h6666_6666_6666_6666, AUTH_NSAID, tr2);
    write_regression_row(fd, "R5", fix_mode, "auth_write", "auth_write", AUTH_NSAID, "ALLOW",
                         0, 0, "none", "OKAY", tr2, "WP-07", git_commit, "auth then auth", 1'b1);

    reset_dut();
    install_policy(AUTH_NSAID);
    dev_write(PROTECT, 64'h7777_7777_7777_7777, UNAUTH_NSAID, tr);
    dev_write(PROTECT, 64'h8888_8888_8888_8888, UNAUTH_NSAID, tr2);
    write_regression_row(fd, "R6", fix_mode, "unauth_write", "unauth_write", UNAUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr2, "WP-02", git_commit, "unauth then unauth", 1'b1);

    reset_dut();
    install_policy(AUTH_NSAID);
    dev_read(PROTECT, AUTH_NSAID, tr);
    write_regression_row(fd, "R7", fix_mode, "none", "auth_read", AUTH_NSAID, "ALLOW",
                         0, 0, "none", "OKAY", tr, "WP-11", git_commit, "NSAID0 read", 1'b0);
    dev_write(PROTECT, 64'hAAAA_AAAA_AAAA_AAAA, AUTH_NSAID, tr2);
    write_regression_row(fd, "R7", fix_mode, "auth_read", "auth_write", AUTH_NSAID, "ALLOW",
                         0, 0, "none", "OKAY", tr2, "WP-11", git_commit, "NSAID0 write", 1'b1);

    reset_dut();
    install_policy(AUTH_NSAID);
    dev_read(PROTECT, UNAUTH_NSAID, tr);
    write_regression_row(fd, "R8", fix_mode, "none", "unauth_read", UNAUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr, "WP-11", git_commit, "NSAID1 read", 1'b0);
    dev_write(PROTECT, 64'hBBBB_BBBB_BBBB_BBBB, UNAUTH_NSAID, tr2);
    write_regression_row(fd, "R8", fix_mode, "unauth_read", "unauth_write", UNAUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr2, "WP-11", git_commit, "NSAID1 write", 1'b1);

    reset_dut();
    install_policy_rw(AUTH_NSAID, 1'b1, 1'b0);
    dev_read(PROTECT, AUTH_NSAID, tr);
    write_regression_row(fd, "R9", fix_mode, "none", "perm_r1_w0_read", AUTH_NSAID, "ALLOW",
                         0, 0, "none", "OKAY", tr, "WP-11", git_commit, "R=1 W=0 read", 1'b0);
    dev_write(PROTECT, 64'hCCCC_CCCC_CCCC_CCCC, AUTH_NSAID, tr2);
    write_regression_row(fd, "R9", fix_mode, "perm_r1_w0_read", "perm_r1_w0_write", AUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr2, "WP-02", git_commit, "R=1 W=0 write", 1'b1);

    reset_dut();
    install_policy_rw(AUTH_NSAID, 1'b0, 1'b1);
    dev_read(PROTECT, AUTH_NSAID, tr);
    write_regression_row(fd, "R10", fix_mode, "none", "perm_r0_w1_read", AUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr, "WP-11", git_commit, "R=0 W=1 read", 1'b0);
    dev_write(PROTECT, 64'hDDDD_DDDD_DDDD_DDDD, AUTH_NSAID, tr2);
    write_regression_row(fd, "R10", fix_mode, "perm_r0_w1_read", "perm_r0_w1_write", AUTH_NSAID, "ALLOW",
                         0, 0, "none", "OKAY", tr2, "WP-07", git_commit, "R=0 W=1 write", 1'b1);

    reset_dut();
    install_policy(AUTH_NSAID);
    dev_read(PROTECT + 64'h1000, AUTH_NSAID, tr);
    write_regression_row(fd, "R11", fix_mode, "none", "no_entry_read", AUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr, "WP-11", git_commit, "no matching entry read", 1'b0);
    dev_write(PROTECT + 64'h1000, 64'hEEEE_EEEE_EEEE_EEEE, AUTH_NSAID, tr2);
    write_regression_row(fd, "R11", fix_mode, "no_entry_read", "no_entry_write", AUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr2, "WP-02", git_commit, "no matching entry write", 1'b1);

    reset_dut();
    enable_only_no_entry();
    dev_read(PROTECT, AUTH_NSAID, tr);
    write_regression_row(fd, "R12", fix_mode, "none", "enable_no_entry_read", AUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr, "WP-11", git_commit, "enable no entry read", 1'b0);
    dev_write(PROTECT, 64'hFFFF_FFFF_FFFF_FFFF, AUTH_NSAID, tr2);
    write_regression_row(fd, "R12", fix_mode, "enable_no_entry_read", "enable_no_entry_write", AUTH_NSAID, "DENY",
                         0, 0, "none", "SLVERR", tr2, "WP-02", git_commit, "enable no entry write", 1'b1);
  endtask

  task automatic run_timing_matrix(input int fd, input string fix_mode, input string git_commit);
    int delays[5];
    int di;
    string auth_s;
    logic [3:0] nsaid;
    logic [63:0] data;
    txn_result_t tr;
    string ordering;
    int aw_d, w_d;

    delays[0] = 0; delays[1] = 1; delays[2] = 2; delays[3] = 4; delays[4] = 8;

    for (int auth_case = 0; auth_case < 2; auth_case++) begin
      if (auth_case == 0) begin auth_s = "auth"; nsaid = AUTH_NSAID; end
      else begin auth_s = "deny"; nsaid = UNAUTH_NSAID; end

      for (di = 0; di < 5; di++) begin
        for (int ord = 0; ord < 3; ord++) begin
          if (ord == 0) begin ordering = "AW-before-W"; aw_d = 0; w_d = delays[di]; end
          else if (ord == 1) begin ordering = "W-before-AW"; aw_d = delays[di]; w_d = 0; end
          else begin ordering = "same-cycle"; aw_d = 0; w_d = 0; end

          reset_dut();
          install_policy(AUTH_NSAID);
          data = 64'hA000_0000_0000_0000 + (auth_case << 32) + delays[di] + ord;
          dev_write_timed(PROTECT, data, nsaid, aw_d, w_d, 1'b0, tr);
          $fwrite(fd, "%s,%s,%s,%0d,%0d,%0d,%s,%0d,%0d,%0d,%0d,%0d,%s,%s,%s\n",
                  fix_mode, auth_s, ordering, delays[di], aw_d, w_d,
                  classify_write(tr), tr.dst_aw, tr.dst_w, tr.mem_changed,
                  tr.deadlock, tr.allow_captured, bresp_str(tr.b_resp), git_commit,
                  $sformatf("delay=%0d", delays[di]));
        end
      end
    end
  endtask

  task automatic run_stale_route(input int fd, input string fix_mode, input string git_commit);
    txn_result_t tr, tr2, tr3;
    string seq;
    reset_dut();
    install_policy(AUTH_NSAID);

    seq = "ALLOW_DENY";
    dev_write(PROTECT, 64'h1000, AUTH_NSAID, tr);
    dev_write(PROTECT, 64'h2000, UNAUTH_NSAID, tr2);
    $fwrite(fd, "%s,%s,%0d,%0d,%s,%s,%0d,%0d,%0d,%s,%s\n",
            fix_mode, seq, AUTH_NSAID, UNAUTH_NSAID, classify_write(tr), classify_write(tr2),
            tr2.dst_w, tr2.mem_changed, tr2.allow_captured, git_commit, "WP-04");

    reset_dut(); install_policy(AUTH_NSAID);
    seq = "ALLOW_DENY_DENY";
    dev_write(PROTECT, 64'h1001, AUTH_NSAID, tr);
    dev_write(PROTECT, 64'h2001, UNAUTH_NSAID, tr2);
    dev_write(PROTECT, 64'h2002, UNAUTH_NSAID, tr3);
    $fwrite(fd, "%s,%s,%0d,%0d,%s,%s,%0d,%0d,%0d,%s,%s\n",
            fix_mode, seq, AUTH_NSAID, UNAUTH_NSAID, classify_write(tr2), classify_write(tr3),
            tr3.dst_w, tr3.mem_changed, tr3.allow_captured, git_commit, "WP-04");

    reset_dut(); install_policy(AUTH_NSAID);
    seq = "ALLOW_DENY_ALLOW";
    dev_write(PROTECT, 64'h1002, AUTH_NSAID, tr);
    dev_write(PROTECT, 64'h2003, UNAUTH_NSAID, tr2);
    dev_write(PROTECT, 64'h1003, AUTH_NSAID, tr3);
    $fwrite(fd, "%s,%s,%0d,%0d,%s,%s,%0d,%0d,%0d,%s,%s\n",
            fix_mode, seq, AUTH_NSAID, UNAUTH_NSAID, classify_write(tr2), classify_write(tr3),
            tr3.dst_w, tr3.mem_changed, tr3.allow_captured, git_commit, "WP-04,WP-09");

    reset_dut(); install_policy(AUTH_NSAID);
    seq = "ALLOW_ALLOW_DENY";
    dev_write(PROTECT, 64'h1004, AUTH_NSAID, tr);
    dev_write(PROTECT, 64'h1005, AUTH_NSAID, tr2);
    dev_write(PROTECT, 64'h2004, UNAUTH_NSAID, tr3);
    $fwrite(fd, "%s,%s,%0d,%0d,%s,%s,%0d,%0d,%0d,%s,%s\n",
            fix_mode, seq, AUTH_NSAID, UNAUTH_NSAID, classify_write(tr2), classify_write(tr3),
            tr3.dst_w, tr3.mem_changed, tr3.allow_captured, git_commit, "WP-04");

    reset_dut(); install_policy(AUTH_NSAID);
    seq = "DENY_ALLOW_DENY";
    dev_write(PROTECT, 64'h2005, UNAUTH_NSAID, tr);
    dev_write(PROTECT, 64'h1006, AUTH_NSAID, tr2);
    dev_write(PROTECT, 64'h2006, UNAUTH_NSAID, tr3);
    $fwrite(fd, "%s,%s,%0d,%0d,%s,%s,%0d,%0d,%0d,%s,%s\n",
            fix_mode, seq, UNAUTH_NSAID, AUTH_NSAID, classify_write(tr2), classify_write(tr3),
            tr3.dst_w, tr3.mem_changed, tr3.allow_captured, git_commit, "WP-09");

    reset_dut(); install_policy(AUTH_NSAID);
    seq = "ALLOW_A_ALLOW_B_DENY_C";
    dev_write(PROTECT, 64'h1007, AUTH_NSAID, tr);
    dev_write(PROTECT + 64'h10, 64'h1008, AUTH_NSAID, tr2);
    dev_write(PROTECT, 64'h2007, UNAUTH_NSAID, tr3);
    $fwrite(fd, "%s,%s,%0d,%0d,%s,%s,%0d,%0d,%0d,%s,%s\n",
            fix_mode, seq, AUTH_NSAID, UNAUTH_NSAID, classify_write(tr2), classify_write(tr3),
            tr3.dst_w, tr3.mem_changed, tr3.allow_captured, git_commit, "WP-04,WP-05");
  endtask

  task automatic run_random(input int fd, input string fix_mode, input string git_commit);
    int seed;
    int n;
    seed = 56;
    n = 500;
    void'($value$plusargs("M56_RANDOM_SEED=%d", seed));
    void'($value$plusargs("M56_RANDOM_N=%d", n));
    $fwrite(fd, "seed,run,nsaid,address,operation,configured,observed,bresp,rresp,memory_effect,dst_aw,dst_w,deadlock,fix,git_commit\n");
    for (int i = 0; i < n; i++) begin
      txn_result_t tr_w, tr_r;
      logic [3:0] nsaid;
      logic [63:0] addr;
      int aw_d, w_d;
      string obs;
      reset_dut();
      if ((i % 3) != 0) install_policy(AUTH_NSAID);
      else enable_only_no_entry();
      nsaid = 4'((i + seed) % 16);
      addr = PROTECT + ((i * 13 + seed) & 64'hFF);
      aw_d = (i + seed) % 5;
      w_d = (i * 3 + seed) % 5;
      if (i % 2 == 0) begin
        dev_write_timed(addr, 64'(i + seed), nsaid, aw_d, w_d, (i % 7) == 0, tr_w);
        obs = classify_write(tr_w);
        $fwrite(fd, "%0d,%0d,%0d,0x%016x,write,%0d,%s,%s,,%0d,%0d,%0d,%0d,%s,%s\n",
                seed, i, nsaid, addr, (i % 3) != 0, obs, bresp_str(tr_w.b_resp),
                tr_w.mem_changed, tr_w.dst_aw, tr_w.dst_w, tr_w.deadlock, fix_mode, git_commit);
      end else begin
        dev_read_timed(addr, nsaid, aw_d, tr_r);
        obs = classify_read(tr_r);
        $fwrite(fd, "%0d,%0d,%0d,0x%016x,read,%0d,%s,,%s,%0d,%0d,%0d,%0d,%s,%s\n",
                seed, i, nsaid, addr, (i % 3) != 0, obs,
                (tr_r.r_resp == axi_pkg::RESP_OKAY) ? "OKAY" :
                (tr_r.r_resp == axi_pkg::RESP_SLVERR) ? "SLVERR" : bresp_str(tr_r.r_resp),
                tr_r.mem_changed, tr_r.dst_aw, tr_r.dst_w, tr_r.deadlock, fix_mode, git_commit);
      end
    end
  endtask

  task automatic run_read_regression(input int fd, input string fix_mode, input string git_commit);
    txn_result_t tr;
    $fwrite(fd, "test_id,configuration,nsaid,case,expected,observed,rresp,mem_changed,result,fix,git_commit\n");
    reset_dut(); install_policy(AUTH_NSAID);
    dev_read(PROTECT, AUTH_NSAID, tr);
    $fwrite(fd, "R7,%s,%0d,auth_read,ALLOW,%s,%0d,%0d,%s,%s,%s\n",
            fix_mode, AUTH_NSAID, classify_read(tr), tr.r_resp, tr.mem_changed,
            read_expect_pass(tr, 1'b1) ? "PASS" : "FAIL", fix_mode, git_commit);

    reset_dut(); install_policy(AUTH_NSAID);
    dev_read(PROTECT, UNAUTH_NSAID, tr);
    $fwrite(fd, "R8,%s,%0d,unauth_read,DENY,%s,%0d,%0d,%s,%s,%s\n",
            fix_mode, UNAUTH_NSAID, classify_read(tr), tr.r_resp, tr.mem_changed,
            read_expect_pass(tr, 1'b0) ? "PASS" : "FAIL", fix_mode, git_commit);

    reset_dut(); install_policy_rw(AUTH_NSAID, 1'b1, 1'b0);
    dev_read(PROTECT, AUTH_NSAID, tr);
    $fwrite(fd, "R9,%s,%0d,perm_r1_w0,ALLOW,%s,%0d,%0d,%s,%s,%s\n",
            fix_mode, AUTH_NSAID, classify_read(tr), tr.r_resp, tr.mem_changed,
            read_expect_pass(tr, 1'b1) ? "PASS" : "FAIL", fix_mode, git_commit);

    reset_dut(); install_policy_rw(AUTH_NSAID, 1'b0, 1'b1);
    dev_read(PROTECT, AUTH_NSAID, tr);
    $fwrite(fd, "R10,%s,%0d,perm_r0_w1,DENY,%s,%0d,%0d,%s,%s,%s\n",
            fix_mode, AUTH_NSAID, classify_read(tr), tr.r_resp, tr.mem_changed,
            read_expect_pass(tr, 1'b0) ? "PASS" : "FAIL", fix_mode, git_commit);

    reset_dut(); install_policy(AUTH_NSAID);
    dev_read(PROTECT + 64'h1000, AUTH_NSAID, tr);
    $fwrite(fd, "R11,%s,%0d,no_entry,DENY,%s,%0d,%0d,%s,%s,%s\n",
            fix_mode, AUTH_NSAID, classify_read(tr), tr.r_resp, tr.mem_changed,
            read_expect_pass(tr, 1'b0) ? "PASS" : "FAIL", fix_mode, git_commit);
  endtask

  task automatic run_reset_regression(input int fd, input string fix_mode, input string git_commit);
    txn_result_t tr;
    $fwrite(fd, "case,configuration,phase,probe_route_select,probe_txn_allow,post_reset_write_observed,post_reset_mem,dst_w_after,result,fix,git_commit\n");
    reset_dut();
    install_policy(AUTH_NSAID);
    tick(2);
    rst_n = 1'b0;
    tick(3);
    rst_n = 1'b1;
    tick(5);
    install_policy(AUTH_NSAID);
    tick(20);
    dev_write(PROTECT, 64'hDEAD_BEEF_CAFE_BABE, UNAUTH_NSAID, tr);
    $fwrite(fd, "reset_during_idle,%s,after_reset,%0d,%0d,%s,%0d,%0d,%s,%s,%s\n",
            fix_mode, probe_route_select, probe_txn_allow, classify_write(tr),
            tr.mem_changed, tr.dst_w,
            (classify_write(tr) == "DENY") ? "PASS" : "FAIL", fix_mode, git_commit);
  endtask

  task automatic measure_write_latency(
    input logic [63:0] addr,
    input logic [63:0] data,
    input logic [3:0] nsaid,
    output int aw_to_b,
    output int aw_to_dst_aw,
    output int w_to_dst_w
  );
    int cycle;
    int aw_cycle, w_cycle, b_cycle, dst_aw_cycle, dst_w_cycle;
    logic aw_hs, w_hs;
    aw_to_b = -1;
    aw_to_dst_aw = -1;
    w_to_dst_w = -1;
    aw_cycle = -1; w_cycle = -1; b_cycle = -1;
    dst_aw_cycle = -1; dst_w_cycle = -1;
    probe_armed = 1'b1;
    bus_idle();
    rp_req.aw_valid = 1'b1;
    rp_req.w_valid = 1'b1;
    rp_req.b_ready = 1'b1;
    rp_req.aw.id = '0;
    rp_req.aw.addr = addr;
    rp_req.aw.len = '0;
    rp_req.aw.size = 3'd2;
    rp_req.aw.burst = axi_pkg::BURST_INCR;
    rp_req.aw.prot = '0;
    rp_req.aw.nsaid = nsaid;
    rp_req.w.data = data;
    rp_req.w.strb = 8'h0F;
    rp_req.w.last = 1'b1;
    aw_hs = 1'b0; w_hs = 1'b0;
    aw_cycle = 0;
    w_cycle = 0;
    cycle = 0;
    while (cycle < TIMEOUT_LONG) begin
      if (rp_req.aw_valid && !aw_hs) aw_cycle = cycle;
      if (rp_req.w_valid && !w_hs) w_cycle = cycle;
      if (probe_mst_aw && dst_aw_cycle < 0) dst_aw_cycle = cycle;
      if (probe_mst_w && dst_w_cycle < 0) dst_w_cycle = cycle;
      if (rp_req.aw_valid && rp_rsp.aw_ready) begin rp_req.aw_valid = 1'b0; aw_hs = 1'b1; end
      if (rp_req.w_valid && rp_rsp.w_ready) begin rp_req.w_valid = 1'b0; w_hs = 1'b1; end
      if (rp_rsp.b_valid && rp_req.b_ready && b_cycle < 0) b_cycle = cycle;
      if (b_cycle >= 0) break;
      cycle = cycle + 1;
      @(posedge clk);
    end
    if (aw_cycle >= 0 && b_cycle >= 0) aw_to_b = b_cycle - aw_cycle;
    if (aw_cycle >= 0 && dst_aw_cycle >= 0) aw_to_dst_aw = dst_aw_cycle - aw_cycle;
    if (w_cycle >= 0 && dst_w_cycle >= 0) w_to_dst_w = dst_w_cycle - w_cycle;
    rp_req.b_ready = 1'b0;
    bus_idle();
    tick(2);
  endtask

  task automatic run_latency(input int fd, input string fix_mode, input string git_commit);
    int aw_to_b, aw_to_dst_aw, w_to_dst_w;
    int timeout;
    int cycle;
    int aw_c, w_c, b_c, da_c, dw_c;
    logic aw_done, w_done;
    if (fd == 0)
      fd = $fopen("results/tables/m56_latency.csv", "a");
    reset_dut();
    install_policy(AUTH_NSAID);
    probe_armed = 1'b1;
    bus_idle();
    rp_req.aw_valid = 1'b1;
    rp_req.w_valid = 1'b1;
    rp_req.b_ready = 1'b1;
    rp_req.aw.id = '0;
    rp_req.aw.addr = PROTECT;
    rp_req.aw.len = '0;
    rp_req.aw.size = 3'd2;
    rp_req.aw.burst = axi_pkg::BURST_INCR;
    rp_req.aw.prot = '0;
    rp_req.aw.nsaid = AUTH_NSAID;
    rp_req.w.data = 64'hA5;
    rp_req.w.strb = 8'h0F;
    rp_req.w.last = 1'b1;
    aw_done = 1'b0; w_done = 1'b0;
    aw_c = -1; w_c = -1; b_c = -1; da_c = -1; dw_c = -1;
    for (cycle = 0; cycle < TIMEOUT_LONG; cycle++) begin
      if (!aw_done && rp_req.aw_valid) aw_c = cycle;
      if (!w_done && rp_req.w_valid) w_c = cycle;
      if (probe_mst_aw && da_c < 0) da_c = cycle;
      if (probe_mst_w && dw_c < 0) dw_c = cycle;
      if (rp_req.aw_valid && rp_rsp.aw_ready) begin rp_req.aw_valid = 1'b0; aw_done = 1'b1; end
      if (rp_req.w_valid && rp_rsp.w_ready) begin rp_req.w_valid = 1'b0; w_done = 1'b1; end
      if (rp_rsp.b_valid && rp_req.b_ready) begin b_c = cycle; break; end
      @(posedge clk);
    end
    aw_to_b = (aw_c >= 0 && b_c >= 0) ? (b_c - aw_c) : -1;
    aw_to_dst_aw = (aw_c >= 0 && da_c >= 0) ? (da_c - aw_c) : -1;
    w_to_dst_w = (w_c >= 0 && dw_c >= 0) ? (dw_c - w_c) : -1;
    $fwrite(fd, "%s,aw_to_b,%0d,%s,%s,authorized write same-cycle AW/W\n",
            fix_mode, aw_to_b, fix_mode, git_commit);
    $fwrite(fd, "%s,aw_to_dst_aw,%0d,%s,%s,authorized write same-cycle AW/W\n",
            fix_mode, aw_to_dst_aw, fix_mode, git_commit);
    $fwrite(fd, "%s,w_to_dst_w,%0d,%s,%s,authorized write same-cycle AW/W\n",
            fix_mode, w_to_dst_w, fix_mode, git_commit);
    rp_req.b_ready = 1'b0;
    bus_idle();
  endtask

  task automatic run_fix_compare(input int fd, input string fix_mode, input string git_commit);
    txn_result_t tr_auth, tr_unauth, tr_fresh;
    string obs;
    $fwrite(fd, "configuration,build_fix,unauth_write_memory_effect,source_completion,bresp,deadlock,stale_route_possible,authorized_write_regression,notes\n");
    reset_dut();
    install_policy(AUTH_NSAID);
    dev_write(PROTECT, 64'h0123_4567_89AB_CDEF, AUTH_NSAID, tr_auth);
    dev_write(PROTECT, 64'hFEDC_BA98_7654_3210, UNAUTH_NSAID, tr_unauth);
    reset_dut();
    install_policy(AUTH_NSAID);
    dev_write(PROTECT, 64'hDEAD_BEEF_CAFE_BABE, UNAUTH_NSAID, tr_fresh);
    obs = classify_write(tr_unauth);
    $fwrite(fd, "%s,%s,%0d,%0d,%s,%0d,%0d,%0d,R3+fresh_unauth; build=%s\n",
            fix_mode, fix_mode,
            tr_unauth.mem_changed, tr_unauth.completed, bresp_str(tr_unauth.b_resp),
            tr_unauth.deadlock || tr_fresh.deadlock,
            (tr_unauth.dst_w && !tr_unauth.allow_captured),
            (classify_write(tr_auth) == "ALLOW") ? 1 : 0, fix_mode);
  endtask

  integer csv, txt_fd;
  string mode;
  string fix_mode;
  string git_commit;

  initial begin
    mode = "regression";
    fix_mode = "proper";
    git_commit = "unknown";
    void'($value$plusargs("M56_MODE=%s", mode));
    void'($value$plusargs("M56_FIX=%s", fix_mode));
    void'($value$plusargs("M56_GIT_COMMIT=%s", git_commit));

    if (mode == "before") begin
      if ($test$plusargs("M56_VCD")) begin
        $dumpfile("results/m56/before_fix/M56-BEFORE-CE.vcd");
        $dumpvars(0, m56_rtl_adapter);
      end
      txt_fd = $fopen("results/m56/before_fix/M56-BEFORE-CE.txt", "w");
      $fwrite(txt_fd, "M56 before-fix reproduction fix=%s git=%s\n", fix_mode, git_commit);
      run_r3_sequence(txt_fd);
      $fclose(txt_fd);
    end

    if (mode == "regression") begin
      csv = $fopen("results/tables/m56_write_regression.csv", "w");
      $fwrite(csv, "test_id,configuration,previous_transaction,current_transaction,nsaid,authorization,aw_timing,w_timing,backpressure,expected_bresp,observed_bresp,downstream_aw_seen,downstream_w_seen,memory_changed,property,result,git_commit,notes\n");
      run_write_regression(csv, fix_mode, git_commit);
      $fclose(csv);
    end

    if (mode == "timing") begin
      csv = $fopen("results/tables/m56_axi_timing_matrix.csv", "w");
      $fwrite(csv, "configuration,auth_case,ordering,delay,aw_delay,w_delay,observed,dst_aw,dst_w,memory_changed,deadlock,allow_captured,bresp,git_commit,notes\n");
      run_timing_matrix(csv, fix_mode, git_commit);
      $fclose(csv);
    end

    if (mode == "stale-route") begin
      csv = $fopen("results/tables/m56_route_freshness.csv", "w");
      $fwrite(csv, "configuration,sequence,nsaid_first,nsaid_second,observed_prev,observed_cur,dst_w_cur,memory_changed,allow_captured,git_commit,property\n");
      run_stale_route(csv, fix_mode, git_commit);
      $fclose(csv);
    end

    if (mode == "random") begin
      csv = $fopen("results/m56/random/all_runs.csv", "w");
      run_random(csv, fix_mode, git_commit);
      $fclose(csv);
    end

    if (mode == "read") begin
      csv = $fopen("results/tables/m56_read_regression.csv", "w");
      run_read_regression(csv, fix_mode, git_commit);
      $fclose(csv);
    end

    if (mode == "reset") begin
      csv = $fopen("results/tables/m56_reset_regression.csv", "w");
      run_reset_regression(csv, fix_mode, git_commit);
      $fclose(csv);
    end

    if (mode == "latency") begin
      csv = $fopen("results/tables/m56_latency.csv", "w");
      $fwrite(csv, "configuration,metric,cycles,fix,git_commit,notes\n");
      $fclose(csv);
      run_latency(0, fix_mode, git_commit);
    end

    if (mode == "fix_compare") begin
      csv = $fopen("results/tables/m56_fix_comparison.csv", "w");
      run_fix_compare(csv, fix_mode, git_commit);
      $fclose(csv);
    end

    $display("M56 diagnostic complete mode=%s fix=%s", mode, fix_mode);
    $finish(0);
  end

endmodule
