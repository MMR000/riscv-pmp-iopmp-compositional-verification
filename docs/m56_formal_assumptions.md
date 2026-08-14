# M5.6 formal assumptions

## M56-FA-01 Single outstanding write

At most one write transaction in the data abstractor FSM at a time (matches upstream FSM).

## M56-FA-02 Stable AW under valid&&!ready

AW address/ID/nsaid stable while `aw_valid && !aw_ready`.

## M56-FA-03 Stable W under valid&&!ready

W data/strb/last stable while `w_valid && !w_ready`.

## M56-FA-04 Single-beat writes in harness

Directed/regression harness uses `len=0`, `w.last=1`.

## M56-FA-05 IOPMP decision latency bounded

`valid_i` arrives within 16 cycles of entering WAIT_IOPMP (simulation and abstract formal model).

## M56-FA-06 Legal B response

Downstream returns B within finite time when W handshake completes on authorized path.

## M56-FA-07 No concurrent AR during write repair FSM

Read transactions use separate FSM path; harness does not overlap AR with active write FSM states under test.

## M56-FA-08 Formal model scope

F-WP-* properties on `formal_m56_write_path_tb.sv` verify the **abstract transaction-binding model**, not full `axi_demux` RTL. Full RTL evidence comes from simulation campaigns.

## M56-FA-09 Reset synchronous deassert

Reset deasserts synchronously; no X on route_select after reset.
