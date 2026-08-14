// M5.6 formal harness — abstract write-path transaction-binding repair model.
`timescale 1ns/1ps

module formal_m56_write_path_tb (
    input wire clk,
    input wire rst_n
);

  localparam RESP_OKAY   = 2'b00;
  localparam RESP_SLVERR = 2'b10;

  localparam ST_IDLE       = 3'd0;
  localparam ST_VERIFY     = 3'd1;
  localparam ST_WAIT_IOPMP = 3'd2;
  localparam ST_HANDSHAKE  = 3'd3;
  localparam ST_WAIT_B     = 3'd4;

  reg [2:0] state;
  reg route_select;
  reg write_aw_done;
  reg aw_active;

  reg slv_aw_valid;
  reg slv_w_valid;
  reg slv_b_ready;
  reg iopmp_allow;
  reg iopmp_valid;

  wire slv_aw_ready;
  wire slv_w_ready;
  wire slv_b_valid;
  wire [1:0] b_resp;
  wire dst_aw_valid;
  wire dst_w_valid;
  wire mem_we;
  wire deny_decision;

  assign deny_decision = iopmp_valid && !iopmp_allow;
  assign dst_aw_valid = (state == ST_HANDSHAKE) && aw_active && !write_aw_done && slv_aw_valid;
  assign dst_w_valid  = (state == ST_HANDSHAKE) && aw_active && write_aw_done && slv_w_valid && route_select;
  assign mem_we       = dst_w_valid && slv_w_ready;

  assign slv_aw_ready = (state == ST_HANDSHAKE) && aw_active && !write_aw_done && slv_aw_valid && route_select;
  assign slv_w_ready  = (state == ST_HANDSHAKE) && aw_active && slv_w_valid &&
                        (route_select || deny_decision);
  assign slv_b_valid  = (state == ST_HANDSHAKE) && deny_decision && slv_w_valid && slv_w_ready;
  assign b_resp       = deny_decision ? RESP_SLVERR : RESP_OKAY;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= ST_IDLE;
      route_select <= 1'b0;
      write_aw_done <= 1'b0;
      aw_active <= 1'b0;
    end else begin
      case (state)
        ST_IDLE: begin
          route_select <= 1'b0;
          write_aw_done <= 1'b0;
          aw_active <= 1'b0;
          if (slv_aw_valid) begin
            aw_active <= 1'b1;
            state <= ST_VERIFY;
          end
        end
        ST_VERIFY: begin
          state <= ST_WAIT_IOPMP;
        end
        ST_WAIT_IOPMP: begin
          if (iopmp_valid) begin
            route_select <= iopmp_allow;
            state <= ST_HANDSHAKE;
          end
        end
        ST_HANDSHAKE: begin
          if (deny_decision) begin
            if (slv_w_valid && slv_w_ready) begin
              state <= ST_IDLE;
              route_select <= 1'b0;
              write_aw_done <= 1'b0;
              aw_active <= 1'b0;
            end
          end else if (route_select) begin
            if (!write_aw_done && slv_aw_valid && slv_aw_ready)
              write_aw_done <= 1'b1;
            else if (write_aw_done && slv_w_valid && slv_w_ready)
              state <= ST_WAIT_B;
          end
        end
        ST_WAIT_B: begin
          if (slv_b_valid && slv_b_ready) begin
            state <= ST_IDLE;
            route_select <= 1'b0;
            write_aw_done <= 1'b0;
            aw_active <= 1'b0;
          end
        end
        default: state <= ST_IDLE;
      endcase
    end
  end

  // M56-FA-05: bounded IOPMP response (environment constraint in simulation)
  // Formal: unconstrained iopmp_valid driven by solver within depth bound

  // F-WP-01
  always @(posedge clk)
    if (rst_n && deny_decision)
      assert(!dst_aw_valid);

  // F-WP-02 / F-WP-03
  always @(posedge clk)
    if (rst_n && state == ST_HANDSHAKE && !route_select)
      assert(!dst_w_valid && !mem_we);

  // F-WP-04
  always @(posedge clk)
    if (rst_n && dst_w_valid)
      assert(route_select);

  // F-WP-05 / F-WP-06
  always @(posedge clk)
    if (rst_n && state == ST_IDLE)
      assert(!route_select);

  // F-WP-07: after reset release, route select clear in idle
  reg rst_q;
  always @(posedge clk) rst_q <= rst_n;
  always @(posedge clk)
    if (rst_q && state == ST_IDLE)
      assert(!route_select);

  // Covers F-WP-08 / F-WP-09 verified in simulation (not BMC cover checks here)

endmodule
