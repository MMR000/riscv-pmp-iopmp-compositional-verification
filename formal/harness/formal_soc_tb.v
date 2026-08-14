// Compositional formal harness: production PMP + IOPMP + interconnect + SRAM.
`include "bus_pkg.vh"
`include "formal_helpers.vh"

module formal_soc_tb (
    input wire clk,
    input wire rst_n
);

    `FORMAL_RESET_CTRL(clk, dut_rst_n, formal_warmup)

    wire                    cfg_write;
    wire [`ADDR_WIDTH-1:0]  cfg_addr;
    wire [`DATA_WIDTH-1:0]  cfg_wdata;

    reg                     cpu_req;
    reg [`ADDR_WIDTH-1:0]   cpu_addr;
    reg                     cpu_write;
    reg [`DATA_WIDTH-1:0]   cpu_wdata;
    reg                     cpu_privilege;

    reg                     dma_req;
    reg [`ADDR_WIDTH-1:0]   dma_addr;
    reg                     dma_write;
    reg [`DATA_WIDTH-1:0]   dma_wdata;
    reg [7:0]               dma_requester_id;
    reg [15:0]              dma_length;

    wire pmp_enable, iopmp_enable, secure_ready;
    wire [`ADDR_WIDTH-1:0] rule0_base, rule0_limit;
    wire [7:0] rule0_rid;
    wire rule0_re, rule0_we, rule0_valid;

    wire pmp_req, pmp_write, pmp_gnt, pmp_valid;
    wire [`ADDR_WIDTH-1:0] pmp_addr;
    wire [`DATA_WIDTH-1:0] pmp_wdata, pmp_rdata;

    wire iopmp_req, iopmp_write, iopmp_gnt, iopmp_valid;
    wire [`ADDR_WIDTH-1:0] iopmp_addr;
    wire [`DATA_WIDTH-1:0] iopmp_wdata, iopmp_rdata;

    wire norm_req, norm_write, norm_gnt, norm_valid;
    wire [`ADDR_WIDTH-1:0] norm_addr;
    wire [`DATA_WIDTH-1:0] norm_wdata, norm_rdata;

    wire prot_req, prot_write, prot_gnt, prot_valid;
    wire [`ADDR_WIDTH-1:0] prot_addr;
    wire [`DATA_WIDTH-1:0] prot_wdata, prot_rdata;
    wire prot_mem_changed;
    wire [`ADDR_WIDTH-1:0] prot_changed_addr;
    wire [`DATA_WIDTH-1:0] prot_changed_wdata;

    wire iopmp_txn_valid, iopmp_txn_write, iopmp_txn_authorized;
    wire [7:0] iopmp_txn_rid;
    wire [`ADDR_WIDTH-1:0] iopmp_txn_addr;

    security_config u_sec (
        .clk(clk), .rst_n(dut_rst_n),
        .pmp_enable(pmp_enable), .iopmp_enable(iopmp_enable),
        .rule0_base(rule0_base), .rule0_limit(rule0_limit),
        .rule0_rid(rule0_rid), .rule0_re(rule0_re), .rule0_we(rule0_we),
        .rule0_valid(rule0_valid), .secure_ready(secure_ready),
        .security_epoch(),
        .cfg_write(cfg_write), .cfg_addr(cfg_addr), .cfg_wdata(cfg_wdata)
    );

    pmp u_pmp (
        .clk(clk), .rst_n(dut_rst_n), .enable(pmp_enable),
        .cpu_req(cpu_req), .cpu_addr(cpu_addr), .cpu_write(cpu_write),
        .cpu_wdata(cpu_wdata), .cpu_privilege(cpu_privilege),
        .cpu_gnt(), .cpu_valid(), .cpu_rdata(),
        .cpu_error(), .cpu_req_out(pmp_req), .cpu_addr_out(pmp_addr),
        .cpu_write_out(pmp_write), .cpu_wdata_out(pmp_wdata),
        .bus_gnt(pmp_gnt), .bus_valid(pmp_valid), .bus_rdata(pmp_rdata)
    );

    iopmp u_iopmp (
        .clk(clk), .rst_n(dut_rst_n), .enable(iopmp_enable),
        .dma_req(dma_req), .dma_addr(dma_addr), .dma_write(dma_write),
        .dma_wdata(dma_wdata), .dma_requester_id(dma_requester_id),
        .dma_length(dma_length),
        .dma_gnt(), .dma_valid(), .dma_rdata(), .dma_error(),
        .dma_req_out(iopmp_req), .dma_addr_out(iopmp_addr),
        .dma_write_out(iopmp_write), .dma_wdata_out(iopmp_wdata),
        .bus_gnt(iopmp_gnt), .bus_valid(iopmp_valid), .bus_rdata(iopmp_rdata),
        .rule0_base(rule0_base), .rule0_limit(rule0_limit),
        .rule0_rid(rule0_rid),         .rule0_re(rule0_re), .rule0_we(rule0_we),
        .rule0_valid(rule0_valid),
        .secure_ready(secure_ready), .security_epoch(),
        .txn_valid(iopmp_txn_valid), .txn_master(),
        .txn_addr(iopmp_txn_addr), .txn_write(iopmp_txn_write),
        .txn_authorized_at_admission(iopmp_txn_authorized),
        .txn_requester_id(iopmp_txn_rid), .txn_length(), .txn_age(), .busy()
    );

    bus_interconnect u_ic (
        .clk(clk), .rst_n(dut_rst_n),
        .cpu_req(pmp_req), .cpu_addr(pmp_addr), .cpu_write(pmp_write),
        .cpu_wdata(pmp_wdata),
        .cpu_gnt(pmp_gnt), .cpu_valid(pmp_valid), .cpu_rdata(pmp_rdata),
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

    sram #(.DEPTH(256)) u_norm (
        .clk(clk), .rst_n(dut_rst_n),
        .req(norm_req), .write(norm_write), .addr(norm_addr), .wdata(norm_wdata),
        .gnt(norm_gnt), .valid(norm_valid), .rdata(norm_rdata),
        .mem_changed(), .changed_addr(), .changed_wdata(),
        .peek_addr(32'h0), .peek_data()
    );

    sram #(.DEPTH(256)) u_prot (
        .clk(clk), .rst_n(dut_rst_n),
        .req(prot_req), .write(prot_write), .addr(prot_addr), .wdata(prot_wdata),
        .gnt(prot_gnt), .valid(prot_valid), .rdata(prot_rdata),
        .mem_changed(prot_mem_changed), .changed_addr(prot_changed_addr),
        .changed_wdata(prot_changed_wdata),
        .peek_addr(`ADDR_PROTECT_SRAM_BASE), .peek_data()
    );

    wire iopmp_hold_authorized;
    wire iopmp_hold_write;
    wire [`ADDR_WIDTH-1:0] iopmp_hold_addr;
    wire pmp_hold_privilege;
    wire pmp_hold_write;
    wire [`ADDR_WIDTH-1:0] pmp_hold_addr;
    wire [1:0] iopmp_state;

    assign iopmp_hold_authorized = u_iopmp.hold_authorized;
    assign iopmp_hold_write      = u_iopmp.hold_write;
    assign iopmp_hold_addr       = u_iopmp.hold_addr;
    assign pmp_hold_privilege    = u_pmp.hold_privilege;
    assign pmp_hold_write        = u_pmp.hold_write;
    assign pmp_hold_addr         = u_pmp.hold_addr;
    assign iopmp_state           = u_iopmp.state;

    localparam ST_IDLE = 2'd0;

    reg [2:0] boot_cnt;
    always @(posedge clk) begin
        if (!dut_rst_n) begin
            boot_cnt <= 3'd0;
            cpu_req <= 1'b0;
            cpu_addr <= 32'h0;
            cpu_write <= 1'b0;
            cpu_wdata <= 32'h0;
            cpu_privilege <= 1'b0;
            dma_req <= 1'b0;
            dma_addr <= 32'h0;
            dma_write <= 1'b0;
            dma_wdata <= 32'h0;
            dma_requester_id <= 8'h0;
            dma_length <= 16'h0;
        end else if (boot_cnt < 3'd4)
            boot_cnt <= boot_cnt + 3'd1;
    end

    wire trusted_cfg = dut_rst_n && (boot_cnt == 3'd1 || boot_cnt == 3'd2);
    wire boot_done = (boot_cnt >= 3'd3);
    wire check_ready = formal_warmup && boot_done;

    always @(*) begin
        cfg_write = trusted_cfg;
        cfg_addr  = (boot_cnt == 3'd1) ? (`ADDR_SEC_CFG_BASE + 32'h4) :
                    (boot_cnt == 3'd2) ? (`ADDR_SEC_CFG_BASE + 32'h108) : 32'h0;
        cfg_wdata = (boot_cnt == 3'd1) ? 32'h1 :
                    {21'b0, 1'b1, 1'b1, 1'b1, rule0_rid};
    end

    // No master requests until trusted configuration is loaded; then allow concurrency.
    always @(*) assume (`IN_PROT(cpu_addr) || !cpu_req);
    always @(*) assume (`IN_PROT(dma_addr) || !dma_req);
    always @(*) assume (check_ready || (!cpu_req && !dma_req));

    always @(*) assume (!check_ready || (pmp_enable && iopmp_enable && rule0_valid));
    always @(*) assume (!cfg_write || trusted_cfg);

    // SP-02/SP-04/SP-05 admission checks in RTL (`ifdef FORMAL).

    // SP-10: attribute protected writes via interconnect master + active transaction.
    wire cpu_completing = check_ready && prot_mem_changed && pmp_valid && u_ic.serve_cpu;
    wire dma_completing = check_ready && prot_mem_changed && iopmp_valid && !u_ic.serve_cpu;

    always @(posedge clk) begin
        if (cpu_completing) begin
            assert(u_ic.active_write && (u_ic.active_addr == prot_changed_addr));
            assert(pmp_hold_privilege && pmp_enable);
        end
        if (dma_completing) begin
            assert(u_ic.active_write && (u_ic.active_addr == prot_changed_addr));
            assert(iopmp_hold_authorized && iopmp_enable);
        end
    end

    // Exclude anyinit mid-transaction states until configuration is ready.
    always @(*) assume(!check_ready ||
                      (u_ic.arb == 2'd0 && !u_pmp.pending && iopmp_state == ST_IDLE));

    wire pmp_pending = u_pmp.pending;
    wire iopmp_busy = (iopmp_state != ST_IDLE);
    always @(posedge clk) begin
        if (check_ready && pmp_pending) begin
            assume($stable(cpu_privilege));
            assume($stable(cpu_addr));
            assume($stable(cpu_write));
        end
        if (check_ready && iopmp_busy) begin
            assume($stable(dma_requester_id));
            assume($stable(dma_addr));
            assume($stable(dma_write));
        end
    end

    wire unauth_cpu = check_ready && cpu_req && !u_pmp.pending && cpu_write &&
                      `IN_PROT(cpu_addr) && !cpu_privilege;
    wire unauth_dma = check_ready && dma_req && (iopmp_state == ST_IDLE) &&
                      dma_write && `IN_PROT(dma_addr) &&
                      (dma_requester_id != rule0_rid || !rule0_we);
    wire auth_cpu = check_ready && cpu_req && !u_pmp.pending && cpu_write &&
                    `IN_PROT(cpu_addr) && cpu_privilege;
    wire auth_dma = check_ready && dma_req && (iopmp_state == ST_IDLE) &&
                    dma_write && `IN_PROT(dma_addr) &&
                    (dma_requester_id == rule0_rid) && rule0_we;

    always @(posedge clk) cover(check_ready && cpu_req && dma_req);
    always @(posedge clk) cover(check_ready && unauth_cpu && auth_dma);
    always @(posedge clk) cover(check_ready && auth_cpu && unauth_dma);
    always @(posedge clk) cover(check_ready && unauth_cpu && unauth_dma);
    always @(posedge clk) cover(check_ready && cpu_addr == dma_addr && cpu_req && dma_req);
    always @(posedge clk) cover(check_ready && prot_mem_changed);

endmodule
