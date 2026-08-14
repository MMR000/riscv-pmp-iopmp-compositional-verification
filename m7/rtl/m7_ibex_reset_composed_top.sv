// M7 Phase C: real Ibex + DMA + IOPMP with independent reset domains (MEM-RET).
// Phase B top left frozen; this is a separate composed reset top.
`include "m7_composed_map.vh"
`include "bus_pkg.vh"

`ifndef RV32M
  `define RV32M ibex_pkg::RV32MFast
`endif

module m7_ibex_reset_composed_top #(
    parameter bit PMPEnable       = 1'b1,
    parameter int PMPNumRegions   = 8,
    parameter int PMPGranularity  = 0,
    parameter                     SRAMInitFile = ""
) (
    input  logic        IO_CLK,
    input  logic        IO_RST_N
);

  logic clk_i, rst_ni;
  assign clk_i  = IO_CLK;
  assign rst_ni = IO_RST_N;

  // Domain resets (driven by harness)
  logic cpu_reset_n, dma_reset_n, iopmp_reset_n;
  logic security_config_reset_n, interconnect_reset_n, protected_memory_reset_n;

  logic        cfg_write;
  logic [31:0] cfg_addr, cfg_wdata;
  logic        dma_start, dma_done, dma_error;
  logic [31:0] dma_src_addr, dma_dst_addr, dma_wdata, dma_rdata;
  logic [15:0] dma_length;
  logic [7:0]  dma_requester_id;
  logic [1:0]  dma_mode;
  logic [31:0] prot_peek_addr, prot_mem_word0;
  logic        prot_mem_changed;
  logic [31:0] prot_changed_addr, prot_changed_wdata;
  logic        iopmp_txn_valid, iopmp_txn_authorized;
  logic [7:0]  iopmp_txn_rid;
  logic [31:0] test_ready_o, harness_result_i, harness_dma_cycle_i, harness_cpu_cycle_i;
  logic        harness_go_set, pmp_ready_o, sys_secure_ready, test_finished;
  logic        init_req, init_write, init_gnt, init_valid;
  logic [31:0] init_addr, init_wdata;

  typedef enum logic { CoreD } bus_host_e;
  typedef enum logic [2:0] { DevRam, DevSim, DevTimer, DevSync } bus_dev_e;
  localparam int NrDevices = 4;
  localparam int NrHosts   = 1;

  logic        host_req, host_gnt, host_we, host_rvalid, host_err;
  logic [31:0] host_addr, host_wdata, host_rdata;
  logic [3:0]  host_be;

  logic        device_req[NrDevices], device_we[NrDevices];
  logic        device_rvalid[NrDevices], device_err[NrDevices];
  logic [31:0] device_addr[NrDevices], device_wdata[NrDevices], device_rdata[NrDevices];
  logic [3:0]  device_be[NrDevices];
  logic [31:0] cfg_device_addr_base[NrDevices], cfg_device_addr_mask[NrDevices];

  assign cfg_device_addr_base[DevRam]   = `M7_IBEX_RAM_BASE;
  assign cfg_device_addr_mask[DevRam]   = `M7_IBEX_RAM_MASK;
  assign cfg_device_addr_base[DevSim]   = `M7_SIM_CTRL_BASE;
  assign cfg_device_addr_mask[DevSim]   = `M7_SIM_CTRL_MASK;
  assign cfg_device_addr_base[DevTimer] = `M7_TIMER_BASE;
  assign cfg_device_addr_mask[DevTimer] = `M7_TIMER_MASK;
  assign cfg_device_addr_base[DevSync]  = `M7_TEST_SYNC_BASE;
  assign cfg_device_addr_mask[DevSync]  = 32'hFFFF_F000;

  logic instr_req, instr_gnt, instr_rvalid, instr_err;
  logic [31:0] instr_addr, instr_rdata;
  logic core_data_req, core_data_we, core_data_gnt, core_data_rvalid, core_data_err;
  logic [3:0] core_data_be;
  logic [31:0] core_data_addr, core_data_wdata, core_data_rdata;
  logic [6:0] data_rdata_intg, instr_rdata_intg;

  logic research_sel, research_gnt, research_valid, research_req, research_write;
  logic research_outstanding;
  logic [31:0] research_rdata, research_addr, research_wdata;

  wire cpu_adapt_req, cpu_adapt_write, cpu_adapt_gnt, cpu_adapt_valid;
  wire [`ADDR_WIDTH-1:0] cpu_adapt_addr;
  wire [`DATA_WIDTH-1:0] cpu_adapt_wdata, cpu_adapt_rdata;

  // Mux trusted init writer onto arbiter CPU port when active
  wire cpu_ic_req   = init_req | cpu_adapt_req;
  wire cpu_ic_write = init_req ? init_write : cpu_adapt_write;
  wire [`ADDR_WIDTH-1:0] cpu_ic_addr  = init_req ? init_addr  : cpu_adapt_addr;
  wire [`DATA_WIDTH-1:0] cpu_ic_wdata = init_req ? init_wdata : cpu_adapt_wdata;
  wire cpu_ic_gnt, cpu_ic_valid;
  wire [`DATA_WIDTH-1:0] cpu_ic_rdata;
  assign init_gnt           = init_req & cpu_ic_gnt;
  assign init_valid         = init_req & cpu_ic_valid;
  assign cpu_adapt_gnt      = ~init_req & cpu_ic_gnt;
  assign cpu_adapt_valid    = ~init_req & cpu_ic_valid;
  assign cpu_adapt_rdata    = cpu_ic_rdata;

  function automatic logic is_research_addr(input logic [31:0] a);
    is_research_addr =
        ((a >= `M7_NORMAL_SRAM_BASE) && (a <= `M7_NORMAL_SRAM_LIMIT)) ||
        ((a >= `M7_PROTECT_SRAM_BASE) && (a <= `M7_PROTECT_SRAM_LIMIT));
  endfunction

  assign research_sel = core_data_req && is_research_addr(core_data_addr);

  always_ff @(posedge clk_i or negedge cpu_reset_n) begin
    if (!cpu_reset_n)
      research_outstanding <= 1'b0;
    else if (research_sel && research_gnt)
      research_outstanding <= 1'b1;
    else if (research_valid)
      research_outstanding <= 1'b0;
  end

  assign host_req   = core_data_req && !research_sel && !research_outstanding;
  assign host_addr  = core_data_addr;
  assign host_we    = core_data_we;
  assign host_be    = core_data_be;
  assign host_wdata = core_data_wdata;

  m7_ibex_data_adapter u_data_adapt (
      .clk_i(clk_i), .rst_ni(interconnect_reset_n),
      .ibex_req_i(research_sel ? core_data_req : 1'b0),
      .ibex_gnt_o(research_gnt),
      .ibex_rvalid_o(research_valid),
      .ibex_we_i(core_data_we),
      .ibex_be_i(core_data_be),
      .ibex_addr_i(core_data_addr),
      .ibex_wdata_i(core_data_wdata),
      .ibex_rdata_o(research_rdata),
      .ibex_err_o(),
      .cpu_req_o(cpu_adapt_req),
      .cpu_addr_o(cpu_adapt_addr),
      .cpu_write_o(cpu_adapt_write),
      .cpu_wdata_o(cpu_adapt_wdata),
      .cpu_gnt_i(cpu_adapt_gnt),
      .cpu_valid_i(cpu_adapt_valid),
      .cpu_rdata_i(cpu_adapt_rdata)
  );

  assign core_data_gnt    = research_sel ? research_gnt : host_gnt;
  assign core_data_rvalid = research_outstanding ? research_valid : host_rvalid;
  assign core_data_rdata  = research_outstanding ? research_rdata : host_rdata;
  assign core_data_err    = research_outstanding ? 1'b0 : host_err;

  assign instr_gnt = instr_req;
  assign instr_err = 1'b0;

  // Boot bus/RAM/timer stay on cold reset (rst_ni), not cpu_reset_n.
  // Mid-sim CPU-domain reset must not disturb instruction memory rvalid
  // pipelines or wipe the loaded ELF image sideband state.
  bus #(
      .NrDevices(NrDevices), .NrHosts(NrHosts), .DataWidth(32), .AddressWidth(32)
  ) u_bus (
      .clk_i(clk_i), .rst_ni(rst_ni),
      .host_req_i({host_req}), .host_gnt_o({host_gnt}),
      .host_addr_i({host_addr}), .host_we_i({host_we}), .host_be_i({host_be}),
      .host_wdata_i({host_wdata}), .host_rvalid_o({host_rvalid}),
      .host_rdata_o({host_rdata}), .host_err_o({host_err}),
      .device_req_o(device_req), .device_addr_o(device_addr),
      .device_we_o(device_we), .device_be_o(device_be),
      .device_wdata_o(device_wdata), .device_rvalid_i(device_rvalid),
      .device_rdata_i(device_rdata), .device_err_i(device_err),
      .cfg_device_addr_base, .cfg_device_addr_mask
  );

  ibex_top_tracing #(
      .PMPEnable(PMPEnable), .PMPGranularity(PMPGranularity),
      .PMPNumRegions(PMPNumRegions), .RV32M(`RV32M),
      .DmBaseAddr(32'h00100000), .DmHaltAddr(32'h00100000)
  ) u_ibex (
      .clk_i(clk_i), .rst_ni(cpu_reset_n),
      .test_en_i(1'b0), .scan_rst_ni(1'b1),
      .ram_cfg_icache_tag_i('{default: prim_ram_1p_pkg::RAM_1P_CFG_REQ_DEFAULT}),
      .ram_cfg_icache_tag_o(),
      .ram_cfg_icache_data_i('{default: prim_ram_1p_pkg::RAM_1P_CFG_REQ_DEFAULT}),
      .ram_cfg_icache_data_o(),
      .hart_id_i(32'h0), .boot_addr_i(32'h00100000),
      .instr_req_o(instr_req), .instr_gnt_i(instr_gnt),
      .instr_rvalid_i(instr_rvalid), .instr_addr_o(instr_addr),
      .instr_rdata_i(instr_rdata), .instr_rdata_intg_i(instr_rdata_intg),
      .instr_err_i(instr_err),
      .data_req_o(core_data_req), .data_gnt_i(core_data_gnt),
      .data_rvalid_i(core_data_rvalid), .data_we_o(core_data_we),
      .data_be_o(core_data_be), .data_addr_o(core_data_addr),
      .data_wdata_o(core_data_wdata), .data_wdata_intg_o(),
      .data_rdata_i(core_data_rdata),
      .data_rdata_intg_i(data_rdata_intg), .data_err_i(core_data_err),
      .irq_software_i(1'b0), .irq_timer_i(1'b0), .irq_external_i(1'b0),
      .irq_fast_i(15'h0), .irq_nm_i(1'b0),
      .scramble_key_valid_i('0), .scramble_key_i('0), .scramble_nonce_i('0),
      .scramble_req_o(),
      .debug_req_i(1'b0), .crash_dump_o(), .double_fault_seen_o(),
      .fetch_enable_i(ibex_pkg::IbexMuBiOn), .mcounteren_writable_i(ibex_pkg::IbexMuBiOn),
      .core_sleep_o(), .lockstep_cmp_en_o(),
      .data_req_shadow_o(), .data_we_shadow_o(), .data_be_shadow_o(),
      .data_addr_shadow_o(), .data_wdata_shadow_o(), .data_wdata_intg_shadow_o(),
      .instr_req_shadow_o(), .instr_addr_shadow_o(),
      .alert_major_bus_o(), .alert_major_internal_o(), .alert_minor_o()
  );

  assign data_rdata_intg = 7'h0;
  assign instr_rdata_intg = 7'h0;

  ram_2p #(
      .Depth(1024*1024/4), .MemInitFile(SRAMInitFile)
  ) u_ram (
      .clk_i(clk_i), .rst_ni(rst_ni),
      .a_req_i(device_req[DevRam]), .a_we_i(device_we[DevRam]),
      .a_be_i(device_be[DevRam]), .a_addr_i(device_addr[DevRam]),
      .a_wdata_i(device_wdata[DevRam]), .a_rvalid_o(device_rvalid[DevRam]),
      .a_rdata_o(device_rdata[DevRam]),
      .b_req_i(instr_req), .b_we_i(1'b0), .b_be_i(4'h0),
      .b_addr_i(instr_addr), .b_wdata_i(32'h0),
      .b_rvalid_o(instr_rvalid), .b_rdata_o(instr_rdata)
  );

  simulator_ctrl #(.LogName("m7_ibex_reset_composed.log")) u_sim_ctrl (
      .clk_i(clk_i), .rst_ni(rst_ni),
      .req_i(device_req[DevSim]), .we_i(device_we[DevSim]),
      .be_i(device_be[DevSim]), .addr_i(device_addr[DevSim]),
      .wdata_i(device_wdata[DevSim]), .rvalid_o(device_rvalid[DevSim]),
      .rdata_o(device_rdata[DevSim])
  );

  timer #(.DataWidth(32), .AddressWidth(32)) u_timer (
      .clk_i(clk_i), .rst_ni(rst_ni),
      .timer_req_i(device_req[DevTimer]), .timer_we_i(device_we[DevTimer]),
      .timer_be_i(device_be[DevTimer]), .timer_addr_i(device_addr[DevTimer]),
      .timer_wdata_i(device_wdata[DevTimer]),
      .timer_rvalid_o(device_rvalid[DevTimer]),
      .timer_rdata_o(device_rdata[DevTimer]),
      .timer_err_o(device_err[DevTimer]), .timer_intr_o()
  );

  // Sync survives CPU-only reset (cold reset only)
  m7_reset_test_sync u_sync (
      .clk_i(clk_i), .rst_ni(rst_ni),
      .req_i(device_req[DevSync]), .we_i(device_we[DevSync]),
      .be_i(device_be[DevSync]), .addr_i(device_addr[DevSync]),
      .wdata_i(device_wdata[DevSync]),
      .rvalid_o(device_rvalid[DevSync]), .rdata_o(device_rdata[DevSync]),
      .test_ready_o(test_ready_o), .go_o(),
      .go_set_i(harness_go_set),
      .harness_result_i(harness_result_i),
      .harness_dma_cycle_i(harness_dma_cycle_i),
      .harness_cpu_cycle_i(harness_cpu_cycle_i),
      .pmp_ready_o(pmp_ready_o)
  );

  assign device_err[DevRam]  = 1'b0;
  assign device_err[DevSim]  = 1'b0;
  assign device_err[DevSync] = 1'b0;

  wire iopmp_req, iopmp_write, iopmp_gnt, iopmp_valid;
  wire [`ADDR_WIDTH-1:0] iopmp_addr;
  wire [`DATA_WIDTH-1:0] iopmp_wdata, iopmp_rdata;

  wire norm_req, norm_write, norm_gnt, norm_valid;
  wire [`ADDR_WIDTH-1:0] norm_addr;
  wire [`DATA_WIDTH-1:0] norm_wdata, norm_rdata;

  wire prot_req, prot_write, prot_gnt, prot_valid;
  wire [`ADDR_WIDTH-1:0] prot_addr;
  wire [`DATA_WIDTH-1:0] prot_wdata, prot_rdata;

  wire pmp_enable, iopmp_enable;
  wire [`ADDR_WIDTH-1:0] rule0_base, rule0_limit;
  wire [7:0] rule0_rid;
  wire rule0_re, rule0_we, rule0_valid;
  wire hw_secure_ready;
  wire [7:0] security_epoch;
  wire iopmp_busy;

  wire dma_m_req, dma_m_write, dma_m_gnt, dma_m_valid, dma_m_error;
  wire [`ADDR_WIDTH-1:0] dma_m_addr;
  wire [`DATA_WIDTH-1:0] dma_m_wdata, dma_m_rdata;
  wire [7:0] dma_m_rid;
  wire [15:0] dma_m_len;

  dma_master u_dma (
      .clk(clk_i), .rst_n(dma_reset_n),
      .start(dma_start), .src_addr(dma_src_addr), .dst_addr(dma_dst_addr),
      .wdata(dma_wdata), .length(dma_length), .requester_id(dma_requester_id),
      .mode(dma_mode),
      .req(dma_m_req), .req_addr(dma_m_addr), .req_write(dma_m_write),
      .req_wdata(dma_m_wdata), .req_requester_id(dma_m_rid),
      .req_length(dma_m_len),
      .gnt(dma_m_gnt), .valid(dma_m_valid), .rdata(dma_m_rdata),
      .error(dma_m_error),
      .done(dma_done), .last_error(dma_error), .last_rdata(dma_rdata)
  );

  security_config u_sec (
      .clk(clk_i), .rst_n(security_config_reset_n),
      .pmp_enable(pmp_enable), .iopmp_enable(iopmp_enable),
      .rule0_base(rule0_base), .rule0_limit(rule0_limit),
      .rule0_rid(rule0_rid), .rule0_re(rule0_re), .rule0_we(rule0_we),
      .rule0_valid(rule0_valid),
      .secure_ready(hw_secure_ready), .security_epoch(security_epoch),
      .cfg_write(cfg_write), .cfg_addr(cfg_addr), .cfg_wdata(cfg_wdata)
  );

  iopmp u_iopmp (
      .clk(clk_i), .rst_n(iopmp_reset_n), .enable(iopmp_enable),
      .dma_req(dma_m_req), .dma_addr(dma_m_addr), .dma_write(dma_m_write),
      .dma_wdata(dma_m_wdata), .dma_requester_id(dma_m_rid),
      .dma_length(dma_m_len),
      .dma_gnt(dma_m_gnt), .dma_valid(dma_m_valid), .dma_rdata(dma_m_rdata),
      .dma_error(dma_m_error),
      .dma_req_out(iopmp_req), .dma_addr_out(iopmp_addr),
      .dma_write_out(iopmp_write), .dma_wdata_out(iopmp_wdata),
      .bus_gnt(iopmp_gnt), .bus_valid(iopmp_valid), .bus_rdata(iopmp_rdata),
      .rule0_base(rule0_base), .rule0_limit(rule0_limit), .rule0_rid(rule0_rid),
      .rule0_re(rule0_re), .rule0_we(rule0_we), .rule0_valid(rule0_valid),
      .secure_ready(hw_secure_ready), .security_epoch(security_epoch),
      .txn_valid(iopmp_txn_valid), .txn_master(),
      .txn_addr(), .txn_write(), .txn_authorized_at_admission(iopmp_txn_authorized),
      .txn_requester_id(iopmp_txn_rid), .txn_length(), .txn_age(), .busy(iopmp_busy)
  );

  m7_research_arbiter u_ic (
      .clk(clk_i), .rst_n(interconnect_reset_n),
      .cpu_req(cpu_ic_req), .cpu_addr(cpu_ic_addr), .cpu_write(cpu_ic_write),
      .cpu_wdata(cpu_ic_wdata),
      .cpu_gnt(cpu_ic_gnt), .cpu_valid(cpu_ic_valid), .cpu_rdata(cpu_ic_rdata),
      .dma_req(iopmp_req), .dma_addr(iopmp_addr), .dma_write(iopmp_write),
      .dma_wdata(iopmp_wdata),
      .dma_gnt(iopmp_gnt), .dma_valid(iopmp_valid), .dma_rdata(iopmp_rdata),
      .norm_req(norm_req), .norm_addr(norm_addr), .norm_write(norm_write),
      .norm_wdata(norm_wdata), .norm_gnt(norm_gnt), .norm_valid(norm_valid),
      .norm_rdata(norm_rdata),
      .prot_req(prot_req), .prot_addr(prot_addr), .prot_write(prot_write),
      .prot_wdata(prot_wdata), .prot_gnt(prot_gnt), .prot_valid(prot_valid),
      .prot_rdata(prot_rdata)
  );

  sram #(.DEPTH(16384)) u_norm_sram (
      .clk(clk_i), .rst_n(interconnect_reset_n),
      .req(norm_req), .write(norm_write), .addr(norm_addr), .wdata(norm_wdata),
      .gnt(norm_gnt), .valid(norm_valid), .rdata(norm_rdata),
      .mem_changed(), .changed_addr(), .changed_wdata(),
      .peek_addr(32'h0), .peek_data()
  );

  // MEM-RET: protected array not cleared; domain reset held high in primary tests
  sram #(.DEPTH(16384)) u_prot_sram (
      .clk(clk_i), .rst_n(protected_memory_reset_n),
      .req(prot_req), .write(prot_write), .addr(prot_addr), .wdata(prot_wdata),
      .gnt(prot_gnt), .valid(prot_valid), .rdata(prot_rdata),
      .mem_changed(prot_mem_changed), .changed_addr(prot_changed_addr),
      .changed_wdata(prot_changed_wdata),
      .peek_addr(prot_peek_addr), .peek_data(prot_mem_word0)
  );

  assign prot_peek_addr = `M7_PROTECT_SRAM_BASE + `M7_PROTECT_TEST_OFF;

  logic [31:0] stamp_cpu_release, stamp_dma_release, stamp_iopmp_release;
  logic [31:0] stamp_sec_release, stamp_ic_release, stamp_pmp_ready;
  logic [31:0] stamp_iopmp_ready, stamp_secure_ready, stamp_dma_req, stamp_mem_commit, cycle_o;

  m7_realcore_reset_harness u_harness (
      .clk(clk_i), .rst_n(rst_ni),
      .cpu_reset_n(cpu_reset_n), .dma_reset_n(dma_reset_n),
      .iopmp_reset_n(iopmp_reset_n),
      .security_config_reset_n(security_config_reset_n),
      .interconnect_reset_n(interconnect_reset_n),
      .protected_memory_reset_n(protected_memory_reset_n),
      .cfg_write(cfg_write), .cfg_addr(cfg_addr), .cfg_wdata(cfg_wdata),
      .dma_start(dma_start), .dma_src_addr(dma_src_addr),
      .dma_dst_addr(dma_dst_addr), .dma_wdata(dma_wdata),
      .dma_length(dma_length), .dma_requester_id(dma_requester_id),
      .dma_mode(dma_mode), .dma_done(dma_done), .dma_error(dma_error),
      .init_req(init_req), .init_write(init_write),
      .init_addr(init_addr), .init_wdata(init_wdata),
      .init_gnt(init_gnt), .init_valid(init_valid),
      .prot_mem_word0(prot_mem_word0), .prot_mem_changed(prot_mem_changed),
      .pmp_ready(pmp_ready_o), .iopmp_enable(iopmp_enable), .rule0_valid(rule0_valid),
      .harness_go_set(harness_go_set),
      .harness_result(harness_result_i),
      .harness_dma_cycle(harness_dma_cycle_i),
      .harness_cpu_cycle(harness_cpu_cycle_i),
      .stamp_cpu_release(stamp_cpu_release),
      .stamp_dma_release(stamp_dma_release),
      .stamp_iopmp_release(stamp_iopmp_release),
      .stamp_sec_release(stamp_sec_release),
      .stamp_ic_release(stamp_ic_release),
      .stamp_pmp_ready(stamp_pmp_ready),
      .stamp_iopmp_ready(stamp_iopmp_ready),
      .stamp_secure_ready(stamp_secure_ready),
      .stamp_dma_req(stamp_dma_req),
      .stamp_mem_commit(stamp_mem_commit),
      .cycle_o(cycle_o),
      .sys_secure_ready(sys_secure_ready),
      .test_finished(test_finished)
  );

endmodule
