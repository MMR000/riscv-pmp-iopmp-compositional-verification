# Shared SKY130HD 10 ns primary constraint for M7 J0-J3.
# Clock port is `clk` on m7_ppa_j*_top (not official ibex_core clk_i).
current_design $::env(DESIGN_NAME)

set clk_name core_clock
set clk_port_name clk
if {[info exists ::env(CLOCK_PERIOD)] && $::env(CLOCK_PERIOD) ne ""} {
  set clk_period $::env(CLOCK_PERIOD)
} else {
  set clk_period 10.0
}
set clk_io_pct 0.2

set clk_port [get_ports $clk_port_name]

create_clock -name $clk_name -period $clk_period $clk_port
set clk_io_name vclk_$clk_name
create_clock -name $clk_io_name -period $clk_period
set_clock_latency 1.095 [get_clocks $clk_name]
set_clock_latency 1.095 [get_clocks $clk_io_name]

set non_clock_inputs [all_inputs -no_clocks]

set_input_delay [expr $clk_period * $clk_io_pct] -clock $clk_io_name $non_clock_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_io_name [all_outputs]
