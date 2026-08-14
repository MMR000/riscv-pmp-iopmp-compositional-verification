// M5.6 proper fix v2 — phased AW-then-W handshake binds W route to AW decision.
// Upstream base: zero-day-labs/riscv-iopmp @ a029581

module rv_iopmp_data_abstractor_axi #(
    parameter int unsigned SID_WIDTH      = 8,
    parameter int unsigned DATA_WIDTH     = 64,
    parameter int unsigned ADDR_WIDTH     = 64,
    parameter int unsigned ID_WIDTH       = 8,
    parameter type         axi_req_nsaid_t  = logic,
    parameter type         axi_req_t        = logic,
    parameter type         axi_rsp_t        = logic,
    parameter type         axi_aw_chan_t  = logic,
    parameter type         axi_w_chan_t   = logic,
    parameter type         axi_b_chan_t   = logic,
    parameter type         axi_ar_chan_t  = logic,
    parameter type         axi_r_chan_t   = logic
) (
    input logic clk_i,
    input logic rst_ni,
    input  axi_req_nsaid_t slv_req_i,
    output axi_rsp_t       slv_rsp_o,
    output axi_req_t       mst_req_o,
    input  axi_rsp_t       mst_rsp_i,
    output logic                                   transaction_en_o,
    output logic [ADDR_WIDTH - 1:0]                addr_o,
    output logic [ADDR_WIDTH - 1:0]         total_length_o,
    output logic [$clog2(DATA_WIDTH/8) :0]         num_bytes_o,
    output logic [SID_WIDTH     - 1:0]             sid_o,
    output rv_iopmp_pkg::access_t                  access_type_o,
    input  logic                 iopmp_allow_transaction_i,
    input  logic                                   ready_i,
    input  logic                                   valid_i
);

typedef enum logic [2:0] {
    IDLE            = 3'b000,
    VERIFICATION    = 3'b001,
    WAIT_IOPMP      = 3'b010,
    AXI_HANDSHAKE   = 3'b011,
    WAIT_B          = 3'b100
} state_t;

logic route_select_q, route_select_n;
logic write_aw_done_q, write_aw_done_n;
logic transaction_allowed_n, transaction_allowed_q;
logic aw_request_n, aw_request_q;
logic ar_request_n, ar_request_q;
logic [ADDR_WIDTH-1:0] addr_n, addr_q, addr_to_check_n, addr_to_check_q;
logic [ADDR_WIDTH - 1:0] total_length_n, total_length_q;
logic [$clog2(DATA_WIDTH/8) :0] num_bytes_n, num_bytes_q;
axi_pkg::burst_t burst_type_n, burst_type_q;
axi_pkg::len_t burst_length_n, burst_length_q;
axi_pkg::size_t size_n, size_q;
logic bc_allow_request, bc_bound_violation;
logic [ADDR_WIDTH-1:0] wrap_boundary;
state_t state_n, state_q;
axi_req_t axi_aux_req;

logic hs_active;
logic write_hs_active;
logic read_hs_active;

assign hs_active         = (state_q == AXI_HANDSHAKE);
assign write_hs_active   = hs_active && aw_request_q;
assign read_hs_active    = hs_active && ar_request_q;

assign addr_o = addr_to_check_q;
assign num_bytes_o = num_bytes_q;
assign sid_o = aw_request_q ? slv_req_i.aw.nsaid : slv_req_i.ar.nsaid;
assign access_type_o = aw_request_q ? rv_iopmp_pkg::ACCESS_WRITE : rv_iopmp_pkg::ACCESS_READ;
assign total_length_o = total_length_q;

