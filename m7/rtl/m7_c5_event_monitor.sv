// Phase C.5 event monitor — simulation-only durable TXN ledger.
// SRAM_WRITE observes the actual protected-SRAM write edge (sram_prot_*),
// NOT mem_changed / PROT_COMMIT (kept as a separate event).
`include "bus_pkg.vh"

module m7_c5_event_monitor (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [31:0]              cycle,
    input  wire                     dma_req,
    input  wire                     dma_gnt_iopmp,
    input  wire                     dma_valid_iopmp,
    input  wire                     dma_error_iopmp,
    input  wire                     iopmp_txn_valid,
    input  wire                     iopmp_txn_auth,
    input  wire [7:0]               iopmp_txn_rid,
    input  wire [`ADDR_WIDTH-1:0]   iopmp_txn_addr,
    input  wire                     iopmp_txn_write,
    input  wire                     iopmp_req_out,
    input  wire [`ADDR_WIDTH-1:0]   iopmp_addr_out,
    input  wire                     iopmp_write_out,
    input  wire [`DATA_WIDTH-1:0]   iopmp_wdata_out,
    input  wire                     arb_dma_gnt,
    input  wire                     arb_dma_valid,
    input  wire [`ADDR_WIDTH-1:0]   dma_addr,
    input  wire [`DATA_WIDTH-1:0]   dma_wdata,
    input  wire                     dma_write,
    input  wire                     cpu_adapt_req,
    input  wire                     cpu_adapt_gnt,
    input  wire                     cpu_adapt_valid,
    input  wire                     cpu_adapt_write,
    input  wire [`ADDR_WIDTH-1:0]   cpu_adapt_addr,
    input  wire [`DATA_WIDTH-1:0]   cpu_adapt_wdata,
    // Full arbiter CPU port (includes harness init writer)
    input  wire                     cpu_ic_req,
    input  wire                     cpu_ic_gnt,
    input  wire                     cpu_ic_write,
    input  wire [`ADDR_WIDTH-1:0]   cpu_ic_addr,
    input  wire [`DATA_WIDTH-1:0]   cpu_ic_wdata,
    input  wire                     cpu_reset_n,
    input  wire                     dma_reset_n,
    input  wire                     iopmp_reset_n,
    input  wire                     security_config_reset_n,
    input  wire                     interconnect_reset_n,
    input  wire                     protected_memory_reset_n,
    // Actual target-side SRAM port (delay → protected SRAM)
    input  wire                     sram_prot_req,
    input  wire                     sram_prot_write,
    input  wire [`ADDR_WIDTH-1:0]   sram_prot_addr,
    input  wire [`DATA_WIDTH-1:0]   sram_prot_wdata,
    // mem_changed observability (NOT used as write definition)
    input  wire                     prot_mem_changed,
    input  wire [`ADDR_WIDTH-1:0]   prot_changed_addr,
    input  wire [`DATA_WIDTH-1:0]   prot_changed_wdata,
    input  wire                     arb_serve_cpu,
    input  wire                     delay_accepted,
    input  wire                     delay_busy,
    input  wire                     pmp_ready,
    input  wire                     iopmp_enable,
    input  wire                     rule0_valid,
    input  wire                     sys_secure_ready
);

    integer fd;
    reg cpu_reset_n_d, dma_reset_n_d, iopmp_reset_n_d, sec_reset_n_d, ic_reset_n_d;
    reg pmp_ready_d, iopmp_ready_d, secure_d;

    localparam int LEDGER_N = 8;
    reg [15:0]              txn_id_next;
    reg [15:0]              led_id        [0:LEDGER_N-1];
    reg                     led_valid     [0:LEDGER_N-1];
    reg                     led_auth      [0:LEDGER_N-1];
    reg                     led_master_cpu[0:LEDGER_N-1]; // 1=CPU, 0=DMA
    reg [`ADDR_WIDTH-1:0]   led_addr      [0:LEDGER_N-1];
    reg [`DATA_WIDTH-1:0]   led_wdata     [0:LEDGER_N-1];
    reg                     led_write     [0:LEDGER_N-1];
    reg [7:0]               led_rid       [0:LEDGER_N-1];
    reg [31:0]              led_admit_cy  [0:LEDGER_N-1];
    reg [31:0]              led_arb_cy    [0:LEDGER_N-1];
    reg [31:0]              led_delay_cy  [0:LEDGER_N-1];
    reg [31:0]              led_write_cy  [0:LEDGER_N-1];
    reg [31:0]              led_done_cy   [0:LEDGER_N-1];
    reg                     led_arb_seen  [0:LEDGER_N-1];
    reg                     led_delay_seen[0:LEDGER_N-1];
    reg [7:0]               led_write_cnt [0:LEDGER_N-1]; // actual SRAM write count
    reg                     led_done      [0:LEDGER_N-1];
    reg                     led_plock     [0:LEDGER_N-1]; // 1=admission payload is authoritative
    reg [2:0]               led_head;
    reg [15:0]              last_dma_admit_id;
    reg                     last_dma_admit_v;
    reg [15:0]              last_cpu_id;
    reg                     last_cpu_v;
    reg [15:0]              last_delay_id;
    reg                     last_delay_v;
    reg                     last_delay_cpu;
    // Snapshot of DMA requester payload sampled while dma_req before/at admit
    reg [`ADDR_WIDTH-1:0]   dma_req_addr_cap;
    reg [`DATA_WIDTH-1:0]   dma_req_wdata_cap;
    reg                     dma_req_write_cap;
    reg                     dma_req_cap_v;

    wire iopmp_ready = iopmp_enable && rule0_valid;
    // Exact SRAM write semantics (rtl/memory/sram.v): posedge write when rst_n && req && write
    wire actual_sram_write = protected_memory_reset_n && sram_prot_req && sram_prot_write;

    integer i;
    // Reset-epoch: a completed CPU ledger row must not absorb a later
    // payload after CPU reset (IF02-A historical DUPLICATE was this bug).
    reg [15:0] cpu_reset_epoch;

    function automatic [15:0] match_open_write;
        input [`ADDR_WIDTH-1:0] a;
        input [`DATA_WIDTH-1:0] d;
        begin
            match_open_write = 16'd0;
            for (i = 0; i < LEDGER_N; i = i + 1) begin
                if (led_valid[i] && led_write[i] && led_write_cnt[i] == 0 &&
                    led_addr[i] == a && led_wdata[i] == d)
                    match_open_write = led_id[i];
            end
            if (match_open_write == 16'd0) begin
                for (i = 0; i < LEDGER_N; i = i + 1)
                    if (led_valid[i] && led_write[i] && led_addr[i] == a && led_wdata[i] == d)
                        match_open_write = led_id[i];
            end
        end
    endfunction

    initial begin
        fd = $fopen("m7_c5_events.log", "w");
        $fwrite(fd, "# C5 event log (independent SRAM write + durable TXN ledger)\n");
        $fwrite(fd, "# SRAM_WRITE := protected_memory_reset_n && sram_prot_req && sram_prot_write\n");
        $fwrite(fd, "# PROT_COMMIT := prot_mem_changed (distinct; not a write proxy)\n");
        $fwrite(fd, "# LEDGER: completed TXN_ID is closed across CPU reset epoch\n");
    end
    final $fclose(fd);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_reset_n_d <= 0; dma_reset_n_d <= 0; iopmp_reset_n_d <= 0;
            sec_reset_n_d <= 0; ic_reset_n_d <= 0;
            pmp_ready_d <= 0; iopmp_ready_d <= 0; secure_d <= 0;
            txn_id_next <= 16'd1;
            led_head <= 0;
            last_dma_admit_v <= 0;
            last_cpu_v <= 0;
            last_delay_v <= 0;
            dma_req_cap_v <= 0;
            cpu_reset_epoch <= 16'd0;
            for (i = 0; i < LEDGER_N; i = i + 1) begin
                led_valid[i] <= 0; led_arb_seen[i] <= 0;
                led_delay_seen[i] <= 0; led_write_cnt[i] <= 0; led_done[i] <= 0;
                led_plock[i] <= 0;
            end
        end else begin
            // Capture requester payload while request is live (before reset clears it)
            if (dma_req) begin
                dma_req_addr_cap  <= dma_addr;
                dma_req_wdata_cap <= dma_wdata;
                dma_req_write_cap <= dma_write;
                dma_req_cap_v     <= 1'b1;
            end

            if (cpu_reset_n_d && !cpu_reset_n) begin
                $fwrite(fd, "CYC=%0d EVT=CPU_RESET_ASSERT\n", cycle);
                cpu_reset_epoch <= cpu_reset_epoch + 16'd1;
                // Close last-CPU / last-delay pointers if that TXN already committed
                // a SRAM write. In-flight (write_cnt==0) stays bound (Model A drain).
                if (last_cpu_v) begin
                    for (i = 0; i < LEDGER_N; i = i + 1)
                        if (led_valid[i] && led_id[i] == last_cpu_id && led_write_cnt[i] >= 8'd1)
                            last_cpu_v <= 1'b0;
                end
                if (last_delay_v && last_delay_cpu) begin
                    for (i = 0; i < LEDGER_N; i = i + 1)
                        if (led_valid[i] && led_id[i] == last_delay_id && led_write_cnt[i] >= 8'd1)
                            last_delay_v <= 1'b0;
                end
                $fwrite(fd, "CYC=%0d EVT=LEDGER_CPU_EPOCH epoch=%0d\n",
                    cycle, cpu_reset_epoch + 16'd1);
            end
            if (!cpu_reset_n_d && cpu_reset_n)
                $fwrite(fd, "CYC=%0d EVT=CPU_RESET_RELEASE\n", cycle);
            if (dma_reset_n_d && !dma_reset_n)
                $fwrite(fd, "CYC=%0d EVT=DMA_RESET_ASSERT\n", cycle);
            if (!dma_reset_n_d && dma_reset_n)
                $fwrite(fd, "CYC=%0d EVT=DMA_RESET_RELEASE\n", cycle);
            if (iopmp_reset_n_d && !iopmp_reset_n)
                $fwrite(fd, "CYC=%0d EVT=IOPMP_RESET_ASSERT\n", cycle);
            if (!iopmp_reset_n_d && iopmp_reset_n)
                $fwrite(fd, "CYC=%0d EVT=IOPMP_RESET_RELEASE\n", cycle);
            if (sec_reset_n_d && !security_config_reset_n)
                $fwrite(fd, "CYC=%0d EVT=SEC_RESET_ASSERT\n", cycle);
            if (!sec_reset_n_d && security_config_reset_n)
                $fwrite(fd, "CYC=%0d EVT=SEC_RESET_RELEASE\n", cycle);
            if (ic_reset_n_d && !interconnect_reset_n)
                $fwrite(fd, "CYC=%0d EVT=IC_RESET_ASSERT\n", cycle);
            if (!ic_reset_n_d && interconnect_reset_n)
                $fwrite(fd, "CYC=%0d EVT=IC_RESET_RELEASE\n", cycle);
            if (!pmp_ready_d && pmp_ready)
                $fwrite(fd, "CYC=%0d EVT=PMP_READY\n", cycle);
            if (!iopmp_ready_d && iopmp_ready)
                $fwrite(fd, "CYC=%0d EVT=IOPMP_READY\n", cycle);
            if (!secure_d && sys_secure_ready)
                $fwrite(fd, "CYC=%0d EVT=SECURE_READY\n", cycle);

            // DMA admission: prefer IOPMP txn_* captured at admit (not live requester)
            if (dma_gnt_iopmp && iopmp_txn_valid) begin
                if (iopmp_txn_auth) begin
                    led_id[led_head] <= txn_id_next;
                    led_valid[led_head] <= 1'b1;
                    led_auth[led_head] <= 1'b1;
                    led_master_cpu[led_head] <= 1'b0;
                    // Admission payload precedence: txn_addr/write from IOPMP, wdata from
                    // requester snapshot (txn has no wdata port), else live dma_*.
                    led_addr[led_head]  <= iopmp_txn_addr;
                    led_write[led_head] <= iopmp_txn_write;
                    led_wdata[led_head] <= dma_req_cap_v ? dma_req_wdata_cap : dma_wdata;
                    led_rid[led_head] <= iopmp_txn_rid;
                    led_admit_cy[led_head] <= cycle;
                    led_arb_cy[led_head] <= 0;
                    led_delay_cy[led_head] <= 0;
                    led_write_cy[led_head] <= 0;
                    led_done_cy[led_head] <= 0;
                    led_arb_seen[led_head] <= 1'b0;
                    led_delay_seen[led_head] <= 1'b0;
                    led_write_cnt[led_head] <= 8'd0;
                    led_done[led_head] <= 1'b0;
                    led_plock[led_head] <= 1'b1;
                    last_dma_admit_id <= txn_id_next;
                    last_dma_admit_v <= 1'b1;
                    $fwrite(fd,
                        "CYC=%0d EVT=DMA_ADMITTED TXN_ID=%0d RID=0x%02x ADDR=0x%08x WDATA=0x%08x WRITE=%0d AUTH=1 DMA_RST=%0d IOPMP_RST=%0d IC_RST=%0d SRC=txn_snap\n",
                        cycle, txn_id_next, iopmp_txn_rid, iopmp_txn_addr,
                        dma_req_cap_v ? dma_req_wdata_cap : dma_wdata, iopmp_txn_write,
                        dma_reset_n, iopmp_reset_n, interconnect_reset_n);
                    txn_id_next <= txn_id_next + 16'd1;
                    led_head <= led_head + 3'd1;
                    dma_req_cap_v <= 1'b0;
                end else begin
                    $fwrite(fd,
                        "CYC=%0d EVT=DMA_DENIED RID=0x%02x ADDR=0x%08x WDATA=0x%08x WRITE=%0d\n",
                        cycle, iopmp_txn_rid, iopmp_txn_addr, dma_wdata, iopmp_txn_write);
                end
            end

            // CPU/init arbiter grant → ledger (covers harness init writer + adapter)
            if (cpu_ic_req && cpu_ic_gnt && cpu_ic_write &&
                cpu_ic_addr >= `ADDR_PROTECT_SRAM_BASE &&
                cpu_ic_addr <= `ADDR_PROTECT_SRAM_LIMIT) begin
                led_id[led_head] <= txn_id_next;
                led_valid[led_head] <= 1'b1;
                led_auth[led_head] <= 1'b1;
                led_master_cpu[led_head] <= 1'b1;
                led_addr[led_head] <= cpu_ic_addr;
                led_wdata[led_head] <= cpu_ic_wdata;
                led_write[led_head] <= 1'b1;
                led_rid[led_head] <= 8'h0;
                led_admit_cy[led_head] <= cycle;
                led_arb_seen[led_head] <= 1'b1;
                led_arb_cy[led_head] <= cycle;
                led_delay_seen[led_head] <= 1'b0;
                led_write_cnt[led_head] <= 0;
                led_done[led_head] <= 0;
                led_plock[led_head] <= 1'b1;
                last_cpu_id <= txn_id_next;
                last_cpu_v <= 1'b1;
                $fwrite(fd,
                    "CYC=%0d EVT=CPU_ADMITTED TXN_ID=%0d ADDR=0x%08x WDATA=0x%08x WRITE=1\n",
                    cycle, txn_id_next, cpu_ic_addr, cpu_ic_wdata);
                txn_id_next <= txn_id_next + 16'd1;
                led_head <= led_head + 3'd1;
            end

            if (arb_dma_gnt) begin
                $fwrite(fd, "CYC=%0d EVT=ARB_DMA_GNT iopmp_req_out=%0d addr=0x%08x wdata=0x%08x write=%0d\n",
                    cycle, iopmp_req_out, iopmp_addr_out, iopmp_wdata_out, iopmp_write_out);
                if (last_dma_admit_v) begin
                    for (i = 0; i < LEDGER_N; i = i + 1)
                        if (led_valid[i] && led_id[i] == last_dma_admit_id) begin
                            led_arb_seen[i] <= 1'b1;
                            led_arb_cy[i] <= cycle;
                        end
                    $fwrite(fd,
                        "CYC=%0d EVT=DMA_TARGET_ACCEPTED TXN_ID=%0d IOPMP_ADDR=0x%08x WRITE=%0d WDATA=0x%08x\n",
                        cycle, last_dma_admit_id, iopmp_addr_out, iopmp_write_out, iopmp_wdata_out);
                end else begin
                    $fwrite(fd, "CYC=%0d EVT=DMA_TARGET_ACCEPTED TXN_ID=0 ORPHAN_GRANT=1\n", cycle);
                end
            end

            if (delay_accepted) begin
                if (arb_serve_cpu) begin
                    begin : cpu_delay_bind
                        reg [15:0] bind_id;
                        reg        last_already_written;
                        last_already_written = 1'b0;
                        if (last_cpu_v) begin
                            for (i = 0; i < LEDGER_N; i = i + 1)
                                if (led_valid[i] && led_id[i] == last_cpu_id &&
                                    led_write_cnt[i] >= 8'd1)
                                    last_already_written = 1'b1;
                        end
                        if (last_cpu_v && !last_already_written)
                            bind_id = last_cpu_id;
                        else begin
                            // New CPU beat after a completed seed / after reset epoch.
                            bind_id = txn_id_next;
                            led_id[led_head] <= txn_id_next;
                            led_valid[led_head] <= 1'b1;
                            led_auth[led_head] <= 1'b1;
                            led_master_cpu[led_head] <= 1'b1;
                            led_addr[led_head] <= cpu_ic_addr;
                            led_wdata[led_head] <= cpu_ic_wdata;
                            led_write[led_head] <= 1'b1;
                            led_rid[led_head] <= 8'h0;
                            led_admit_cy[led_head] <= cycle;
                            led_arb_seen[led_head] <= 1'b1;
                            led_arb_cy[led_head] <= cycle;
                            led_delay_seen[led_head] <= 1'b1;
                            led_delay_cy[led_head] <= cycle;
                            led_write_cnt[led_head] <= 8'd0;
                            led_done[led_head] <= 1'b0;
                            led_plock[led_head] <= 1'b0; // payload from delay/SRAM, not stale cpu_ic_*
                            last_cpu_id <= txn_id_next;
                            last_cpu_v <= 1'b1;
                            $fwrite(fd,
                                "CYC=%0d EVT=CPU_ADMITTED TXN_ID=%0d ADDR=0x%08x WDATA=0x%08x WRITE=1 SRC=delay_epoch\n",
                                cycle, txn_id_next, cpu_ic_addr, cpu_ic_wdata);
                            txn_id_next <= txn_id_next + 16'd1;
                            led_head <= led_head + 3'd1;
                        end
                        last_delay_id <= bind_id;
                        last_delay_v <= 1'b1;
                        last_delay_cpu <= 1'b1;
                        $fwrite(fd, "CYC=%0d EVT=DELAY_ACCEPTED TXN_ID=%0d SRC=CPU\n",
                            cycle, bind_id);
                    end
                end else begin
                    last_delay_id <= last_dma_admit_v ? last_dma_admit_id : 16'd0;
                    last_delay_v <= 1'b1;
                    last_delay_cpu <= 1'b0;
                    $fwrite(fd, "CYC=%0d EVT=DELAY_ACCEPTED TXN_ID=%0d SRC=DMA LIVE_ADMIT=%0d\n",
                        cycle, last_dma_admit_v ? last_dma_admit_id : 16'd0, last_dma_admit_v);
                    for (i = 0; i < LEDGER_N; i = i + 1)
                        if (led_valid[i] && led_id[i] == last_dma_admit_id) begin
                            led_delay_seen[i] <= 1'b1;
                            led_delay_cy[i] <= cycle;
                        end
                end
            end

            // INDEPENDENT actual SRAM write (not mem_changed)
            if (actual_sram_write) begin
                begin : sram_wr
                    reg [15:0] mid;
                    reg is_cpu;
                    reg reuse_closed;
                    mid = 16'd0;
                    is_cpu = 1'b0;
                    reuse_closed = 1'b0;
                    if (last_delay_v && last_delay_id != 16'd0) begin
                        for (i = 0; i < LEDGER_N; i = i + 1)
                            if (led_valid[i] && led_id[i] == last_delay_id) begin
                                if (led_write_cnt[i] >= 8'd1)
                                    reuse_closed = 1'b1;
                                else if (led_plock[i] &&
                                         (led_wdata[i] != sram_prot_wdata ||
                                          led_addr[i] != sram_prot_addr))
                                    reuse_closed = 1'b1;
                                else begin
                                    mid = last_delay_id;
                                    is_cpu = led_master_cpu[i];
                                end
                            end
                    end
                    if (mid == 16'd0)
                        mid = match_open_write(sram_prot_addr, sram_prot_wdata);
                    if (mid != 16'd0) begin
                        for (i = 0; i < LEDGER_N; i = i + 1)
                            if (led_valid[i] && led_id[i] == mid)
                                is_cpu = led_master_cpu[i];
                    end
                    if (mid == 16'd0 && reuse_closed) begin
                        mid = txn_id_next;
                        is_cpu = last_delay_cpu;
                        led_id[led_head] <= txn_id_next;
                        led_valid[led_head] <= 1'b1;
                        led_auth[led_head] <= 1'b1;
                        led_master_cpu[led_head] <= last_delay_cpu;
                        led_addr[led_head] <= sram_prot_addr;
                        led_wdata[led_head] <= sram_prot_wdata;
                        led_write[led_head] <= 1'b1;
                        led_rid[led_head] <= 8'h0;
                        led_admit_cy[led_head] <= cycle;
                        led_write_cnt[led_head] <= 8'd0;
                        led_done[led_head] <= 1'b0;
                        $fwrite(fd,
                            "CYC=%0d EVT=TXN_LATEBIND TXN_ID=%0d ADDR=0x%08x DATA=0x%08x SRC=%s\n",
                            cycle, txn_id_next, sram_prot_addr, sram_prot_wdata,
                            last_delay_cpu ? "CPU" : "DMA");
                        txn_id_next <= txn_id_next + 16'd1;
                        led_head <= led_head + 3'd1;
                    end
                    $fwrite(fd,
                        "CYC=%0d EVT=SRAM_WRITE SRC=%s TXN_ID=%0d ADDR=0x%08x DATA=0x%08x\n",
                        cycle, is_cpu ? "CPU" : "DMA", mid, sram_prot_addr, sram_prot_wdata);
                    if (mid != 0) begin
                        for (i = 0; i < LEDGER_N; i = i + 1)
                            if (led_valid[i] && led_id[i] == mid) begin
                                if (led_write_cnt[i] >= 8'd1)
                                    $fwrite(fd,
                                        "CYC=%0d EVT=SCOREBOARD_FAIL REASON=DUPLICATE_SRAM_WRITE TXN_ID=%0d CNT=%0d\n",
                                        cycle, mid, led_write_cnt[i] + 1);
                                led_write_cnt[i] <= led_write_cnt[i] + 8'd1;
                                led_write_cy[i] <= cycle;
                                if (!led_plock[i]) begin
                                    led_addr[i] <= sram_prot_addr;
                                    led_wdata[i] <= sram_prot_wdata;
                                    led_plock[i] <= 1'b1;
                                end else if (led_addr[i] != sram_prot_addr ||
                                           led_wdata[i] != sram_prot_wdata)
                                    $fwrite(fd,
                                        "CYC=%0d EVT=SCOREBOARD_FAIL REASON=PAYLOAD_MISMATCH TXN_ID=%0d\n",
                                        cycle, mid);
                            end
                    end else begin
                        $fwrite(fd, "CYC=%0d EVT=SCOREBOARD_FAIL REASON=ORPHAN_SRAM_WRITE ADDR=0x%08x DATA=0x%08x\n",
                            cycle, sram_prot_addr, sram_prot_wdata);
                    end
                end
            end

            // Distinct mem_changed observability
            if (prot_mem_changed) begin
                $fwrite(fd,
                    "CYC=%0d EVT=PROT_COMMIT SRC=%s ADDR=0x%08x DATA=0x%08x\n",
                    cycle, arb_serve_cpu ? "CPU" : "DMA",
                    prot_changed_addr, prot_changed_wdata);
            end

            if (dma_valid_iopmp) begin
                $fwrite(fd, "CYC=%0d EVT=DMA_COMPLETED TXN_ID=%0d ERR=%0d\n",
                    cycle, last_dma_admit_v ? last_dma_admit_id : 16'd0, dma_error_iopmp);
                for (i = 0; i < LEDGER_N; i = i + 1)
                    if (led_valid[i] && led_id[i] == last_dma_admit_id) begin
                        led_done[i] <= 1'b1;
                        led_done_cy[i] <= cycle;
                    end
                last_dma_admit_v <= 1'b0;
            end

            if (cpu_adapt_valid)
                $fwrite(fd, "CYC=%0d EVT=CPU_RVALID\n", cycle);

            cpu_reset_n_d <= cpu_reset_n;
            dma_reset_n_d <= dma_reset_n;
            iopmp_reset_n_d <= iopmp_reset_n;
            sec_reset_n_d <= security_config_reset_n;
            ic_reset_n_d <= interconnect_reset_n;
            pmp_ready_d <= pmp_ready;
            iopmp_ready_d <= iopmp_ready;
            secure_d <= sys_secure_ready;
            $fflush(fd);
        end
    end
endmodule
