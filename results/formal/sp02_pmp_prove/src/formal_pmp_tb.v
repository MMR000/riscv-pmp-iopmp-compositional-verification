// Unit-level formal harness for PMP (uses production pmp.v RTL).
`include "bus_pkg.vh"
`include "formal_helpers.vh"

module formal_pmp_tb (
    input wire clk,
    input wire rst_n
);

    `FORMAL_RESET_CTRL(clk, dut_rst_n, formal_warmup)

    reg                     enable;
    reg                     cpu_req;
    reg [`ADDR_WIDTH-1:0]   cpu_addr;
    reg                     cpu_write;
    reg [`DATA_WIDTH-1:0]   cpu_wdata;
    reg                     cpu_privilege;

    wire cpu_gnt, cpu_valid, cpu_error;
    wire [`DATA_WIDTH-1:0] cpu_rdata;
    wire cpu_req_out;
    wire [`ADDR_WIDTH-1:0] cpu_addr_out;
    wire cpu_write_out;
    wire bus_gnt, bus_valid;
    wire [`DATA_WIDTH-1:0] bus_rdata;

    pmp u_dut (
        .clk(clk), .rst_n(dut_rst_n), .enable(enable),
        .cpu_req(cpu_req), .cpu_addr(cpu_addr), .cpu_write(cpu_write),
        .cpu_wdata(cpu_wdata), .cpu_privilege(cpu_privilege),
        .cpu_gnt(cpu_gnt), .cpu_valid(cpu_valid), .cpu_rdata(cpu_rdata),
        .cpu_error(cpu_error),
        .cpu_req_out(cpu_req_out), .cpu_addr_out(cpu_addr_out),
        .cpu_write_out(cpu_write_out), .cpu_wdata_out(),
        .bus_gnt(bus_gnt), .bus_valid(bus_valid), .bus_rdata(bus_rdata)
    );

    formal_bus_stub u_bus (
        .clk(clk), .rst_n(dut_rst_n),
        .req(cpu_req_out), .write(cpu_write_out),
        .gnt(bus_gnt), .valid(bus_valid), .rdata(bus_rdata)
    );

    wire unauth_cpu_admit = enable && cpu_req && !u_dut.pending &&
                            cpu_write && `IN_PROT(cpu_addr) && !cpu_privilege;

    always @(*) assume (enable);

    // SP-02 checked in pmp.v (`ifdef FORMAL) using latched hold_* at commit.

    always @(posedge clk) cover(formal_warmup && cpu_req && cpu_privilege && cpu_write);
    always @(posedge clk) cover(formal_warmup && unauth_cpu_admit);

endmodule