// Phase 1: AW only. Phase 2: W after AW accepted (demux route FIFO populated).
assign axi_aux_req.aw_valid = write_hs_active && !write_aw_done_q && slv_req_i.aw_valid;
assign axi_aux_req.aw.id = slv_req_i.aw.id;
assign axi_aux_req.aw.addr = slv_req_i.aw.addr;
assign axi_aux_req.aw.len = slv_req_i.aw.len;
assign axi_aux_req.aw.size = slv_req_i.aw.size;
assign axi_aux_req.aw.burst = slv_req_i.aw.burst;
assign axi_aux_req.aw.lock = slv_req_i.aw.lock;
assign axi_aux_req.aw.cache = slv_req_i.aw.cache;
assign axi_aux_req.aw.prot = slv_req_i.aw.prot;
assign axi_aux_req.aw.qos = slv_req_i.aw.qos;
assign axi_aux_req.aw.region = slv_req_i.aw.region;
assign axi_aux_req.aw.atop = slv_req_i.aw.atop;
assign axi_aux_req.aw.user = slv_req_i.aw.user;

assign axi_aux_req.w = slv_req_i.w;
assign axi_aux_req.w_valid = write_hs_active && write_aw_done_q && slv_req_i.w_valid;

assign axi_aux_req.b_ready = slv_req_i.b_ready;
assign axi_aux_req.ar_valid = read_hs_active && slv_req_i.ar_valid;
assign axi_aux_req.ar.id = slv_req_i.ar.id;
assign axi_aux_req.ar.addr = slv_req_i.ar.addr;
assign axi_aux_req.ar.len = slv_req_i.ar.len;
assign axi_aux_req.ar.size = slv_req_i.ar.size;
assign axi_aux_req.ar.burst = slv_req_i.ar.burst;
assign axi_aux_req.ar.lock = slv_req_i.ar.lock;
assign axi_aux_req.ar.cache = slv_req_i.ar.cache;
assign axi_aux_req.ar.prot = slv_req_i.ar.prot;
assign axi_aux_req.ar.qos = slv_req_i.ar.qos;
assign axi_aux_req.ar.region = slv_req_i.ar.region;
assign axi_aux_req.ar.user = slv_req_i.ar.user;
assign axi_aux_req.r_ready = slv_req_i.r_ready;

always_comb begin
    state_n = state_q;
    route_select_n = route_select_q;
    write_aw_done_n = write_aw_done_q;
    transaction_allowed_n = transaction_allowed_q;
    transaction_en_o = 1'b0;
    aw_request_n = aw_request_q;
    ar_request_n = ar_request_q;
    num_bytes_n = num_bytes_q;
    addr_n = addr_q;
    addr_to_check_n = addr_to_check_q;
    size_n = size_q;
    burst_type_n = burst_type_q;
    burst_length_n = burst_length_q;
    total_length_n = total_length_q;

    unique case (state_q)
        IDLE: begin
            route_select_n = 1'b0;
            write_aw_done_n = 1'b0;
            state_n = (slv_req_i.aw_valid | slv_req_i.ar_valid) ? VERIFICATION : IDLE;
            transaction_allowed_n = 1'b0;
            aw_request_n = slv_req_i.aw_valid ? 1'b1 : 1'b0;
            ar_request_n = slv_req_i.aw_valid ? 1'b0 : slv_req_i.ar_valid ? 1'b1 : 1'b0;
            num_bytes_n = slv_req_i.aw_valid ? axi_pkg::num_bytes(slv_req_i.aw.size) : axi_pkg::num_bytes(slv_req_i.ar.size);
            addr_n = slv_req_i.aw_valid ? slv_req_i.aw.addr : slv_req_i.ar.addr;
            addr_to_check_n = addr_n;
            size_n = slv_req_i.aw_valid ? slv_req_i.aw.size : slv_req_i.ar.size;
            burst_type_n = slv_req_i.aw_valid ? slv_req_i.aw.burst : slv_req_i.ar.burst;
            burst_length_n = slv_req_i.aw_valid ? slv_req_i.aw.len : slv_req_i.ar.len;
            total_length_n = num_bytes_n * (burst_length_n + 1);
        end
        VERIFICATION: begin
            if (ready_i) begin
                transaction_en_o = 1'b1;
                state_n = WAIT_IOPMP;
            end
        end
        WAIT_IOPMP: begin
            if (valid_i) begin
                state_n = AXI_HANDSHAKE;
                route_select_n = iopmp_allow_transaction_i & bc_allow_request;
            end
            transaction_allowed_n = iopmp_allow_transaction_i & bc_allow_request;
        end
        AXI_HANDSHAKE: begin
            if (aw_request_q) begin
                if (!write_aw_done_q && slv_rsp_o.aw_ready)
                    write_aw_done_n = 1'b1;
                if (write_aw_done_q && slv_rsp_o.w_ready)
                    state_n = WAIT_B;
            end else if (ar_request_q && slv_rsp_o.ar_ready) begin
                state_n = IDLE;
            end
            if (state_n == IDLE && ar_request_q) begin
                route_select_n = 1'b0;
            end
        end
        WAIT_B: begin
            if (slv_rsp_o.b_valid && slv_req_i.b_ready)
                state_n = IDLE;
            route_select_n = route_select_q;
            if (state_n == IDLE && aw_request_q) begin
                route_select_n = 1'b0;
                write_aw_done_n = 1'b0;
            end
        end
        default: ;
    endcase
