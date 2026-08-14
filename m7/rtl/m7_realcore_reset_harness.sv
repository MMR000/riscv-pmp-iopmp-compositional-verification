// Phase C reset/recovery harness (deterministic RC tests).
// IOPMP programming = TRUSTED_CONFIGURATION. PMP_READY = firmware milestone.
`include "bus_pkg.vh"
`include "m7_composed_map.vh"

module m7_realcore_reset_harness (
    input  wire                     clk,
    input  wire                     rst_n,
    output reg                      cpu_reset_n,
    output reg                      dma_reset_n,
    output reg                      iopmp_reset_n,
    output reg                      security_config_reset_n,
    output reg                      interconnect_reset_n,
    output reg                      protected_memory_reset_n,
    output reg                      cfg_write,
    output reg  [`ADDR_WIDTH-1:0]   cfg_addr,
    output reg  [`DATA_WIDTH-1:0]   cfg_wdata,
    output reg                      dma_start,
    output reg  [`ADDR_WIDTH-1:0]   dma_src_addr,
    output reg  [`ADDR_WIDTH-1:0]   dma_dst_addr,
    output reg  [`DATA_WIDTH-1:0]   dma_wdata,
    output reg  [15:0]              dma_length,
    output reg  [7:0]               dma_requester_id,
    output reg  [1:0]               dma_mode,
    input  wire                     dma_done,
    input  wire                     dma_error,
    output reg                      init_req,
    output reg                      init_write,
    output reg  [`ADDR_WIDTH-1:0]   init_addr,
    output reg  [`DATA_WIDTH-1:0]   init_wdata,
    input  wire                     init_gnt,
    input  wire                     init_valid,
    input  wire [`DATA_WIDTH-1:0]   prot_mem_word0,
    input  wire                     prot_mem_changed,
    input  wire                     pmp_ready,
    input  wire                     iopmp_enable,
    input  wire                     rule0_valid,
    output reg                      harness_go_set,
    output reg  [31:0]              harness_result,
    output reg  [31:0]              harness_dma_cycle,
    output reg  [31:0]              harness_cpu_cycle,
    output reg  [31:0]              stamp_cpu_release,
    output reg  [31:0]              stamp_dma_release,
    output reg  [31:0]              stamp_iopmp_release,
    output reg  [31:0]              stamp_sec_release,
    output reg  [31:0]              stamp_ic_release,
    output reg  [31:0]              stamp_pmp_ready,
    output reg  [31:0]              stamp_iopmp_ready,
    output reg  [31:0]              stamp_secure_ready,
    output reg  [31:0]              stamp_dma_req,
    output reg  [31:0]              stamp_mem_commit,
    output reg  [31:0]              cycle_o,
    output wire                     sys_secure_ready,
    output reg                      test_finished
);
    // cycle_o is the free-running cycle counter

    localparam [`ADDR_WIDTH-1:0] PROT_WORD = `M7_PROTECT_SRAM_BASE + `M7_PROTECT_TEST_OFF;
    localparam [`DATA_WIDTH-1:0] SENTINEL  = 32'h5151_A5A5;

    integer rc_test;
    integer log_fd;
    integer cfg_step;
    integer wait_n;

    reg pmp_seen, iopmp_ready_seen, secure_seen, commit_seen;

    assign sys_secure_ready = pmp_ready && iopmp_enable && rule0_valid && interconnect_reset_n;

    typedef enum logic [4:0] {
        ST_BOOT,
        ST_UP_IC,
        ST_UP_SEC_IOPMP,
        ST_UP_DMA,
        ST_UP_CPU,
        ST_SEED,
        ST_WAIT_PMP,
        ST_CFG0, ST_CFG1, ST_CFG2, ST_CFG3,
        ST_EARLY_DMA_ISSUE,
        ST_EARLY_DMA_WAIT,
        ST_CPU_HOLD_RESET,
        ST_PARTIAL_IOPMP_RST,
        ST_PARTIAL_IOPMP_REL,
        ST_GO,
        ST_POST_DMA_ISSUE,
        ST_POST_DMA_WAIT,
        ST_FINISH,
        ST_IDLE
    } st_t;

    st_t st;

    initial begin
        rc_test = 1;
        void'($value$plusargs("RC_TEST=%d", rc_test));
        log_fd = $fopen("m7_realcore_reset_harness.log", "w");
        $fwrite(log_fd, "RC_TEST=%0d\n", rc_test);
    end
    final $fclose(log_fd);

    task automatic arm_dma(input [7:0] rid, input [`DATA_WIDTH-1:0] data);
        begin
            dma_dst_addr <= PROT_WORD;
            dma_src_addr <= 32'h0;
            dma_length <= 16'd4;
            dma_mode <= 2'd1;
            dma_wdata <= data;
            dma_requester_id <= rid;
            dma_start <= 1'b1;
            stamp_dma_req <= cycle_o;
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= ST_BOOT;
            cycle_o <= 0;
            cpu_reset_n <= 0;
            dma_reset_n <= 0;
            iopmp_reset_n <= 0;
            security_config_reset_n <= 0;
            interconnect_reset_n <= 0;
            protected_memory_reset_n <= 1'b1;
            cfg_write <= 0;
            dma_start <= 0;
            init_req <= 0;
            init_write <= 0;
            init_addr <= PROT_WORD;
            init_wdata <= SENTINEL;
            harness_go_set <= 0;
            harness_result <= 0;
            harness_dma_cycle <= 0;
            harness_cpu_cycle <= 0;
            stamp_cpu_release <= 0;
            stamp_dma_release <= 0;
            stamp_iopmp_release <= 0;
            stamp_sec_release <= 0;
            stamp_ic_release <= 0;
            stamp_pmp_ready <= 0;
            stamp_iopmp_ready <= 0;
            stamp_secure_ready <= 0;
            stamp_dma_req <= 0;
            stamp_mem_commit <= 0;
            pmp_seen <= 0;
            iopmp_ready_seen <= 0;
            secure_seen <= 0;
            commit_seen <= 0;
            test_finished <= 0;
            cfg_step <= 0;
            wait_n <= 0;
        end else begin
            cycle_o <= cycle_o + 1;
            cfg_write <= 0;
            dma_start <= 0;
            init_req <= 0;
            harness_go_set <= 0;

            if (pmp_ready && !pmp_seen) begin pmp_seen <= 1; stamp_pmp_ready <= cycle_o; end
            if (iopmp_enable && rule0_valid && !iopmp_ready_seen) begin
                iopmp_ready_seen <= 1; stamp_iopmp_ready <= cycle_o;
            end
            if (sys_secure_ready && !secure_seen) begin
                secure_seen <= 1; stamp_secure_ready <= cycle_o;
            end
            if (prot_mem_changed && !commit_seen) begin
                commit_seen <= 1; stamp_mem_commit <= cycle_o;
            end

            unique case (st)
                ST_BOOT: st <= ST_UP_IC;

                ST_UP_IC: begin
                    interconnect_reset_n <= 1;
                    stamp_ic_release <= cycle_o;
                    // Release CPU with interconnect for recovery / partial-reset tests.
                    // Holding Ibex in reset long after the boot bus is live
                    // then releasing mid-sim causes a spurious early exception
                    // (observed Phase C). Early-DMA tests keep CPU held.
                    // RC-09 releases here, then re-asserts cpu_reset_n after cfg.
                    if (!(rc_test == 1 || rc_test == 2 || rc_test == 3)) begin
                        cpu_reset_n <= 1;
                        stamp_cpu_release <= cycle_o;
                    end
                    st <= ST_UP_SEC_IOPMP;
                end

                ST_UP_SEC_IOPMP: begin
                    security_config_reset_n <= 1;
                    iopmp_reset_n <= 1;
                    stamp_sec_release <= cycle_o;
                    stamp_iopmp_release <= cycle_o;
                    st <= ST_UP_DMA;
                end

                ST_UP_DMA: begin
                    dma_reset_n <= 1;
                    stamp_dma_release <= cycle_o;
                    // Keep CPU held until after MEM-RET sentinel seed.
                    st <= ST_SEED;
                end

                ST_UP_CPU: begin
                    cpu_reset_n <= 1;
                    stamp_cpu_release <= cycle_o;
                    if (rc_test == 1 || rc_test == 2 || rc_test == 3)
                        st <= ST_EARLY_DMA_ISSUE;
                    else
                        st <= ST_WAIT_PMP;
                    wait_n <= 0;
                end

                ST_SEED: begin
                    init_req <= 1;
                    init_write <= 1;
                    init_addr <= PROT_WORD;
                    init_wdata <= SENTINEL;
                    if (init_valid) begin
                        commit_seen <= 0;
                        stamp_mem_commit <= 0;
                        if (rc_test == 1 || rc_test == 2 || rc_test == 3)
                            st <= ST_EARLY_DMA_ISSUE; // CPU stays held
                        else
                            // Recovery / RC-09 / partial-reset: CPU already released with IC.
                            st <= ST_WAIT_PMP;
                        wait_n <= 0;
                    end
                end

                ST_WAIT_PMP: begin
                    wait_n <= wait_n + 1;
                    if (pmp_ready) begin
                        harness_cpu_cycle <= cycle_o;
                        st <= ST_CFG0;
                    end else if (wait_n > 20000) begin
                        $fwrite(log_fd, "TIMEOUT_WAIT_PMP cycle=%0d\n", cycle_o);
                        $fflush(log_fd);
                        harness_result <= 32'hDEAD00A1;
                        st <= ST_FINISH;
                        test_finished <= 1;
                        $display("M7-RC-TIMEOUT-PMP");
                        $finish;
                    end
                end

                ST_CFG0: begin
                    cfg_write <= 1; cfg_addr <= `ADDR_SEC_CFG_BASE + 32'h4; cfg_wdata <= 32'h1;
                    st <= ST_CFG1;
                end
                ST_CFG1: begin
                    cfg_write <= 1; cfg_addr <= `ADDR_SEC_CFG_BASE + 32'h100;
                    cfg_wdata <= `ADDR_PROTECT_SRAM_BASE; st <= ST_CFG2;
                end
                ST_CFG2: begin
                    cfg_write <= 1; cfg_addr <= `ADDR_SEC_CFG_BASE + 32'h104;
                    cfg_wdata <= `ADDR_PROTECT_SRAM_LIMIT; st <= ST_CFG3;
                end
                ST_CFG3: begin
                    cfg_write <= 1; cfg_addr <= `ADDR_SEC_CFG_BASE + 32'h108;
                    cfg_wdata <= 32'h0000_0701;
                    if (rc_test == 3) begin
                        // Post-config authorized retry
                        st <= ST_POST_DMA_ISSUE;
                        wait_n <= 0;
                        // force auth rid/data in POST for test 3
                    end else if (rc_test == 9) st <= ST_CPU_HOLD_RESET;
                    else if (rc_test == 10 || rc_test == 11) st <= ST_PARTIAL_IOPMP_RST;
                    else if (rc_test == 4 || rc_test == 5 || rc_test == 6) st <= ST_GO;
                    else if (rc_test == 7 || rc_test == 8 || rc_test == 12) begin
                        harness_go_set <= 1;
                        st <= ST_POST_DMA_ISSUE;
                        wait_n <= 0;
                    end else if (rc_test >= 20 && rc_test <= 25) begin
                        harness_go_set <= 1;
                        st <= ST_POST_DMA_ISSUE;
                        wait_n <= 0;
                    end else st <= ST_FINISH;
                end

                ST_EARLY_DMA_ISSUE: begin
                    wait_n <= wait_n + 1;
                    if (wait_n >= 3) begin
                        if (rc_test == 3)
                            arm_dma(8'h01, 32'hA11D_00C3);
                        else
                            arm_dma(8'h02, 32'hDADA_0001);
                        st <= ST_EARLY_DMA_WAIT;
                    end
                end

                ST_EARLY_DMA_WAIT: begin
                    if (dma_done) begin
                        harness_dma_cycle <= cycle_o;
                        harness_result <= dma_error ? 32'hDEAD0001 : 32'h600D0001;
                        $fwrite(log_fd,
                            "PHASE=EARLY ERR=%0d PEEK=0x%08x SECURE=%0d EN=%0d RULEV=%0d\n",
                            dma_error, prot_mem_word0, sys_secure_ready, iopmp_enable, rule0_valid);
                        if (rc_test == 3) begin
                            // Configure IOPMP then retry authorized DMA (no CPU required).
                            st <= ST_CFG0;
                        end else st <= ST_FINISH;
                    end
                end

                ST_CPU_HOLD_RESET: begin
                    cpu_reset_n <= 0;
                    wait_n <= 0;
                    st <= ST_POST_DMA_ISSUE;
                end

                ST_PARTIAL_IOPMP_RST: begin
                    iopmp_reset_n <= 0;
                    security_config_reset_n <= 0;
                    // clear ready tracking for new epoch
                    iopmp_ready_seen <= 0;
                    secure_seen <= 0;
                    st <= ST_PARTIAL_IOPMP_REL;
                    wait_n <= 0;
                end

                ST_PARTIAL_IOPMP_REL: begin
                    wait_n <= wait_n + 1;
                    if (wait_n == 2) begin
                        iopmp_reset_n <= 1;
                        security_config_reset_n <= 1;
                        stamp_iopmp_release <= cycle_o;
                        stamp_sec_release <= cycle_o;
                    end
                    if (wait_n >= 5) begin
                        arm_dma(8'h02, 32'hDADA_00AA);
                        st <= ST_EARLY_DMA_WAIT;
                    end
                end

                ST_GO: begin
                    harness_go_set <= 1;
                    harness_result <= 32'h600D00FF;
                    st <= ST_FINISH;
                end

                ST_POST_DMA_ISSUE: begin
                    wait_n <= wait_n + 1;
                    if (wait_n >= 2) begin
                        if (rc_test == 3)
                            arm_dma(8'h01, 32'hA11D_00C3);
                        else if (rc_test == 7 || rc_test == 12)
                            arm_dma(8'h01, 32'hD00D_00C7);
                        else if (rc_test == 8 || rc_test == 9)
                            arm_dma(8'h02, 32'hDADA_0008);
                        else
                            arm_dma(8'h01, 32'hA11D_00C7);
                        st <= ST_POST_DMA_WAIT;
                    end
                end

                ST_POST_DMA_WAIT: begin
                    if (dma_done) begin
                        harness_dma_cycle <= cycle_o;
                        harness_result <= dma_error ? 32'hDEAD0001 : 32'h600D0001;
                        $fwrite(log_fd,
                            "PHASE=POST ERR=%0d PEEK=0x%08x SECURE=%0d\n",
                            dma_error, prot_mem_word0, sys_secure_ready);
                        st <= ST_FINISH;
                    end
                end

                ST_FINISH: begin
                    $fwrite(log_fd,
                        "DONE PEEK=0x%08x CPU_REL=%0d DMA_REL=%0d IOPMP_REL=%0d PMP_RDY=%0d IOPMP_RDY=%0d SECURE=%0d DMA_REQ=%0d COMMIT=%0d RESULT=0x%08x\n",
                        prot_mem_word0, stamp_cpu_release, stamp_dma_release,
                        stamp_iopmp_release, stamp_pmp_ready, stamp_iopmp_ready,
                        stamp_secure_ready, stamp_dma_req, stamp_mem_commit, harness_result);
                    // Harness-only tests finish here; CPU-driven tests rely on sim_halt.
                    if (rc_test == 1 || rc_test == 2 || rc_test == 3 ||
                        rc_test == 9 || rc_test == 10 || rc_test == 11) begin
                        test_finished <= 1;
                        $display("M7-RC-HARNESS-FINISH");
                        $finish;
                    end
                    // RC-03 also harness-finished after post DMA
                    if (rc_test == 3) begin
                        // already covered above
                    end
                    st <= ST_IDLE;
                end

                ST_IDLE: ;

                default: st <= ST_BOOT;
            endcase
        end
    end

endmodule
