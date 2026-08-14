# Standalone build for M7 Phase C real-core reset tests
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(ROOT)../../..)
IBEX_SW := $(REPO)/third_party/ibex/examples/sw/simple_system/common
COMP := $(REPO)/m7/sw/ibex_composed
XPACK_GCC := $(REPO)/third_party/toolchain/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-gcc

GCC ?= $(XPACK_GCC)
ARCH ?= rv32imc_zicsr
ABI ?= ilp32
CFLAGS := -march=$(ARCH) -mabi=$(ABI) -static -mcmodel=medany -Wall -g -Os \
	-fvisibility=hidden -nostdlib -nostartfiles -ffreestanding
INCS := -I$(IBEX_SW)
LINKER_SCRIPT := $(IBEX_SW)/link.ld
CRT := $(IBEX_SW)/crt0.S

TESTS := 1 2 3 4 5 6 7 8 9 10 11 12
ELFS := $(foreach n,$(TESTS),RC-$(n).elf)

.PHONY: all clean
all: $(ELFS)

crt0.o: $(CRT)
	"$(GCC)" $(CFLAGS) $(INCS) -c -o $@ $<

m7_comp_common.o: $(COMP)/m7_comp_common.c
	"$(GCC)" $(CFLAGS) $(INCS) -c -o $@ $<

define ELF_RULE
RC-$(1).elf: ibex_reset_tests.c m7_rc_trap.c m7_comp_common.o crt0.o
	"$(GCC)" $(CFLAGS) $(INCS) -DTEST_NUM=$(1) -c -o ibex_reset_tests_$(1).o ibex_reset_tests.c
	"$(GCC)" $(CFLAGS) $(INCS) -c -o m7_rc_trap_$(1).o m7_rc_trap.c
	"$(GCC)" $(CFLAGS) -T $(LINKER_SCRIPT) crt0.o m7_comp_common.o ibex_reset_tests_$(1).o m7_rc_trap_$(1).o -o $$@
endef

$(foreach n,$(TESTS),$(eval $(call ELF_RULE,$(n))))

clean:
	rm -f $(ELFS) *.o