end

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        state_q <= IDLE;
        route_select_q <= 1'b0;
        write_aw_done_q <= 1'b0;
        transaction_allowed_q <= 1'b0;
        aw_request_q <= 1'b0;
        ar_request_q <= 1'b0;
        num_bytes_q <= '0;
        addr_q <= '0;
        addr_to_check_q <= '0;
        size_q <= '0;
        burst_type_q <= '0;
        burst_length_q <= '0;
        total_length_q <= '0;
    end else begin
        state_q <= state_n;
        route_select_q <= route_select_n;
        write_aw_done_q <= write_aw_done_n;
        transaction_allowed_q <= transaction_allowed_n;
        aw_request_q <= aw_request_n;
        ar_request_q <= ar_request_n;
        num_bytes_q <= num_bytes_n;
        addr_q <= addr_n;
        addr_to_check_q <= addr_to_check_n;
        size_q <= size_n;
        burst_type_q <= burst_type_n;
        burst_length_q <= burst_length_n;
        total_length_q <= total_length_n;
    end
end

rv_iopmp_axi4_bc i_rv_iopmp_axi4_bc (
    .request_i(aw_request_q | ar_request_q),
    .addr_i(addr_q),
    .burst_type_i(burst_type_q),
    .burst_length_i(burst_length_q),
    .n_bytes_i(size_q),
    .allow_request_o(bc_allow_request),
    .bound_violation_o(bc_bound_violation),
    .wrap_boundary_o(wrap_boundary)
);

axi_req_t error_req;
axi_rsp_t error_rsp;
axi_demux #(
    .AxiIdWidth(ID_WIDTH),
    .aw_chan_t(axi_aw_chan_t),
    .w_chan_t(axi_w_chan_t),
    .b_chan_t(axi_b_chan_t),
    .ar_chan_t(axi_ar_chan_t),
    .r_chan_t(axi_r_chan_t),
    .req_t(axi_req_t),
    .resp_t(axi_rsp_t),
    .NoMstPorts(2),
    .AxiLookBits(ID_WIDTH),
    .FallThrough(1'b0),
    .SpillAw(1'b0), .SpillW(1'b0), .SpillB(1'b0), .SpillAr(1'b0), .SpillR(1'b0)
) i_axi_demux (
    .clk_i, .rst_ni, .test_i(1'b0),
    .slv_aw_select_i(route_select_q),
    .slv_ar_select_i(route_select_q),
    .slv_req_i(axi_aux_req), .slv_resp_o(slv_rsp_o),
    .mst_reqs_o({mst_req_o, error_req}),
    .mst_resps_i({mst_rsp_i, error_rsp})
);

axi_err_slv #(
    .AxiIdWidth(ID_WIDTH), .req_t(axi_req_t), .resp_t(axi_rsp_t),
    .Resp(axi_pkg::RESP_SLVERR), .RespWidth(DATA_WIDTH),
    .RespData(64'hCA11AB1EBADCAB1E), .ATOPs(1'b1), .MaxTrans(1)
) i_axi_err_slv (
    .clk_i, .rst_ni, .test_i(1'b0),
    .slv_req_i(error_req), .slv_resp_o(error_rsp)
);

endmodule
