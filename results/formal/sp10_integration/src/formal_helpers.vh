// Shared formal helpers for protected-region checks and reset sequencing.
`ifndef FORMAL_HELPERS_VH
`define FORMAL_HELPERS_VH

`define IN_PROT(a) ((a) >= `ADDR_PROTECT_SRAM_BASE && (a) <= `ADDR_PROTECT_SRAM_LIMIT)

// Self-contained reset: ext_rst_n starts low, releases after first clock.
// dut_rst_n deasserts one cycle later; formal_warmup after two post-release cycles.
`define FORMAL_RESET_CTRL(clk, dut_rst_n, formal_warmup) \
    reg       ext_rst_n; \
    reg [3:0] formal_rc; \
    reg       dut_rst_n; \
    initial ext_rst_n = 1'b0; \
    always @(posedge clk) ext_rst_n <= 1'b1; \
    always @(posedge clk or negedge ext_rst_n) begin \
        if (!ext_rst_n) begin \
            formal_rc <= 4'd0; \
            dut_rst_n <= 1'b0; \
        end else begin \
            formal_rc <= formal_rc + 4'd1; \
            dut_rst_n <= (formal_rc >= 4'd1); \
        end \
    end \
    wire formal_warmup = ext_rst_n && dut_rst_n && (formal_rc >= 4'd2);

`endif
