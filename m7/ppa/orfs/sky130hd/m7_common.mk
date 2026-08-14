# Shared ORFS settings for M7 J0-J3 SKY130HD primary comparison.
# Sourced from per-variant config.mk. Do not edit official designs/sky130hd/ibex.

export PLATFORM = sky130hd
M7_ORFS := /repo/m7/ppa/orfs

export VERILOG_FILES = $(shell grep -vE '^#|^$$' $(M7_ORFS)/filelists/$(M7_VARIANT).orfs.files)
export VERILOG_INCLUDE_DIRS = \
  /repo/rtl/common \
  /repo/m7/rtl \
  /repo/m7/ppa/rtl \
  /repo/third_party/ibex/vendor/lowrisc_ip/ip/prim/rtl \
  /repo/third_party/ibex/vendor/lowrisc_ip/ip/prim_generic/rtl \
  /repo/third_party/ibex/vendor/lowrisc_ip/dv/sv/dv_utils \
  /repo/third_party/ibex/syn/rtl \
  /repo/third_party/ibex/shared/rtl

export SYNTH_HDL_FRONTEND = slang
export SDC_FILE = $(M7_ORFS)/sky130hd/constraint.sdc

export ADDER_MAP_FILE :=

# Match validated official sky130hd/ibex physical methodology.
export CORE_UTILIZATION = 50
export PLACE_DENSITY_LB_ADDON = 0.25
export TNS_END_PERCENT = 100
export FASTROUTE_TCL = $(M7_ORFS)/sky130hd/fastroute.tcl
export REMOVE_ABC_BUFFERS = 1
export CTS_CLUSTER_SIZE = 20
export CTS_CLUSTER_DIAMETER = 50
export SWAP_ARITH_OPERATORS = 1
export OPENROAD_HIERARCHICAL = 1

# Host Kepler-formal is AVX-512; identical omission for every variant.
export LEC_CHECK = 0

# Primary comparison is 10.0 ns. Sweep overrides CLOCK_PERIOD on the make command line.
# ABC_CLOCK_PERIOD_IN_PS must be numeric; do not parse Tcl from constraint.sdc.
export CLOCK_PERIOD ?= 10.0
export ABC_CLOCK_PERIOD_IN_PS = $(CLOCK_PERIOD)
