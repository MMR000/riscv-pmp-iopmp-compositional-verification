export DESIGN_NICKNAME = m7_j3
export DESIGN_NAME = m7_ppa_j3_top
M7_VARIANT = J3
include /repo/m7/ppa/orfs/sky130hd/m7_common.mk
# Fail-closed RST-B in security_config.v (J3 only).
export VERILOG_DEFINES += -D RST_B
