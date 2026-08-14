// Phase C.5 test-only delay between arbiter prot port and protected SRAM.
// delay_cycles==0: combinatorial pass-through (same timing as direct SRAM).
// delay_cycles==N>0: accept once, wait N cycles, then fire one SRAM access.
`include "bus_pkg.vh"

module m7_target_delay (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [7:0]               delay_cycles,
    input  wire                     in_req,
    input  wire                     in_write,
    input  wire [`ADDR_WIDTH-1:0]   in_addr,
    input  wire [`DATA_WIDTH-1:0]   in_wdata,
    output wire                     in_gnt,
    output wire                     in_valid,
    output wire [`DATA_WIDTH-1:0]   in_rdata,
    output wire                     out_req,
    output wire                     out_write,
    output wire [`ADDR_WIDTH-1:0]   out_addr,
    output wire [`DATA_WIDTH-1:0]   out_wdata,
    input  wire                     out_gnt,
    input  wire                     out_valid,
    input  wire [`DATA_WIDTH-1:0]   out_rdata,
    output wire                     delay_busy,
    output wire [7:0]               delay_count_o,
    output wire                     delay_accepted // pulse: accepted into delay (pre-commit)
);

    wire bypass = (delay_cycles == 8'd0);

    // Bypass path
    assign out_req   = bypass ? in_req   : d_out_req;
    assign out_write = bypass ? in_write : d_out_write;
    assign out_addr  = bypass ? in_addr  : d_out_addr;
    assign out_wdata = bypass ? in_wdata : d_out_wdata;
    assign in_gnt    = bypass ? out_gnt  : d_in_gnt;
    assign in_valid  = bypass ? out_valid: d_in_valid;
    assign in_rdata  = bypass ? out_rdata: d_in_rdata;
    assign delay_busy = bypass ? 1'b0 : d_busy;
    assign delay_count_o = bypass ? 8'd0 : d_cnt;
    assign delay_accepted = bypass ? 1'b0 : d_accepted;

    reg d_out_req, d_out_write, d_in_gnt, d_in_valid, d_busy, d_accepted, fired;
    reg need_req_drop;
    reg [`ADDR_WIDTH-1:0] d_out_addr;
    reg [`DATA_WIDTH-1:0] d_out_wdata, d_in_rdata;
    reg [7:0] d_cnt;
    reg [1:0] st;
    reg h_write;
    reg [`ADDR_WIDTH-1:0] h_addr;
    reg [`DATA_WIDTH-1:0] h_wdata;

    localparam S_IDLE = 2'd0;
    localparam S_WAIT = 2'd1;
    localparam S_FIRE = 2'd2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= S_IDLE;
            d_cnt <= 0;
            d_out_req <= 0;
            d_in_gnt <= 0;
            d_in_valid <= 0;
            d_in_rdata <= 0;
            d_busy <= 0;
            d_accepted <= 0;
            fired <= 0;
            need_req_drop <= 0;
            h_write <= 0;
            h_addr <= 0;
            h_wdata <= 0;
            d_out_write <= 0;
            d_out_addr <= 0;
            d_out_wdata <= 0;
        end else begin
            d_in_gnt <= 0;
            d_in_valid <= 0;
            d_out_req <= 0;
            d_accepted <= 0;
            if (bypass) begin
                st <= S_IDLE;
                d_busy <= 0;
                need_req_drop <= 0;
            end else begin
                unique case (st)
                    S_IDLE: begin
                        d_busy <= 0;
                        if (need_req_drop) begin
                            // Require master to drop req between transactions so a
                            // frozen in-flight req cannot be double-accepted.
                            if (!in_req)
                                need_req_drop <= 1'b0;
                        end else if (in_req) begin
                            h_write <= in_write;
                            h_addr  <= in_addr;
                            h_wdata <= in_wdata;
                            d_in_gnt <= 1'b1;
                            d_accepted <= 1'b1;
                            d_cnt <= delay_cycles;
                            d_busy <= 1'b1;
                            fired <= 1'b0;
                            st <= S_WAIT;
                        end
                    end
                    S_WAIT: begin
                        d_busy <= 1'b1;
                        if (d_cnt > 1)
                            d_cnt <= d_cnt - 1;
                        else begin
                            d_cnt <= 0;
                            st <= S_FIRE;
                        end
                    end
                    S_FIRE: begin
                        d_busy <= 1'b1;
                        if (!fired) begin
                            d_out_req   <= 1'b1;
                            d_out_write <= h_write;
                            d_out_addr  <= h_addr;
                            d_out_wdata <= h_wdata;
                            fired <= 1'b1;
                        end else begin
                            d_out_req <= 1'b0;
                        end
                        if (out_valid) begin
                            d_in_valid <= 1'b1;
                            d_in_rdata <= out_rdata;
                            d_busy <= 0;
                            fired <= 0;
                            need_req_drop <= 1'b1;
                            st <= S_IDLE;
                        end
                    end
                    default: st <= S_IDLE;
                endcase
            end
        end
    end

endmodule
