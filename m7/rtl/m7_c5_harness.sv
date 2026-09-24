// Phase C.5 harness: independent domain release schedules + IF/ORD scenarios.
// Ibex constraint: CPU+IC must leave reset near cycle 1 for a healthy core.
// ORD uses a second reset epoch after boot/PMP so REL_* are true independent releases.
`include "bus_pkg.vh"
`include "m7_composed_map.vh"

module m7_c5_harness (
    input  wire                     clk,
    input  wire                     rst_n,
    output reg                      cpu_reset_n,
    output reg                      dma_reset_n,
    output reg                      iopmp_reset_n,
    output reg                      security_config_reset_n,
    output reg                      interconnect_reset_n,
    output reg                      protected_memory_reset_n,
    output reg [7:0]                target_delay_cycles,
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
    input  wire                     iopmp_txn_valid,
    input  wire                     iopmp_txn_auth,
    input  wire                     delay_busy,
    input  wire                     delay_accepted,
    input  wire                     cpu_adapt_req,
    input  wire [`ADDR_WIDTH-1:0]   cpu_adapt_addr,
    input  wire                     cpu_adapt_write,
    output reg                      harness_go_set,
    output reg  [31:0]              harness_result,
    output reg  [31:0]              cycle_o,
    output wire                     sys_secure_ready,
    output reg                      test_finished,
    output reg  [31:0]              stamp_cpu_rel,
    output reg  [31:0]              stamp_dma_rel,
    output reg  [31:0]              stamp_iopmp_rel,
    output reg  [31:0]              stamp_sec_rel,
    output reg  [31:0]              stamp_ic_rel,
    output reg  [31:0]              stamp_pmp_ready,
    output reg  [31:0]              stamp_iopmp_ready,
    output reg  [31:0]              stamp_secure_ready,
    output reg  [31:0]              stamp_dma_req,
    output reg  [31:0]              stamp_dma_admit,
    output reg  [31:0]              stamp_dma_commit,
    output reg  [31:0]              stamp_dma_done,
    output reg  [31:0]              stamp_reset_pulse,
    output reg  [31:0]              stamp_cpu_reset_assert
);

    localparam [`ADDR_WIDTH-1:0] PROT_WORD   = `M7_PROTECT_SRAM_BASE + `M7_PROTECT_TEST_OFF;
    localparam [`ADDR_WIDTH-1:0] PROT_WORD_B = `M7_PROTECT_SRAM_BASE + 32'h200;
    localparam [`DATA_WIDTH-1:0] SENTINEL    = 32'h5151_A5A5;

    integer c5_test;
    integer rel_cpu, rel_dma, rel_iopmp, rel_sec, rel_ic;
    integer delay_n;
    integer dma_n;
    integer thru_left;
    integer thru_first_req;
    integer thru_last_done;
    integer log_fd;
    integer wait_n;
    integer tight_driver; // 0=original re-arm (wait_n>=3); 1=earliest legal (wait_n>=1)
    integer epoch_base;

    reg pmp_seen, iopmp_ready_seen, secure_seen;
    reg admit_seen, commit_seen;
    reg force_hold_cpu;
    reg in_epoch;
    reg epoch_done;
    reg boot_cpu_ic_done;
    reg seed_pending;
    reg seed_saw_commit;
    reg seed_issued;

    wire cpu_prot_req = cpu_adapt_req && cpu_adapt_write &&
                        (cpu_adapt_addr == PROT_WORD);

    assign sys_secure_ready = pmp_ready && iopmp_enable && rule0_valid && interconnect_reset_n;

    typedef enum logic [5:0] {
        ST_BOOT,
        ST_WAIT_REL,
        ST_SEED,
        ST_SEED_WAIT,
        ST_WAIT_PMP,
        ST_CFG0, ST_CFG1, ST_CFG2, ST_CFG3,
        ST_IF_ARM,
        ST_IF_WAIT_ADMIT,
        ST_IF_PULSE_RST,
        ST_IF_WAIT_OUTCOME,
        ST_IF03_GATE,
        ST_ORD_EPOCH_ASSERT,
        ST_ORD_EPOCH_REL,
        ST_ORD_EARLY_DMA,
        ST_ORD_WAIT_EARLY,
        ST_ORD_WAIT_SECURE,
        ST_ORD_POST_UNAUTH,
        ST_ORD_WAIT_UNAUTH,
        ST_ORD_POST_AUTH,
        ST_ORD_WAIT_AUTH,
        ST_ORD_GO_CPU,
        ST_STALE_PRE,
        ST_STALE_WAIT,
        ST_STALE_RST,
        ST_STALE_POST,
        ST_STALE_WAIT2,
        ST_THRU_ARM,
        ST_THRU_WAIT,
        ST_FINISH,
        ST_IDLE
    } st_t;
    st_t st;

    initial begin
        c5_test = 0;
        rel_cpu = 10; rel_dma = 20; rel_iopmp = 12; rel_sec = 12; rel_ic = 8;
        delay_n = 0;
        dma_n = 1;
        tight_driver = 0;
        void'($value$plusargs("C5_TEST=%d", c5_test));
        void'($value$plusargs("REL_CPU=%d", rel_cpu));
        void'($value$plusargs("REL_DMA=%d", rel_dma));
        void'($value$plusargs("REL_IOPMP=%d", rel_iopmp));
        void'($value$plusargs("REL_SEC=%d", rel_sec));
        void'($value$plusargs("REL_IC=%d", rel_ic));
        void'($value$plusargs("TARGET_DELAY=%d", delay_n));
        void'($value$plusargs("DMA_N=%d", dma_n));
        void'($value$plusargs("TIGHT_DRIVER=%d", tight_driver));
        log_fd = $fopen("m7_c5_harness.log", "w");
        $fwrite(log_fd,
            "C5_TEST=%0d REL_CPU=%0d REL_DMA=%0d REL_IOPMP=%0d REL_SEC=%0d REL_IC=%0d DELAY=%0d DMA_N=%0d TIGHT_DRIVER=%0d\n",
            c5_test, rel_cpu, rel_dma, rel_iopmp, rel_sec, rel_ic, delay_n, dma_n, tight_driver);
    end
    final $fclose(log_fd);

    task automatic arm_dma(input [7:0] rid, input [`DATA_WIDTH-1:0] data,
                           input [`ADDR_WIDTH-1:0] addr);
        begin
            dma_dst_addr <= addr;
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
            target_delay_cycles <= 0;
            cfg_write <= 0;
            dma_start <= 0;
            init_req <= 0;
            init_write <= 1;
            init_addr <= PROT_WORD;
            init_wdata <= SENTINEL;
            harness_go_set <= 0;
            harness_result <= 0;
            test_finished <= 0;
            stamp_cpu_rel <= 0;
            stamp_dma_rel <= 0;
            stamp_iopmp_rel <= 0;
            stamp_sec_rel <= 0;
            stamp_ic_rel <= 0;
            stamp_pmp_ready <= 0;
            stamp_iopmp_ready <= 0;
            stamp_secure_ready <= 0;
            stamp_dma_req <= 0;
            stamp_dma_admit <= 0;
            stamp_dma_commit <= 0;
            stamp_dma_done <= 0;
            stamp_reset_pulse <= 0;
            stamp_cpu_reset_assert <= 0;
            pmp_seen <= 0;
            iopmp_ready_seen <= 0;
            secure_seen <= 0;
            admit_seen <= 0;
            commit_seen <= 0;
            wait_n <= 0;
            force_hold_cpu <= 0;
            in_epoch <= 0;
            epoch_done <= 0;
            epoch_base <= 0;
            boot_cpu_ic_done <= 0;
            seed_pending <= 0;
            seed_saw_commit <= 0;
            seed_issued <= 0;
            thru_left <= 0;
            thru_first_req <= 0;
            thru_last_done <= 0;
        end else begin
            cycle_o <= cycle_o + 1;
            cfg_write <= 0;
            dma_start <= 0;
            init_req <= 0;
            harness_go_set <= 0;
            target_delay_cycles <= delay_n[7:0];

            if (prot_mem_changed && seed_pending)
                seed_saw_commit <= 1;
            if (pmp_ready && !pmp_seen) begin pmp_seen <= 1; stamp_pmp_ready <= cycle_o; end
            if (iopmp_enable && rule0_valid && !iopmp_ready_seen) begin
                iopmp_ready_seen <= 1; stamp_iopmp_ready <= cycle_o;
            end
            if (sys_secure_ready && !secure_seen) begin
                secure_seen <= 1; stamp_secure_ready <= cycle_o;
            end
            if (iopmp_txn_valid && iopmp_txn_auth && !admit_seen) begin
                admit_seen <= 1; stamp_dma_admit <= cycle_o;
            end
            // CPU commit landmark (IF02): first prot change after go/admit window
            if (prot_mem_changed && !commit_seen && (admit_seen || (c5_test >= 110 && c5_test <= 112))) begin
                if (prot_mem_word0 != SENTINEL || admit_seen)
                    ; // stamp below using changed path — harness sees prot_mem_word0 after change
                commit_seen <= 1;
                stamp_dma_commit <= cycle_o;
            end

            // ---- Domain release ----
            // Boot assist (non-epoch): Ibex needs CPU+IC at cycle 1.
            if (!in_epoch) begin
                if (cycle_o == 1) begin
                    interconnect_reset_n <= 1;
                    if (!stamp_ic_rel) stamp_ic_rel <= cycle_o;
                    if (!force_hold_cpu) begin
                        cpu_reset_n <= 1;
                        if (!stamp_cpu_rel) stamp_cpu_rel <= cycle_o;
                    end
                    boot_cpu_ic_done <= 1;
                end
                if (cycle_o == 2) begin
                    // For IF/STALE (non-ORD): bring remaining domains up immediately.
                    // For ORD: also bring them up for first boot/PMP; epoch re-holds later.
                    dma_reset_n <= 1;
                    iopmp_reset_n <= 1;
                    security_config_reset_n <= 1;
                    if (!stamp_dma_rel) stamp_dma_rel <= cycle_o;
                    if (!stamp_iopmp_rel) stamp_iopmp_rel <= cycle_o;
                    if (!stamp_sec_rel) stamp_sec_rel <= cycle_o;
                end
            end else if (!epoch_done) begin
                // Second reset epoch: independent REL_* offsets from epoch_base
                if ((cycle_o == epoch_base + rel_ic) && !interconnect_reset_n) begin
                    interconnect_reset_n <= 1; stamp_ic_rel <= cycle_o;
                end
                if ((cycle_o == epoch_base + rel_sec) && !security_config_reset_n) begin
                    security_config_reset_n <= 1; stamp_sec_rel <= cycle_o;
                end
                if ((cycle_o == epoch_base + rel_iopmp) && !iopmp_reset_n) begin
                    iopmp_reset_n <= 1; stamp_iopmp_rel <= cycle_o;
                end
                if ((cycle_o == epoch_base + rel_dma) && !dma_reset_n) begin
                    dma_reset_n <= 1; stamp_dma_rel <= cycle_o;
                end
                if ((cycle_o == epoch_base + rel_cpu) && !cpu_reset_n) begin
                    cpu_reset_n <= 1; stamp_cpu_rel <= cycle_o;
                end
            end

            unique case (st)
                ST_BOOT: begin
                    force_hold_cpu <= (c5_test >= 101 && c5_test <= 104) || (c5_test == 121) || (c5_test == 900);
                    st <= ST_WAIT_REL;
                end

                ST_WAIT_REL: begin
                    if (cycle_o > 3) begin
                        st <= ST_SEED;
                        wait_n <= 0;
                    end
                end

                ST_SEED: begin
                    init_write <= 1;
                    init_addr <= PROT_WORD;
                    init_wdata <= SENTINEL;
                    seed_pending <= 1;
                    // Hold req until grant (gnt is registered through delay/arbiter).
                    if (!seed_issued || !init_gnt) begin
                        init_req <= 1;
                    end
                    if (init_gnt) begin
                        seed_issued <= 1;
                        seed_saw_commit <= 0;
                        st <= ST_SEED_WAIT;
                        wait_n <= 0;
                    end else if (wait_n > 2000) begin
                        $fwrite(log_fd, "SEED_TIMEOUT\n");
                        st <= ST_FINISH;
                    end else
                        wait_n <= wait_n + 1;
                end

                ST_SEED_WAIT: begin
                    // Do not keep init_req high (would re-enter delay after first fire).
                    wait_n <= wait_n + 1;
                    if (seed_saw_commit || prot_mem_changed || wait_n > 5000) begin
                        seed_pending <= 0;
                        commit_seen <= 0;
                        stamp_dma_commit <= 0;
                        admit_seen <= 0;
                        wait_n <= 0;
                        if (c5_test >= 101 && c5_test <= 104)
                            st <= ST_CFG0;
                        else if (c5_test >= 120 && c5_test <= 123)
                            st <= ST_IF03_GATE;
                        else if (c5_test >= 200 && c5_test <= 207)
                            st <= ST_WAIT_PMP;
                        else if (c5_test == 300)
                            st <= ST_CFG0;
                        else if (c5_test == 900)
                            st <= ST_CFG0;
                        else if (force_hold_cpu)
                            st <= ST_CFG0;
                        else
                            st <= ST_WAIT_PMP;
                    end
                end

                ST_WAIT_PMP: begin
                    wait_n <= wait_n + 1;
                    if (pmp_ready) begin
                        wait_n <= 0;
                        if (c5_test >= 200 && c5_test <= 207)
                            st <= ST_ORD_EPOCH_ASSERT;
                        else
                            st <= ST_CFG0;
                    end else if (wait_n > 30000) begin
                        $fwrite(log_fd, "TIMEOUT_PMP\n");
                        harness_result <= 32'hDEAD00A1;
                        st <= ST_FINISH;
                    end
                end

                ST_ORD_EPOCH_ASSERT: begin
                    // True independent release-order epoch (MEM-RET preserved).
                    cpu_reset_n <= 0;
                    dma_reset_n <= 0;
                    iopmp_reset_n <= 0;
                    security_config_reset_n <= 0;
                    interconnect_reset_n <= 0;
                    in_epoch <= 1;
                    epoch_done <= 0;
                    iopmp_ready_seen <= 0;
                    secure_seen <= 0;
                    stamp_cpu_rel <= 0;
                    stamp_dma_rel <= 0;
                    stamp_iopmp_rel <= 0;
                    stamp_sec_rel <= 0;
                    stamp_ic_rel <= 0;
                    stamp_iopmp_ready <= 0;
                    stamp_secure_ready <= 0;
                    admit_seen <= 0;
                    commit_seen <= 0;
                    wait_n <= wait_n + 1;
                    if (wait_n >= 4) begin
                        epoch_base <= cycle_o + 1;
                        wait_n <= 0;
                        st <= ST_ORD_EPOCH_REL;
                        $fwrite(log_fd, "ORD_EPOCH_BASE=%0d\n", cycle_o + 1);
                    end
                end

                ST_ORD_EPOCH_REL: begin
                    // Wait until all five domains released per schedule
                    if (cpu_reset_n && dma_reset_n && iopmp_reset_n &&
                        security_config_reset_n && interconnect_reset_n) begin
                        epoch_done <= 1;
                        wait_n <= 0;
                        st <= ST_ORD_EARLY_DMA;
                    end else if (wait_n > 50000) begin
                        $fwrite(log_fd, "ORD_EPOCH_TIMEOUT\n");
                        st <= ST_FINISH;
                    end
                    wait_n <= wait_n + 1;
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
                    cfg_wdata <= 32'h0000_0701; // RID=1 R+W
                    wait_n <= 0;
                    if (c5_test >= 101 && c5_test <= 104)
                        st <= ST_IF_ARM;
                    else if (c5_test >= 110 && c5_test <= 112)
                        st <= ST_IF_ARM;
                    else if (c5_test >= 120 && c5_test <= 123)
                        st <= ST_IF03_GATE;
                    else if (c5_test == 300)
                        st <= ST_STALE_PRE;
                    else if (c5_test >= 200 && c5_test <= 207)
                        st <= ST_ORD_WAIT_SECURE;
                    else if (c5_test == 900)
                        st <= ST_THRU_ARM;
                    else
                        st <= ST_FINISH;
                end

                ST_IF_ARM: begin
                    wait_n <= wait_n + 1;
                    if (wait_n >= 2) begin
                        admit_seen <= 0;
                        commit_seen <= 0;
                        if (c5_test >= 110 && c5_test <= 112) begin
                            harness_go_set <= 1;
                            st <= ST_IF_WAIT_ADMIT;
                        end else begin
                            arm_dma(8'h01, 32'h1111_1111, PROT_WORD);
                            st <= ST_IF_WAIT_ADMIT;
                        end
                        wait_n <= 0;
                    end
                end

                ST_IF_WAIT_ADMIT: begin
                    wait_n <= wait_n + 1;
                    if (c5_test == 101) begin
                        if (stamp_dma_req != 0 && !admit_seen && wait_n >= 1) begin
                            dma_reset_n <= 0;
                            stamp_reset_pulse <= cycle_o;
                            st <= ST_IF_PULSE_RST;
                            wait_n <= 0;
                        end
                    end else if (c5_test == 102) begin
                        if (admit_seen) begin
                            dma_reset_n <= 0;
                            stamp_reset_pulse <= cycle_o;
                            st <= ST_IF_PULSE_RST;
                            wait_n <= 0;
                        end
                    end else if (c5_test == 103) begin
                        if (admit_seen && delay_busy && !commit_seen) begin
                            dma_reset_n <= 0;
                            stamp_reset_pulse <= cycle_o;
                            st <= ST_IF_PULSE_RST;
                            wait_n <= 0;
                        end else if (admit_seen && delay_n == 0 && !commit_seen && wait_n > 0) begin
                            dma_reset_n <= 0;
                            stamp_reset_pulse <= cycle_o;
                            st <= ST_IF_PULSE_RST;
                            wait_n <= 0;
                        end
                    end else if (c5_test == 104) begin
                        if (admit_seen && !commit_seen) begin
                            iopmp_reset_n <= 0;
                            security_config_reset_n <= 0;
                            stamp_reset_pulse <= cycle_o;
                            st <= ST_IF_PULSE_RST;
                            wait_n <= 0;
                        end
                    end else if (c5_test == 110) begin
                        // After CPU prot request visible, before grant/delay accept
                        if (cpu_prot_req && !delay_busy && !commit_seen) begin
                            cpu_reset_n <= 0;
                            stamp_cpu_reset_assert <= cycle_o;
                            stamp_reset_pulse <= cycle_o;
                            st <= ST_IF_PULSE_RST;
                            wait_n <= 0;
                        end else if (wait_n > 4000) begin
                            $fwrite(log_fd, "IF02_UNREACHABLE\n");
                            harness_result <= 32'hDEAD00F2;
                            st <= ST_FINISH;
                        end
                    end else if (c5_test == 111) begin
                        if ((delay_busy || delay_accepted) && !commit_seen) begin
                            cpu_reset_n <= 0;
                            stamp_cpu_reset_assert <= cycle_o;
                            stamp_reset_pulse <= cycle_o;
                            st <= ST_IF_PULSE_RST;
                            wait_n <= 0;
                        end else if (wait_n > 4000) begin
                            $fwrite(log_fd, "IF02_UNREACHABLE\n");
                            harness_result <= 32'hDEAD00F2;
                            st <= ST_FINISH;
                        end
                    end else if (c5_test == 112) begin
                        if (commit_seen && wait_n >= 1) begin
                            cpu_reset_n <= 0;
                            stamp_cpu_reset_assert <= cycle_o;
                            stamp_reset_pulse <= cycle_o;
                            st <= ST_IF_PULSE_RST;
                            wait_n <= 0;
                        end else if (wait_n > 4000) begin
                            $fwrite(log_fd, "IF02C_UNREACHABLE\n");
                            harness_result <= 32'hDEAD00F2;
                            st <= ST_FINISH;
                        end
                    end
                    if (wait_n > 5000 && c5_test <= 104) begin
                        $fwrite(log_fd, "IF01_TIMEOUT_ADMIT delay_busy=%0d admit=%0d\n",
                            delay_busy, admit_seen);
                        st <= ST_IF_WAIT_OUTCOME;
                    end
                end

                ST_IF_PULSE_RST: begin
                    wait_n <= wait_n + 1;
                    if (wait_n == 2) begin
                        if (c5_test == 104) begin
                            iopmp_reset_n <= 1;
                            security_config_reset_n <= 1;
                        end else if (c5_test >= 110 && c5_test <= 112) begin
                            cpu_reset_n <= 0;
                        end else begin
                            dma_reset_n <= 0;
                        end
                    end
                    if (wait_n == 6) begin
                        if (c5_test >= 110 && c5_test <= 112) begin
                            // Keep CPU held after IF02 pulse so reboot does not
                            // issue a second store that confounds commit counting.
                            cpu_reset_n <= 0;
                        end else if (c5_test <= 103) begin
                            // Keep DMA held after IF01 pulse — releasing mid-drain
                            // can cause a second request/commit.
                            dma_reset_n <= 0;
                        end
                        st <= ST_IF_WAIT_OUTCOME;
                        wait_n <= 0;
                    end
                end

                ST_IF_WAIT_OUTCOME: begin
                    wait_n <= wait_n + 1;
                    if (dma_done) stamp_dma_done <= cycle_o;
                    if (wait_n > 40) begin
                        harness_result <= commit_seen ? 32'h600D00C1 : 32'h600D0000;
                        $fwrite(log_fd,
                            "IF_OUTCOME PEEK=0x%08x ADMIT=%0d COMMIT=%0d RST=%0d REQ=%0d DONE=%0d ERR=%0d\n",
                            prot_mem_word0, stamp_dma_admit, stamp_dma_commit, stamp_reset_pulse,
                            stamp_dma_req, stamp_dma_done, dma_error);
                        if (c5_test == 123)
                            $fwrite(log_fd, "EARLY ERR=%0d PEEK=0x%08x REASON=SEC_RESET_NO_DMA_ISSUE\n",
                                dma_error, prot_mem_word0);
                        st <= ST_FINISH;
                    end
                end

                ST_IF03_GATE: begin
                    wait_n <= wait_n + 1;
                    if (c5_test == 120) begin
                        if (pmp_ready || wait_n > 20000) begin
                            arm_dma(8'h02, 32'hDADA_0120, PROT_WORD);
                            st <= ST_ORD_WAIT_EARLY;
                            wait_n <= 0;
                        end
                    end else if (c5_test == 121) begin
                        if (iopmp_enable && rule0_valid) begin
                            arm_dma(8'h02, 32'hDADA_0121, PROT_WORD);
                            st <= ST_ORD_WAIT_EARLY;
                            wait_n <= 0;
                        end else if (wait_n == 2) begin
                            st <= ST_CFG0;
                        end
                    end else if (c5_test == 122) begin
                        if (pmp_ready && iopmp_enable && rule0_valid) begin
                            interconnect_reset_n <= 0;
                            wait_n <= 0;
                            st <= ST_ORD_EARLY_DMA;
                        end else if (wait_n == 1 && !(iopmp_enable && rule0_valid))
                            st <= ST_CFG0;
                        else if (wait_n > 30000) st <= ST_FINISH;
                    end else if (c5_test == 123) begin
                        if (pmp_ready) begin
                            security_config_reset_n <= 0;
                            stamp_reset_pulse <= cycle_o;
                            wait_n <= 0;
                            st <= ST_IF_PULSE_RST;
                        end else if (wait_n > 30000) st <= ST_FINISH;
                    end
                end

                ST_ORD_EARLY_DMA: begin
                    wait_n <= wait_n + 1;
                    // Earliest domain-legal: DMA + interconnect up (IOPMP may be fail-open/closed)
                    if (dma_reset_n && interconnect_reset_n && wait_n >= 2) begin
                        arm_dma(8'h02, 32'hDADA_00EE, PROT_WORD);
                        st <= ST_ORD_WAIT_EARLY;
                        wait_n <= 0;
                    end else if (wait_n > 20000) begin
                        $fwrite(log_fd, "EARLY_ISSUE_TIMEOUT\n");
                        $fwrite(log_fd, "EARLY ERR=NOT_ISSUED PEEK=0x%08x REASON=IC_DOWN\n",
                            prot_mem_word0);
                        st <= ST_FINISH;
                    end
                end

                ST_ORD_WAIT_EARLY: begin
                    if (dma_done) begin
                        $fwrite(log_fd, "EARLY ERR=%0d PEEK=0x%08x SECURE=%0d EN=%0d RULEV=%0d\n",
                            dma_error, prot_mem_word0, sys_secure_ready, iopmp_enable, rule0_valid);
                        harness_result <= dma_error ? 32'hDEAD0001 : 32'h600D0001;
                        if (c5_test == 122) interconnect_reset_n <= 1;
                        if (c5_test >= 120 && c5_test <= 123)
                            st <= ST_FINISH;
                        else
                            st <= ST_CFG0;
                        wait_n <= 0;
                    end
                end

                ST_ORD_WAIT_SECURE: begin
                    wait_n <= wait_n + 1;
                    // After epoch CPU reboot, wait for PMP again then secure_ready
                    if (sys_secure_ready || wait_n > 40000) begin
                        st <= ST_ORD_POST_UNAUTH;
                        wait_n <= 0;
                    end
                end

                ST_ORD_POST_UNAUTH: begin
                    wait_n <= wait_n + 1;
                    if (wait_n >= 2) begin
                        arm_dma(8'h02, 32'hDADA_00FF, PROT_WORD);
                        st <= ST_ORD_WAIT_UNAUTH;
                        wait_n <= 0;
                    end
                end

                ST_ORD_WAIT_UNAUTH: begin
                    if (dma_done) begin
                        $fwrite(log_fd, "POST_UNAUTH ERR=%0d PEEK=0x%08x\n", dma_error, prot_mem_word0);
                        st <= ST_ORD_POST_AUTH;
                        wait_n <= 0;
                    end
                end

                ST_ORD_POST_AUTH: begin
                    wait_n <= wait_n + 1;
                    if (wait_n >= 2) begin
                        arm_dma(8'h01, 32'hA11D_00C5, PROT_WORD);
                        st <= ST_ORD_WAIT_AUTH;
                        wait_n <= 0;
                    end
                end

                ST_ORD_WAIT_AUTH: begin
                    if (dma_done) begin
                        $fwrite(log_fd, "POST_AUTH ERR=%0d PEEK=0x%08x\n", dma_error, prot_mem_word0);
                        $fwrite(log_fd,
                            "DONE PEEK=0x%08x CPU=%0d DMA=%0d IOPMP=%0d SEC=%0d IC=%0d PMP=%0d IRDY=%0d SECURE=%0d REQ=%0d ADMIT=%0d COMMIT=%0d RST=%0d RES=0x%08x EPOCH=%0d\n",
                            prot_mem_word0, stamp_cpu_rel, stamp_dma_rel, stamp_iopmp_rel, stamp_sec_rel,
                            stamp_ic_rel, stamp_pmp_ready, stamp_iopmp_ready, stamp_secure_ready,
                            stamp_dma_req, stamp_dma_admit, stamp_dma_commit, stamp_reset_pulse, harness_result,
                            epoch_base);
                        $fflush(log_fd);
                        harness_go_set <= 1;
                        st <= ST_ORD_GO_CPU;
                        wait_n <= 0;
                    end
                end

                ST_ORD_GO_CPU: begin
                    wait_n <= wait_n + 1;
                    // Firmware may $finish via sim_halt after U-fault; keep a bound.
                    if (wait_n > 25000) begin
                        st <= ST_FINISH;
                    end
                end

                ST_STALE_PRE: begin
                    wait_n <= wait_n + 1;
                    if (wait_n >= 2) begin
                        arm_dma(8'h01, 32'h1111_1111, PROT_WORD);
                        st <= ST_STALE_WAIT;
                        wait_n <= 0;
                    end
                end

                ST_STALE_WAIT: begin
                    if (admit_seen && (delay_busy || delay_n == 0)) begin
                        iopmp_reset_n <= 0;
                        dma_reset_n <= 0;
                        stamp_reset_pulse <= cycle_o;
                        st <= ST_STALE_RST;
                        wait_n <= 0;
                    end else if (dma_done) begin
                        st <= ST_STALE_RST;
                        wait_n <= 0;
                    end
                end

                ST_STALE_RST: begin
                    wait_n <= wait_n + 1;
                    if (wait_n == 3) begin
                        iopmp_reset_n <= 1;
                        dma_reset_n <= 1;
                        security_config_reset_n <= 1;
                    end
                    if (wait_n == 8) begin
                        cfg_write <= 1; cfg_addr <= `ADDR_SEC_CFG_BASE + 32'h4; cfg_wdata <= 32'h1;
                    end else if (wait_n == 9) begin
                        cfg_write <= 1; cfg_addr <= `ADDR_SEC_CFG_BASE + 32'h100;
                        cfg_wdata <= `ADDR_PROTECT_SRAM_BASE;
                    end else if (wait_n == 10) begin
                        cfg_write <= 1; cfg_addr <= `ADDR_SEC_CFG_BASE + 32'h104;
                        cfg_wdata <= `ADDR_PROTECT_SRAM_LIMIT;
                    end else if (wait_n == 11) begin
                        cfg_write <= 1; cfg_addr <= `ADDR_SEC_CFG_BASE + 32'h108;
                        cfg_wdata <= 32'h0000_0701; // only RID1 — post uses RID2 → deny if no stale allow
                    end else if (wait_n >= 14) begin
                        st <= ST_STALE_POST;
                        wait_n <= 0;
                    end
                end

                ST_STALE_POST: begin
                    wait_n <= wait_n + 1;
                    if (wait_n >= 2) begin
                        arm_dma(8'h02, 32'h2222_2222, PROT_WORD_B);
                        st <= ST_STALE_WAIT2;
                        wait_n <= 0;
                    end
                end

                ST_STALE_WAIT2: begin
                    if (dma_done) begin
                        $fwrite(log_fd, "STALE_POST ERR=%0d PEEK0=0x%08x\n", dma_error, prot_mem_word0);
                        harness_result <= 32'h600D0300;
                        st <= ST_FINISH;
                    end
                end

                ST_THRU_ARM: begin
                    wait_n <= wait_n + 1;
                    // Initialize transfer count once we have entered ARM.
                    if (wait_n >= 1 && thru_left == 0) begin
                        thru_left <= (dma_n < 1) ? 1 : dma_n;
                        thru_first_req <= 0;
                        thru_last_done <= 0;
                        $fwrite(log_fd, "THRU_BEGIN DMA_N=%0d CYC=%0d\n", dma_n, cycle_o);
                    end
                    // Original: wait_n>=3 before arm (~extra idle after ARM entry).
                    // TIGHT_DRIVER=1: arm at wait_n>=1 (earliest legal in this FSM).
                    if (wait_n >= (tight_driver ? 1 : 3)) begin
                        arm_dma(8'h01, 32'hA11D_00C5, PROT_WORD);
                        if (thru_first_req == 0)
                            thru_first_req <= cycle_o;
                        st <= ST_THRU_WAIT;
                        wait_n <= 0;
                    end
                end

                ST_THRU_WAIT: begin
                    if (dma_done) begin
                        thru_last_done <= cycle_o;
                        thru_left <= thru_left - 1;
                        $fwrite(log_fd, "THRU_XFER ERR=%0d LEFT=%0d CYC=%0d\n",
                                dma_error, thru_left - 1, cycle_o);
                        if (thru_left <= 1) begin
                            $fwrite(log_fd,
                                "THRU_DONE N=%0d FIRST_REQ=%0d LAST_DONE=%0d TOTAL=%0d\n",
                                dma_n, thru_first_req, cycle_o, cycle_o - thru_first_req);
                            harness_result <= 32'h600D0900;
                            st <= ST_FINISH;
                        end else begin
                            st <= ST_THRU_ARM;
                            wait_n <= 0;
                        end
                    end else if (wait_n > 50000) begin
                        $fwrite(log_fd, "THRU_TIMEOUT LEFT=%0d CYC=%0d\n", thru_left, cycle_o);
                        st <= ST_FINISH;
                    end else
                        wait_n <= wait_n + 1;
                end

                ST_FINISH: begin
                    $fwrite(log_fd,
                        "DONE PEEK=0x%08x CPU=%0d DMA=%0d IOPMP=%0d SEC=%0d IC=%0d PMP=%0d IRDY=%0d SECURE=%0d REQ=%0d ADMIT=%0d COMMIT=%0d RST=%0d RES=0x%08x EPOCH=%0d\n",
                        prot_mem_word0, stamp_cpu_rel, stamp_dma_rel, stamp_iopmp_rel, stamp_sec_rel,
                        stamp_ic_rel, stamp_pmp_ready, stamp_iopmp_ready, stamp_secure_ready,
                        stamp_dma_req, stamp_dma_admit, stamp_dma_commit, stamp_reset_pulse, harness_result,
                        epoch_base);
                    $fflush(log_fd);
                    test_finished <= 1;
                    $display("M7-C5-FINISH");
                    $finish;
                end

                ST_IDLE: ;

                default: st <= ST_BOOT;
            endcase
        end
    end

endmodule
