// Simplified PMP-like CPU access-control block (research baseline).
`include "bus_pkg.vh"

module pmp (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     enable,
    input  wire                     cpu_req,
    input  wire [`ADDR_WIDTH-1:0]   cpu_addr,
    input  wire                     cpu_write,
    input  wire [`DATA_WIDTH-1:0]   cpu_wdata,
    input  wire                     cpu_privilege,
    output reg                      cpu_gnt,
    output reg                      cpu_valid,
    output reg  [`DATA_WIDTH-1:0]   cpu_rdata,
    output reg                      cpu_error,
    output reg                      cpu_req_out,
    output reg  [`ADDR_WIDTH-1:0]   cpu_addr_out,
    output reg                      cpu_write_out,
    output reg  [`DATA_WIDTH-1:0]   cpu_wdata_out,
    input  wire                     bus_gnt,
    input  wire                     bus_valid,
    input  wire [`DATA_WIDTH-1:0]   bus_rdata
);

    reg pending;

    // Admission-time transaction metadata (stable until bus completion).
    reg                     hold_privilege;
    reg                     hold_write;
    reg [`ADDR_WIDTH-1:0]   hold_addr;

    function in_protected_region;
        input [`ADDR_WIDTH-1:0] a;
        begin
            in_protected_region = (a >= `ADDR_PROTECT_SRAM_BASE) &&
                                  (a <= `ADDR_PROTECT_SRAM_LIMIT);
        end
    endfunction

    function cpu_allowed;
        input [`ADDR_WIDTH-1:0] a;
        input priv;
        begin
            if (!enable)
                cpu_allowed = 1'b1;
            else if (in_protected_region(a))
                cpu_allowed = priv;
            else
                cpu_allowed = 1'b1;
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_req_out   <= 1'b0;
            cpu_addr_out  <= 32'h0;
            cpu_write_out <= 1'b0;
            cpu_wdata_out <= 32'h0;
            cpu_gnt       <= 1'b0;
            cpu_valid     <= 1'b0;
            cpu_rdata     <= 32'h0;
            cpu_error     <= 1'b0;
            pending       <= 1'b0;
            hold_privilege <= 1'b0;
            hold_write     <= 1'b0;
            hold_addr      <= 32'h0;
        end else begin
            cpu_req_out   <= 1'b0;
            cpu_addr_out  <= 32'h0;
            cpu_write_out <= 1'b0;
            cpu_gnt       <= 1'b0;
            cpu_valid     <= 1'b0;
            cpu_error     <= 1'b0;

            if (!pending && cpu_req) begin
                if (cpu_allowed(cpu_addr, cpu_privilege)) begin
                    hold_privilege <= cpu_privilege;
                    hold_write     <= cpu_write;
                    hold_addr      <= cpu_addr;
                    cpu_req_out   <= 1'b1;
                    cpu_addr_out  <= cpu_addr;
                    cpu_write_out <= cpu_write;
                    cpu_wdata_out <= cpu_wdata;
                    pending       <= 1'b1;
                    cpu_gnt       <= 1'b1;
                end else begin
                    cpu_valid <= 1'b1;
                    cpu_error <= 1'b1;
                    cpu_gnt   <= 1'b1;
                end
            end else if (pending) begin
                if (bus_valid) begin
                    cpu_valid <= 1'b1;
                    cpu_rdata <= bus_rdata;
                    pending   <= 1'b0;
                end
            end
        end
    end

`ifdef FORMAL
    // SP-02: protected-memory write commits require admission-time CPU privilege.
    always @(posedge clk) begin
        if (rst_n && enable && pending && bus_valid && hold_write &&
            in_protected_region(hold_addr))
            assert(hold_privilege);
    end
`endif

endmodule
