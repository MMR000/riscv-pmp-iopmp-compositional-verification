# Standalone build for M7 Ibex PMP tests
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
ELFS := $(foreach n,$(TESTS),IBEX-PMP-0$(n).elf)
PERF_ELFS := PERF-CPU-01.elf PERF-CPU-02.elf PERF-CPU-03.elf PERF-CPU-04.elf

.PHONY: all clean perf
all: $(ELFS)
	@echo "ARCH=$(ARCH)" > build_arch.txt
	@"$(GCC)" --version | head -1 >> build_arch.txt

perf: $(PERF_ELFS)

crt0.o: $(CRT)
	"$(GCC)" $(CFLAGS) $(INCS) -c -o $@ $<

m7_common.o: m7_simple_system_common.c
	"$(GCC)" $(CFLAGS) $(INCS) -c -o $@ $<

define ELF_RULE
IBEX-PMP-0$(1).elf: ibex_pmp_tests.c m7_pmp_trap.c m7_common.o crt0.o
	"$(GCC)" $(CFLAGS) $(INCS) -DTEST_NUM=$(1) -c -o ibex_pmp_tests_$(1).o ibex_pmp_tests.c
	"$(GCC)" $(CFLAGS) $(INCS) -c -o m7_pmp_trap_$(1).o m7_pmp_trap.c
	"$(GCC)" $(CFLAGS) -T $(LINKER_SCRIPT) crt0.o m7_common.o ibex_pmp_tests_$(1).o m7_pmp_trap_$(1).o -o $$@
endef

$(foreach n,$(TESTS),$(eval $(call ELF_RULE,$(n))))

define PERF_RULE
PERF-CPU-0$(1).elf: ibex_pmp_tests.c m7_pmp_trap.c m7_common.o crt0.o
	"$(GCC)" $(CFLAGS) $(INCS) -DTEST_NUM=10$(1) -DPERF_MEASURE -c -o ibex_pmp_tests_10$(1).o ibex_pmp_tests.c
	"$(GCC)" $(CFLAGS) $(INCS) -DPERF_MEASURE -c -o m7_pmp_trap_10$(1).o m7_pmp_trap.c
	"$(GCC)" $(CFLAGS) -T $(LINKER_SCRIPT) crt0.o m7_common.o ibex_pmp_tests_10$(1).o m7_pmp_trap_10$(1).o -o $$@
endef

$(foreach n,1 2 3 4,$(eval $(call PERF_RULE,$(n))))

clean:
	rm -f $(ELFS) $(PERF_ELFS) *.o ibex_pmp_tests_*.o m7_pmp_trap_*.o build_arch.txt
