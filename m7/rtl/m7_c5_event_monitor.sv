// Phase C.5 event monitor — simulation observability only.
`include "bus_pkg.vh"

module m7_c5_event_monitor (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [31:0]              cycle,
    // DMA / IOPMP
    input  wire                     dma_req,
    input  wire                     dma_gnt_iopmp,
    input  wire                     dma_valid_iopmp,
    input  wire                     dma_error_iopmp,
    input  wire                     iopmp_txn_valid,
    input  wire                     iopmp_txn_auth,
    input  wire [7:0]               iopmp_txn_rid,
    input  wire                     iopmp_req_out,
    input  wire                     arb_dma_gnt,
    input  wire                     arb_dma_valid,
    input  wire [`ADDR_WIDTH-1:0]   dma_addr,
    input  wire [`DATA_WIDTH-1:0]   dma_wdata,
    input  wire                     dma_write,
    // CPU
    input  wire                     cpu_adapt_req,
    input  wire                     cpu_adapt_gnt,
    input  wire                     cpu_adapt_valid,
    input  wire                     cpu_adapt_write,
    input  wire [`ADDR_WIDTH-1:0]   cpu_adapt_addr,
    input  wire [`DATA_WIDTH-1:0]   cpu_adapt_wdata,
    // Resets
    input  wire                     cpu_reset_n,
    input  wire                     dma_reset_n,
    input  wire                     iopmp_reset_n,
    input  wire                     security_config_reset_n,
    input  wire                     interconnect_reset_n,
    // Memory commit
    input  wire                     prot_mem_changed,
    input  wire [`ADDR_WIDTH-1:0]   prot_changed_addr,
    input  wire [`DATA_WIDTH-1:0]   prot_changed_wdata,
    input  wire                     arb_serve_cpu, // 1 if last/current arbiter service is CPU
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

    wire iopmp_ready = iopmp_enable && rule0_valid;

    initial begin
        fd = $fopen("m7_c5_events.log", "w");
        $fwrite(fd, "# C5 event log\n");
    end
    final $fclose(fd);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_reset_n_d <= 0;
            dma_reset_n_d <= 0;
            iopmp_reset_n_d <= 0;
            sec_reset_n_d <= 0;
            ic_reset_n_d <= 0;
            pmp_ready_d <= 0;
            iopmp_ready_d <= 0;
            secure_d <= 0;
        end else begin
            // Reset edges
            if (cpu_reset_n_d && !cpu_reset_n)
                $fwrite(fd, "CYC=%0d EVT=CPU_RESET_ASSERT\n", cycle);
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

            // DMA landmarks
            if (dma_req && dma_gnt_iopmp && iopmp_txn_valid) begin
                if (iopmp_txn_auth)
                    $fwrite(fd, "CYC=%0d EVT=DMA_ADMITTED RID=0x%02x ADDR=0x%08x WDATA=0x%08x WRITE=%0d\n",
                        cycle, iopmp_txn_rid, dma_addr, dma_wdata, dma_write);
                else
                    $fwrite(fd, "CYC=%0d EVT=DMA_DENIED RID=0x%02x ADDR=0x%08x WDATA=0x%08x WRITE=%0d\n",
                        cycle, iopmp_txn_rid, dma_addr, dma_wdata, dma_write);
            end
            if (dma_req && !dma_gnt_iopmp)
                ; // request outstanding — first cycle logged below
            // REQUESTED: rising edge of dma_req while idle-ish — log each grant cycle's companion
            if (iopmp_req_out && arb_dma_gnt)
                $fwrite(fd, "CYC=%0d EVT=DMA_TARGET_ACCEPTED ADDR=0x%08x\n", cycle, dma_addr);
            if (delay_accepted)
                $fwrite(fd, "CYC=%0d EVT=DELAY_ACCEPTED\n", cycle);
            if (prot_mem_changed) begin
                if (arb_serve_cpu)
                    $fwrite(fd, "CYC=%0d EVT=PROT_COMMIT SRC=CPU ADDR=0x%08x DATA=0x%08x\n",
                        cycle, prot_changed_addr, prot_changed_wdata);
                else
                    $fwrite(fd, "CYC=%0d EVT=PROT_COMMIT SRC=DMA ADDR=0x%08x DATA=0x%08x\n",
                        cycle, prot_changed_addr, prot_changed_wdata);
            end
            if (dma_valid_iopmp)
                $fwrite(fd, "CYC=%0d EVT=DMA_COMPLETED ERR=%0d\n", cycle, dma_error_iopmp);

            // CPU landmarks
            if (cpu_adapt_req && cpu_adapt_gnt)
                $fwrite(fd, "CYC=%0d EVT=CPU_REQ_GNT ADDR=0x%08x WE=%0d WDATA=0x%08x\n",
                    cycle, cpu_adapt_addr, cpu_adapt_write, cpu_adapt_wdata);
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
