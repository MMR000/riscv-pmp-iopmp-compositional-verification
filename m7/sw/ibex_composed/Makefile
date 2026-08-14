# Standalone build for M7 Ibex composed (Phase B) tests
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(ROOT)../../..)
IBEX_SW := $(REPO)/third_party/ibex/examples/sw/simple_system/common
XPACK_GCC := $(REPO)/third_party/toolchain/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-gcc

GCC ?= $(XPACK_GCC)
ARCH ?= rv32imc_zicsr
ABI ?= ilp32
CFLAGS := -march=$(ARCH) -mabi=$(ABI) -static -mcmodel=medany -Wall -g -Os \
	-fvisibility=hidden -nostdlib -nostartfiles -ffreestanding
INCS := -I$(IBEX_SW)
LINKER_SCRIPT := $(IBEX_SW)/link.ld
CRT := $(IBEX_SW)/crt0.S

TESTS := 1 2 3 4 5 6 7 8
ELFS := $(foreach n,$(TESTS),IBEX-COMP-0$(n).elf)

.PHONY: all clean
all: $(ELFS)
	@echo "ARCH=$(ARCH)" > build_arch.txt
	@"$(GCC)" --version | head -1 >> build_arch.txt

crt0.o: $(CRT)
	"$(GCC)" $(CFLAGS) $(INCS) -c -o $@ $<

m7_comp_common.o: m7_comp_common.c
	"$(GCC)" $(CFLAGS) $(INCS) -c -o $@ $<

define ELF_RULE
IBEX-COMP-0$(1).elf: ibex_composed_tests.c m7_comp_trap.c m7_comp_common.o crt0.o
	"$(GCC)" $(CFLAGS) $(INCS) -DTEST_NUM=$(1) -c -o ibex_composed_tests_$(1).o ibex_composed_tests.c
	"$(GCC)" $(CFLAGS) $(INCS) -c -o m7_comp_trap_$(1).o m7_comp_trap.c
	"$(GCC)" $(CFLAGS) -T $(LINKER_SCRIPT) crt0.o m7_comp_common.o ibex_composed_tests_$(1).o m7_comp_trap_$(1).o -o $$@
endef

$(foreach n,$(TESTS),$(eval $(call ELF_RULE,$(n))))

clean:
	rm -f $(ELFS) *.o ibex_composed_tests_*.o m7_comp_trap_*.o build_arch.txt
