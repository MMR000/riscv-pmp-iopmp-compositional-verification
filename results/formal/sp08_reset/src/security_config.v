// Security configuration registers for PMP/IOPMP enable and IOPMP rule 0.
`include "bus_pkg.vh"

module security_config (
    input  wire                     clk,
    input  wire                     rst_n,
    output reg                      pmp_enable,
    output reg                      iopmp_enable,
    output reg  [`ADDR_WIDTH-1:0]   rule0_base,
    output reg  [`ADDR_WIDTH-1:0]   rule0_limit,
    output reg  [7:0]               rule0_rid,
    output reg                      rule0_re,
    output reg                      rule0_we,
    output reg                      rule0_valid,
    output wire                     secure_ready,
    output wire [7:0]               security_epoch,
    input  wire                     cfg_write,
    input  wire [`ADDR_WIDTH-1:0]   cfg_addr,
    input  wire [`DATA_WIDTH-1:0]   cfg_wdata
);

    assign secure_ready = pmp_enable && iopmp_enable && rule0_valid;

    reg [7:0] epoch;
    reg rule0_valid_q;
    assign security_epoch = epoch;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            epoch <= 8'd0;
            rule0_valid_q <= 1'b0;
        end else begin
            rule0_valid_q <= rule0_valid;
            if (rule0_valid_q && !rule0_valid)
                epoch <= epoch + 8'd1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pmp_enable    <= 1'b1;
`ifdef RST_B
            // Fail-closed: IOPMP filtering active, no valid rule until trusted init.
            iopmp_enable  <= 1'b1;
`else
            // RST-A fail-open: IOPMP disabled until configured (enable=0 bypass).
            iopmp_enable  <= 1'b0;
`endif
            rule0_base    <= `ADDR_PROTECT_SRAM_BASE;
            rule0_limit   <= `ADDR_PROTECT_SRAM_LIMIT;
            rule0_rid     <= 8'h01;
            rule0_re      <= 1'b1;
            rule0_we      <= 1'b1;
            rule0_valid   <= 1'b0;
        end else if (cfg_write) begin
            if (cfg_addr == (`ADDR_SEC_CFG_BASE + 32'h0))
                pmp_enable <= cfg_wdata[0];
            else if (cfg_addr == (`ADDR_SEC_CFG_BASE + 32'h4))
                iopmp_enable <= cfg_wdata[0];
            else if (cfg_addr == (`ADDR_SEC_CFG_BASE + 32'h100))
                rule0_base <= cfg_wdata;
            else if (cfg_addr == (`ADDR_SEC_CFG_BASE + 32'h104))
                rule0_limit <= cfg_wdata;
            else if (cfg_addr == (`ADDR_SEC_CFG_BASE + 32'h108)) begin
                rule0_rid   <= cfg_wdata[7:0];
                rule0_re    <= cfg_wdata[8];
                rule0_we    <= cfg_wdata[9];
                rule0_valid <= cfg_wdata[10];
            end
        end
    end

endmodule
