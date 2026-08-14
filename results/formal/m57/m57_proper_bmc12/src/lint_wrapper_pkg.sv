// Yosys-compatible minimal lint_wrapper for M5.7 formal (no package-scoped types in structs).
`ifndef LINT_WRAPPER
`define LINT_WRAPPER
package lint_wrapper;
  localparam UserWidth  = 1;
  localparam AddrWidth  = 64;
  localparam DataWidth  = 64;
  localparam StrbWidth  = DataWidth / 8;
  localparam IdWidth    = 4;

  typedef logic [IdWidth-1:0] id_t;
  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [StrbWidth-1:0] strb_t;
  typedef logic [UserWidth-1:0] user_t;
  typedef logic [3:0] nsaid_t;
  typedef logic [7:0] len_t;
  typedef logic [2:0] size_t;
  typedef logic [1:0] burst_t;
  typedef logic [3:0] cache_t;
  typedef logic [2:0] prot_t;
  typedef logic [3:0] qos_t;
  typedef logic [3:0] region_t;
  typedef logic [5:0] atop_t;
  typedef logic [1:0] ax_resp_t;

  typedef struct packed {
    id_t id;
    addr_t addr;
    len_t len;
    size_t size;
    burst_t burst;
    logic lock;
    cache_t cache;
    prot_t prot;
    qos_t qos;
    region_t region;
    atop_t atop;
    user_t user;
    nsaid_t nsaid;
  } aw_chan_nsaid_t;

  typedef struct packed {
    data_t data;
    strb_t strb;
    logic last;
    user_t user;
  } w_chan_t;

  typedef struct packed {
    id_t id;
    ax_resp_t resp;
    user_t user;
  } b_chan_t;

  typedef struct packed {
    id_t id;
    addr_t addr;
    len_t len;
    size_t size;
    burst_t burst;
    logic lock;
    cache_t cache;
    prot_t prot;
    qos_t qos;
    region_t region;
    user_t user;
  } ar_chan_t;

  typedef struct packed {
    data_t data;
    ax_resp_t resp;
    logic last;
    user_t user;
  } r_chan_t;

  typedef aw_chan_nsaid_t aw_chan_t;

  typedef struct packed {
    aw_chan_nsaid_t aw;
    logic aw_valid;
    w_chan_t w;
    logic w_valid;
    logic b_ready;
    ar_chan_t ar;
    logic ar_valid;
    logic r_ready;
  } req_nsaid_t;

  typedef struct packed {
    logic aw_ready;
    logic w_ready;
    b_chan_t b;
    logic b_valid;
    logic ar_ready;
    r_chan_t r;
    logic r_valid;
  } resp_t;

  typedef struct packed {
    aw_chan_t aw;
    logic aw_valid;
    w_chan_t w;
    logic w_valid;
    logic b_ready;
    ar_chan_t ar;
    logic ar_valid;
    logic r_ready;
  } req_t;
endpackage
`endif
