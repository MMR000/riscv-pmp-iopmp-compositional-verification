// M7 Phase D synthesizable PPA top (real Ibex + optional composition).
// Simulation-only blocks excluded — see docs/m7_ppa_scope.md
`include "m7_composed_map.vh"
`include "bus_pkg.vh"

`ifndef RV32M
  `define RV32M ibex_pkg::RV32MFast
`endif

module m7_ppa_top #(
    parameter bit PMPEnable            = 1'b1,
    parameter int PMPNumRegions          = 8,
    parameter int PMPGranularity         = 0,
    parameter bit INCLUDE_COMPOSITION    = 1'b0,
    parameter bit INCLUDE_DOMAIN_RESET   = 1'b0
) (
    input  logic        clk,
    input  logic        rst_n,
    // Anti-constant-fold policy / transaction stimulus (top-level retained)
    input  logic        cfg_write_i,
    input  logic [31:0] cfg_addr_i,
    input  logic [31:0] cfg_wdata_i,
    input  logic        dma_start_i,
    input  logic [31:0] dma_src_addr_i,
    input  logic [31:0] dma_dst_addr_i,
    input  logic [31:0] dma_wdata_i,
    input  logic [15:0] dma_length_i,
    input  logic [7:0]  dma_requester_id_i,
    input  logic [1:0]  dma_mode_i,
    input  logic        cpu_release_i,
    input  logic        dma_release_i,
    input  logic        iopmp_release_i,
    input  logic        sec_release_i,
    input  logic        ic_release_i,
    output logic        secure_ready_o,
    output logic [7:0]  security_epoch_o,
    output logic        iopmp_busy_o,
    output logic        dma_done_o,
    output logic        dma_error_o,
    // Live Ibex observation ports — prevent dead-logic removal of the core.
    output logic        instr_req_o,
    output logic [31:0] instr_addr_o,
    output logic        data_req_o,
    output logic        data_we_o,
    output logic [31:0] data_addr_o,
    output logic        data_err_o,
    output logic        core_sleep_o
);

    logic cpu_rst_n, dma_rst_n, iopmp_rst_n, sec_rst_n, ic_rst_n;
    if (INCLUDE_DOMAIN_RESET) begin : g_domain
        m7_ppa_domain_reset u_dom (
            .clk(clk), .rst_n(rst_n),
            .cpu_release_i(cpu_release_i), .dma_release_i(dma_release_i),
            .iopmp_release_i(iopmp_release_i), .sec_release_i(sec_release_i),
            .ic_release_i(ic_release_i),
            .cpu_reset_n(cpu_rst_n), .dma_reset_n(dma_rst_n),
            .iopmp_reset_n(iopmp_rst_n), .security_config_reset_n(sec_rst_n),
            .interconnect_reset_n(ic_rst_n)
        );
    end else begin : g_flat
        assign cpu_rst_n = rst_n;
        assign dma_rst_n = rst_n;
        assign iopmp_rst_n = rst_n;
        assign sec_rst_n = rst_n;
        assign ic_rst_n = rst_n;
    end

    logic instr_req, instr_gnt, instr_rvalid, instr_err;
    logic [31:0] instr_addr, instr_rdata;
    logic core_data_req, core_data_we, core_data_gnt, core_data_rvalid, core_data_err;
    logic [3:0] core_data_be;
    logic [31:0] core_data_addr, core_data_wdata, core_data_rdata;
    logic [6:0] data_rdata_intg, instr_rdata_intg;

    logic research_sel, research_gnt, research_valid, research_req, research_write;
    logic research_outstanding;
    logic [31:0] research_rdata, research_addr, research_wdata;

    wire cpu_ic_req, cpu_ic_write, cpu_ic_gnt, cpu_ic_valid;
    wire [`ADDR_WIDTH-1:0] cpu_ic_addr;
    wire [`DATA_WIDTH-1:0] cpu_ic_wdata, cpu_ic_rdata;

    function automatic logic is_research_addr(input logic [31:0] a);
        is_research_addr =
            ((a >= `M7_NORMAL_SRAM_BASE) && (a <= `M7_NORMAL_SRAM_LIMIT)) ||
            ((a >= `M7_PROTECT_SRAM_BASE) && (a <= `M7_PROTECT_SRAM_LIMIT));
    endfunction

    assign research_sel = INCLUDE_COMPOSITION && core_data_req && is_research_addr(core_data_addr);

    always_ff @(posedge clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n)
            research_outstanding <= 1'b0;
        else if (research_sel && research_gnt)
            research_outstanding <= 1'b1;
        else if (research_valid)
            research_outstanding <= 1'b0;
    end

    // Unpacked host arrays match bus.sv ports (slang rejects concatenation
    // of scalars onto unpacked-array output ports).
    localparam int NrDevices = 2;
    localparam int NrHosts   = 1;
    typedef enum logic [1:0] { DevRam, DevTimer } bus_dev_e;

    logic           host_req     [NrHosts];
    logic           host_gnt     [NrHosts];
    logic           host_we      [NrHosts];
    logic           host_rvalid  [NrHosts];
    logic           host_err     [NrHosts];
    logic [31:0]    host_addr    [NrHosts];
    logic [31:0]    host_wdata   [NrHosts];
    logic [31:0]    host_rdata   [NrHosts];
    logic [3:0]     host_be      [NrHosts];

    assign host_req[0]   = core_data_req && !research_sel && !research_outstanding;
    assign host_addr[0]  = core_data_addr;
    assign host_we[0]    = core_data_we;
    assign host_be[0]    = core_data_be;
    assign host_wdata[0] = core_data_wdata;

    if (INCLUDE_COMPOSITION) begin : g_adapt
        m7_ibex_data_adapter u_data_adapt (
            .clk_i(clk), .rst_ni(ic_rst_n),
            .ibex_req_i(research_sel ? core_data_req : 1'b0),
            .ibex_gnt_o(research_gnt), .ibex_rvalid_o(research_valid),
            .ibex_we_i(core_data_we), .ibex_be_i(core_data_be),
            .ibex_addr_i(core_data_addr), .ibex_wdata_i(core_data_wdata),
            .ibex_rdata_o(research_rdata), .ibex_err_o(),
            .cpu_req_o(research_req), .cpu_addr_o(research_addr),
            .cpu_write_o(research_write), .cpu_wdata_o(research_wdata),
            .cpu_gnt_i(cpu_ic_gnt), .cpu_valid_i(cpu_ic_valid),
            .cpu_rdata_i(cpu_ic_rdata)
        );
        assign cpu_ic_req   = research_req;
        assign cpu_ic_addr  = research_addr;
        assign cpu_ic_write = research_write;
        assign cpu_ic_wdata = research_wdata;
    end else begin : g_no_adapt
        assign research_gnt = 1'b0;
        assign research_valid = 1'b0;
        assign research_rdata = 32'h0;
        assign cpu_ic_req = 1'b0;
        assign cpu_ic_addr = 32'h0;
        assign cpu_ic_write = 1'b0;
        assign cpu_ic_wdata = 32'h0;
    end

    assign core_data_gnt    = research_sel ? research_gnt : host_gnt[0];
    assign core_data_rvalid = research_outstanding ? research_valid : host_rvalid[0];
    assign core_data_rdata  = research_outstanding ? research_rdata : host_rdata[0];
    assign core_data_err    = research_outstanding ? 1'b0 : host_err[0];

    assign instr_gnt = instr_req;
    assign instr_err = 1'b0;
    assign data_rdata_intg = 7'h0;
    assign instr_rdata_intg = 7'h0;

    logic device_req[NrDevices], device_we[NrDevices], device_rvalid[NrDevices], device_err[NrDevices];
    logic [31:0] device_addr[NrDevices], device_wdata[NrDevices], device_rdata[NrDevices];
    logic [3:0] device_be[NrDevices];
    logic [31:0] cfg_device_addr_base[NrDevices], cfg_device_addr_mask[NrDevices];

    assign cfg_device_addr_base[DevRam]   = `M7_IBEX_RAM_BASE;
    assign cfg_device_addr_mask[DevRam]   = `M7_IBEX_RAM_MASK;
    assign cfg_device_addr_base[DevTimer] = `M7_TIMER_BASE;
    assign cfg_device_addr_mask[DevTimer] = `M7_TIMER_MASK;

    bus #(.NrDevices(NrDevices), .NrHosts(NrHosts), .DataWidth(32), .AddressWidth(32)) u_bus (
        .clk_i(clk), .rst_ni(rst_n),
        .host_req_i(host_req), .host_gnt_o(host_gnt),
        .host_addr_i(host_addr), .host_we_i(host_we), .host_be_i(host_be),
        .host_wdata_i(host_wdata), .host_rvalid_o(host_rvalid),
        .host_rdata_o(host_rdata), .host_err_o(host_err),
        .device_req_o(device_req), .device_addr_o(device_addr),
        .device_we_o(device_we), .device_be_o(device_be),
        .device_wdata_o(device_wdata), .device_rvalid_i(device_rvalid),
        .device_rdata_i(device_rdata), .device_err_i(device_err),
        .cfg_device_addr_base, .cfg_device_addr_mask
    );

    ibex_top #(
        .PMPEnable(PMPEnable), .PMPGranularity(PMPGranularity),
        .PMPNumRegions(PMPNumRegions), .RV32M(`RV32M)
    ) u_ibex (
        .clk_i(clk), .rst_ni(cpu_rst_n),
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
        .core_sleep_o(core_sleep_o), .lockstep_cmp_en_o(),
        .data_req_shadow_o(), .data_we_shadow_o(), .data_be_shadow_o(),
        .data_addr_shadow_o(), .data_wdata_shadow_o(), .data_wdata_intg_shadow_o(),
        .instr_req_shadow_o(), .instr_addr_shadow_o(),
        .alert_major_bus_o(), .alert_major_internal_o(), .alert_minor_o()
    );

    m7_ppa_mem_slave u_imem (
        .clk(clk), .rst_n(rst_n),
        .req(instr_req), .write(1'b0), .addr(instr_addr), .wdata(32'h0),
        .gnt(), .valid(instr_rvalid), .rdata(instr_rdata)
    );

    m7_ppa_mem_slave u_dram (
        .clk(clk), .rst_n(rst_n),
        .req(device_req[DevRam]), .write(device_we[DevRam]),
        .addr(device_addr[DevRam]), .wdata(device_wdata[DevRam]),
        .gnt(), .valid(device_rvalid[DevRam]), .rdata(device_rdata[DevRam])
    );

    timer #(.DataWidth(32), .AddressWidth(32)) u_timer (
        .clk_i(clk), .rst_ni(rst_n),
        .timer_req_i(device_req[DevTimer]), .timer_we_i(device_we[DevTimer]),
        .timer_be_i(device_be[DevTimer]), .timer_addr_i(device_addr[DevTimer]),
        .timer_wdata_i(device_wdata[DevTimer]),
        .timer_rvalid_o(device_rvalid[DevTimer]),
        .timer_rdata_o(device_rdata[DevTimer]),
        .timer_err_o(device_err[DevTimer]), .timer_intr_o()
    );
    assign device_err[DevRam] = 1'b0;

    // ---- Optional DMA + IOPMP composition (J2/J3) ----
    logic cfg_write;
    logic [31:0] cfg_addr, cfg_wdata;
    logic dma_start, dma_done, dma_error;
    logic [31:0] dma_src_addr, dma_dst_addr, dma_wdata, dma_rdata;
    logic [15:0] dma_length;
    logic [7:0] dma_requester_id;
    logic [1:0] dma_mode;

    logic pmp_enable, iopmp_enable;
    logic [`ADDR_WIDTH-1:0] rule0_base, rule0_limit;
    logic [7:0] rule0_rid;
    logic rule0_re, rule0_we, rule0_valid;
    logic secure_ready;
    logic [7:0] security_epoch;
    logic iopmp_busy;

    assign cfg_write         = INCLUDE_COMPOSITION ? cfg_write_i : 1'b0;
    assign cfg_addr          = cfg_addr_i;
    assign cfg_wdata         = cfg_wdata_i;
    assign dma_start         = INCLUDE_COMPOSITION ? dma_start_i : 1'b0;
    assign dma_src_addr      = dma_src_addr_i;
    assign dma_dst_addr      = dma_dst_addr_i;
    assign dma_wdata         = dma_wdata_i;
    assign dma_length        = dma_length_i;
    assign dma_requester_id  = dma_requester_id_i;
    assign dma_mode          = dma_mode_i;

    wire dma_m_req, dma_m_write, dma_m_gnt, dma_m_valid, dma_m_error;
    wire [`ADDR_WIDTH-1:0] dma_m_addr;
    wire [`DATA_WIDTH-1:0] dma_m_wdata, dma_m_rdata;
    wire [7:0] dma_m_rid;
    wire [15:0] dma_m_len;
    wire iopmp_req, iopmp_write, iopmp_gnt, iopmp_valid;
    wire [`ADDR_WIDTH-1:0] iopmp_addr;
    wire [`DATA_WIDTH-1:0] iopmp_wdata, iopmp_rdata;
    wire norm_req, norm_write, norm_gnt, norm_valid;
    wire [`ADDR_WIDTH-1:0] norm_addr;
    wire [`DATA_WIDTH-1:0] norm_wdata, norm_rdata;
    wire prot_req, prot_write, prot_gnt, prot_valid;
    wire [`ADDR_WIDTH-1:0] prot_addr;
    wire [`DATA_WIDTH-1:0] prot_wdata, prot_rdata;

    if (INCLUDE_COMPOSITION) begin : g_comp
        dma_master u_dma (
            .clk(clk), .rst_n(dma_rst_n),
            .start(dma_start), .src_addr(dma_src_addr), .dst_addr(dma_dst_addr),
            .wdata(dma_wdata), .length(dma_length), .requester_id(dma_requester_id),
            .mode(dma_mode),
            .req(dma_m_req), .req_addr(dma_m_addr), .req_write(dma_m_write),
            .req_wdata(dma_m_wdata), .req_requester_id(dma_m_rid), .req_length(dma_m_len),
            .gnt(dma_m_gnt), .valid(dma_m_valid), .rdata(dma_m_rdata),
            .error(dma_m_error), .done(dma_done), .last_error(dma_error), .last_rdata(dma_rdata)
        );

        security_config u_sec (
            .clk(clk), .rst_n(sec_rst_n),
            .pmp_enable(pmp_enable), .iopmp_enable(iopmp_enable),
            .rule0_base(rule0_base), .rule0_limit(rule0_limit),
            .rule0_rid(rule0_rid), .rule0_re(rule0_re), .rule0_we(rule0_we),
            .rule0_valid(rule0_valid),
            .secure_ready(secure_ready), .security_epoch(security_epoch),
            .cfg_write(cfg_write), .cfg_addr(cfg_addr), .cfg_wdata(cfg_wdata)
        );

        iopmp u_iopmp (
            .clk(clk), .rst_n(iopmp_rst_n), .enable(iopmp_enable),
            .dma_req(dma_m_req), .dma_addr(dma_m_addr), .dma_write(dma_m_write),
            .dma_wdata(dma_m_wdata), .dma_requester_id(dma_m_rid), .dma_length(dma_m_len),
            .dma_gnt(dma_m_gnt), .dma_valid(dma_m_valid), .dma_rdata(dma_m_rdata),
            .dma_error(dma_m_error),
            .dma_req_out(iopmp_req), .dma_addr_out(iopmp_addr),
            .dma_write_out(iopmp_write), .dma_wdata_out(iopmp_wdata),
            .bus_gnt(iopmp_gnt), .bus_valid(iopmp_valid), .bus_rdata(iopmp_rdata),
            .rule0_base(rule0_base), .rule0_limit(rule0_limit), .rule0_rid(rule0_rid),
            .rule0_re(rule0_re), .rule0_we(rule0_we), .rule0_valid(rule0_valid),
            .secure_ready(secure_ready), .security_epoch(security_epoch),
            .txn_valid(), .txn_master(), .txn_addr(), .txn_write(),
            .txn_authorized_at_admission(), .txn_requester_id(),
            .txn_length(), .txn_age(), .busy(iopmp_busy)
        );

        m7_research_arbiter u_ic (
            .clk(clk), .rst_n(ic_rst_n),
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

        m7_ppa_mem_slave u_norm (.clk(clk), .rst_n(rst_n),
            .req(norm_req), .write(norm_write), .addr(norm_addr), .wdata(norm_wdata),
            .gnt(norm_gnt), .valid(norm_valid), .rdata(norm_rdata));
        m7_ppa_mem_slave u_prot (.clk(clk), .rst_n(rst_n),
            .req(prot_req), .write(prot_write), .addr(prot_addr), .wdata(prot_wdata),
            .gnt(prot_gnt), .valid(prot_valid), .rdata(prot_rdata));
        assign secure_ready_o   = secure_ready;
        assign security_epoch_o = security_epoch;
        assign iopmp_busy_o     = iopmp_busy;
        assign dma_done_o       = dma_done;
        assign dma_error_o      = dma_error;
    end else begin : g_nocomp
        assign secure_ready_o = 1'b0;
        assign security_epoch_o = 8'h0;
        assign iopmp_busy_o = 1'b0;
        assign dma_done_o = 1'b0;
        assign dma_error_o = 1'b0;
    end

    assign instr_req_o  = instr_req;
    assign instr_addr_o = instr_addr;
    assign data_req_o   = core_data_req;
    assign data_we_o    = core_data_we;
    assign data_addr_o  = core_data_addr;
    assign data_err_o   = core_data_err;

endmodule
