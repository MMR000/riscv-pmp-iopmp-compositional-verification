// M5 RTL-IOPMP harness: minimal AXI integration + directed test runner.
`timescale 1ns/1ps

module rtl_iopmp_adapter;

  import lint_wrapper::*;
  import rv_iopmp_reg_pkg::*;

  localparam int unsigned PROTECT_LO = 32'h2000_0000;
  localparam logic [63:0] PROTECT = 64'h0000_0000_2000_0000;
  localparam logic [3:0] AUTH_NSAID = 4'd0;
  localparam logic [3:0] UNAUTH_NSAID = 4'd1;
  localparam logic [31:0] ENTRY_CFG_TOR   = 32'h0000_0008;
  localparam logic [31:0] ENTRY_CFG_TORRW = 32'h0000_000B;

  logic clk;
  logic rst_n;

  req_t        ip_req;
  resp_t       ip_rsp;
  req_slv_t    cp_req;
  resp_slv_t   cp_rsp;
  req_nsaid_t  rp_req;
  resp_t       rp_rsp;
  logic        wsi_wire;

  logic mem_write, mem_read;
  logic [63:0] mem_waddr, mem_wdata, mem_raddr;

  rtl_iopmp_dut_wrapper dut (
    .clk_i(clk), .rst_ni(rst_n),
    .axi_iopmp_ip_req(ip_req), .axi_iopmp_ip_rsp(ip_rsp),
    .axi_iopmp_cp_req(cp_req), .axi_iopmp_cp_rsp(cp_rsp),
    .axi_iopmp_rp_req(rp_req), .axi_iopmp_rp_rsp(rp_rsp),
    .wsi_wire_o(wsi_wire)
  );

  axi_simple_mem #(
    .BASE_ADDR(PROTECT)
  ) mem (
    .clk_i(clk), .rst_ni(rst_n),
    .slv_req_i(ip_req), .slv_rsp_o(ip_rsp),
    .write_occurred_o(mem_write), .last_write_addr_o(mem_waddr),
    .last_write_data_o(mem_wdata), .read_occurred_o(mem_read),
    .last_read_addr_o(mem_raddr)
  );

  initial begin
    clk = 1'b0;
    forever begin
      #5 clk = 1'b1;
      #5 clk = 1'b0;
    end
  end

  task automatic tick(input int n = 1);
    repeat (n) @(posedge clk);
  endtask

  task automatic reset_dut;
    rst_n = 1'b0;
    cp_req = '0;
    rp_req = '0;
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
    cp_req.aw.id    = '0;
    cp_req.aw.addr  = axaddr;
    cp_req.aw.len   = '0;
    cp_req.aw.size  = 3'd2;
    cp_req.aw.burst = axi_pkg::BURST_INCR;
    cp_req.aw.prot  = '0;
    cp_req.w_valid  = 1'b1;
    cp_req.w.data   = {32'b0, data};
    cp_req.w.strb   = 8'h0F;
    cp_req.w.last   = 1'b1;
    cp_req.b_ready  = 1'b1;
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
    cp_req.w_valid  = 1'b0;
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
    cp_req.ar.id    = '0;
    cp_req.ar.addr  = axaddr;
    cp_req.ar.len   = '0;
    cp_req.ar.size  = 3'd2;
    cp_req.ar.burst = axi_pkg::BURST_INCR;
    cp_req.ar.prot  = '0;
    cp_req.r_ready  = 1'b1;
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
    // W1SS: enable clears only on reset
  endtask

  task automatic install_policy(input logic [3:0] nsaid);
    logic [13:0] srcmd_off;
    srcmd_off = IOPMP_SRCMD_EN_OFFSET + (14'(nsaid) << 5);
    cfg_write(IOPMP_MDCFG_OFFSET + 14'd0, 32'd1);
    cfg_write(srcmd_off, 32'h0000_0002);            // MD0 enable (md[0] at bit 1)
    cfg_write(IOPMP_ENTRY_ADDR_OFFSET + 14'd0, PROTECT_LO >> 2);
    cfg_write(IOPMP_ENTRY_ADDRH_OFFSET + 14'd0, 32'd0);
    cfg_write(IOPMP_ENTRY_CFG_OFFSET + 14'd0, 32'h0000_0013); // NA4+R+W
    set_enable(1'b1);
    tick(200);
  endtask

  typedef struct {
    logic forwarded;
    logic mem_changed;
    logic [1:0] b_resp;
    logic [1:0] r_resp;
    logic [63:0] rdata;
  } txn_result_t;

  task automatic dev_write(
    input logic [63:0] addr,
    input logic [63:0] data,
    input logic [3:0] nsaid,
    output txn_result_t res
  );
    int timeout;
    res = '{default:'0};
    bus_idle();
    rp_req.aw_valid = 1'b1;
    rp_req.aw.id    = '0;
    rp_req.aw.addr  = addr;
    rp_req.aw.len   = '0;
    rp_req.aw.size  = 3'd2;
    rp_req.aw.burst = axi_pkg::BURST_INCR;
    rp_req.aw.prot  = '0;
    rp_req.aw.nsaid = nsaid;
    rp_req.w_valid  = 1'b1;
    rp_req.w.data   = data;
    rp_req.w.strb   = 8'h0F;
    rp_req.w.last   = 1'b1;
    rp_req.b_ready  = 1'b1;
    timeout = 0;
    while (!rp_rsp.aw_ready) begin
      @(posedge clk);
      if (++timeout > 50000) begin $display("TIMEOUT dev_write aw"); $finish(1); end
    end
    timeout = 0;
    while (!rp_rsp.w_ready) begin
      @(posedge clk);
      if (++timeout > 50000) begin $display("TIMEOUT dev_write w"); $finish(1); end
    end
    @(posedge clk);
    rp_req.aw_valid = 1'b0;
    rp_req.w_valid  = 1'b0;
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
    bus_idle();
    rp_req.ar_valid = 1'b1;
    rp_req.ar.id    = '0;
    rp_req.ar.addr  = addr;
    rp_req.ar.len   = '0;
    rp_req.ar.size  = 3'd2;
    rp_req.ar.burst = axi_pkg::BURST_INCR;
    rp_req.ar.prot  = '0;
    rp_req.ar.nsaid = nsaid;
    rp_req.r_ready  = 1'b1;
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
    res.rdata  = rp_rsp.r.data;
    res.forwarded = (rp_rsp.r.resp == axi_pkg::RESP_OKAY);
    res.mem_changed = mem_read;
    @(posedge clk);
    rp_req.r_ready = 1'b0;
    bus_idle();
    tick(5);
  endtask

  function automatic string classify_result(input txn_result_t r, input logic is_write);
    if (is_write) begin
      if (r.mem_changed && r.b_resp == axi_pkg::RESP_OKAY) return "ALLOW";
      if (r.b_resp == axi_pkg::RESP_SLVERR || !r.mem_changed) return "DENY";
    end else begin
      if (r.mem_changed && r.r_resp == axi_pkg::RESP_OKAY) return "ALLOW";
      if (r.r_resp == axi_pkg::RESP_SLVERR || !r.mem_changed) return "DENY";
    end
    return "INCONCLUSIVE";
  endfunction

  integer csv;
  integer rnd_csv;
  integer fail_csv;

  task automatic emit_row(
    input string exp_id, input string cfg, input logic [3:0] nsaid,
    input logic [63:0] addr, input string op, input logic enable_on,
    input logic configured, input string observed, input string native_class,
    input string bresp, input logic mem_eff
  );
    $fwrite(csv, "%s,%s,%0d,0x%016x,%s,%0d,%0d,%s,%s,%s,%0d\n",
            exp_id, cfg, nsaid, addr, op, enable_on, configured,
            observed, native_class, bresp, mem_eff);
  endtask

  initial begin
    txn_result_t tr;
    logic [31:0] hwcfg0;
    string obs;
    string out_path;
    out_path = "results/m5/rtl/rtl_results.csv";
    if ($value$plusargs("M5_RTL_RESULTS=%s", out_path)) ;
    csv = $fopen(out_path, "w");
    if (csv == 0) begin
      $display("FATAL: cannot open %s", out_path);
      $finish(1);
    end
    $fwrite(csv, "experiment,configuration,nsaid,address,operation,enable,configured,observed,native_class,bresp,memory_effect\n");

    // RTL-M1-01 / RTL-RST-01: reset, no config, protected write
    reset_dut();
    dev_write(PROTECT, 64'h1111_2222_3333_4444, AUTH_NSAID, tr);
    obs = classify_result(tr, 1'b1);
    emit_row("RTL-M1-01", "native-reset", AUTH_NSAID, PROTECT, "write", 0, 0,
             obs, "RTL-DEFAULT-BYPASS", $sformatf("%0d", tr.b_resp), tr.mem_changed);
    emit_row("RTL-RST-01", "native-reset", AUTH_NSAID, PROTECT, "write", 0, 0,
             obs, "RTL-DEFAULT-BYPASS", $sformatf("%0d", tr.b_resp), tr.mem_changed);

    // Enable checking without policy
    reset_dut();
    set_enable(1'b1);
    cfg_read(IOPMP_HWCFG0_OFFSET, hwcfg0);
    dev_write(PROTECT, 64'hAAAA_BBBB_CCCC_DDDD, AUTH_NSAID, tr);
    obs = classify_result(tr, 1'b1);
    emit_row("RTL-M1-06", "enable-no-entry", AUTH_NSAID, PROTECT, "write", 1, 0,
             obs, "RTL-DEFAULT-DENY", $sformatf("%0d", tr.b_resp), tr.mem_changed);

    // RTL-M1-02 / RTL-RST-02: authorized write after policy
    reset_dut();
    install_policy(AUTH_NSAID);
    dev_write(PROTECT, 64'h0123_4567_89AB_CDEF, AUTH_NSAID, tr);
    obs = classify_result(tr, 1'b1);
    emit_row("RTL-M1-02", "configured", AUTH_NSAID, PROTECT, "write", 1, 1,
             obs, "RTL-AUTHORIZED", $sformatf("%0d", tr.b_resp), tr.mem_changed);

    tick(50);
    // RTL-M1-03: wrong requester
    dev_write(PROTECT, 64'hFEDC_BA98_7654_3210, UNAUTH_NSAID, tr);
    obs = classify_result(tr, 1'b1);
    emit_row("RTL-M1-03", "configured", UNAUTH_NSAID, PROTECT, "write", 1, 1,
             obs, "RTL-UNAUTHORIZED", $sformatf("%0d", tr.b_resp), tr.mem_changed);

    // RTL-M1-04 authorized read
    dev_read(PROTECT, AUTH_NSAID, tr);
    obs = classify_result(tr, 1'b0);
    emit_row("RTL-M1-04", "configured", AUTH_NSAID, PROTECT, "read", 1, 1,
             obs, "RTL-AUTHORIZED", $sformatf("%0d", tr.r_resp), tr.mem_changed);

    // RTL-M1-05 unauthorized read
    dev_read(PROTECT, UNAUTH_NSAID, tr);
    obs = classify_result(tr, 1'b0);
    emit_row("RTL-M1-05", "configured", UNAUTH_NSAID, PROTECT, "read", 1, 1,
             obs, "RTL-UNAUTHORIZED", $sformatf("%0d", tr.r_resp), tr.mem_changed);

    // RTL-RST-03: configured then reset then immediate write
    reset_dut();
    install_policy(AUTH_NSAID);
    reset_dut();
    cfg_read(IOPMP_HWCFG0_OFFSET, hwcfg0);
    dev_write(PROTECT, 64'h9999_8888_7777_6666, AUTH_NSAID, tr);
    obs = classify_result(tr, 1'b1);
    emit_row("RTL-RST-03", "post-reset", AUTH_NSAID, PROTECT, "write", hwcfg0[31], 0,
             obs, (hwcfg0[31] ? "RTL-DEFAULT-DENY" : "RTL-DEFAULT-BYPASS"),
             $sformatf("%0d", tr.b_resp), tr.mem_changed);

    $fclose(csv);

    if ($test$plusargs("M5_RTL_RANDOM")) begin
      int n_random = 500;
      int seed = 42;
      string rnd_path = "results/m5/rtl/rtl_random_results.csv";
      void'($value$plusargs("M5_RTL_RANDOM=%d", n_random));
      void'($value$plusargs("M5_RTL_SEED=%d", seed));
      void'($value$plusargs("M5_RTL_RANDOM_OUT=%s", rnd_path));
      rnd_csv = $fopen(rnd_path, "w");
      $fwrite(rnd_csv, "seed,nsaid,address,operation,configured,observed,bresp,memory_effect\n");
      for (int i = 0; i < n_random; i++) begin
        logic [63:0] addr;
        logic [3:0] nsaid;
        logic cfg;
        reset_dut();
        addr = PROTECT + ((i * 17 + seed) & 64'hFFC);
        nsaid = (i % 2) ? UNAUTH_NSAID : AUTH_NSAID;
        cfg = (i % 3) != 0;
        if (cfg) install_policy(AUTH_NSAID);
        else set_enable(1'b1);
        dev_write(addr, 64'(i), nsaid, tr);
        $fwrite(rnd_csv, "%0d,%0d,0x%016x,write,%0d,%s,%0d,%0d\n",
                i, nsaid, addr, cfg, classify_result(tr, 1'b1), tr.b_resp, tr.mem_changed);
      end
      $fclose(rnd_csv);
      $display("M5 RTL random: %0d transactions -> %s", n_random, rnd_path);
    end

    $display("M5 RTL directed tests complete -> %s", out_path);
    $finish(0);
  end

endmodule
