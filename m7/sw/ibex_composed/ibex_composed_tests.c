// M7 Phase B IBEX-COMP-01..08 — real Ibex architectural PMP + DMA/IOPMP sync.
#include "simple_system_common.h"

#define IBEX_RAM_BASE     0x00100000u
#define NORMAL_SRAM_BASE  0x10000000u
#define PROTECT_SRAM_BASE 0x20000000u
#define TEST_SYNC_BASE    0x50000000u

#define PROT_WORD   ((volatile uint32_t *)(PROTECT_SRAM_BASE + 0x100u))
#define SYNC_READY  ((volatile uint32_t *)(TEST_SYNC_BASE + 0x00u))
#define SYNC_GO     ((volatile uint32_t *)(TEST_SYNC_BASE + 0x04u))
#define SYNC_HRESULT ((volatile uint32_t *)(TEST_SYNC_BASE + 0x14u))

#define CPU_VAL_COMP07 0xCAFE0007u
#define CPU_VAL_COMP08 0xB0080008u
#define CPU_VAL_COMP01 0xB0010001u

volatile uint32_t g_mem_before;
volatile uint32_t g_mem_after;

#ifndef TEST_NUM
#define TEST_NUM 0
#endif

static inline void pmp_napot_cfg(unsigned idx, void *addr, unsigned size_bytes,
                                 uint8_t cfg) {
  uint32_t napot = ((uint32_t)addr >> 2) | ((size_bytes >> 3) - 1u);
  uint32_t cfg_val;
  switch (idx) {
  case 0:
    asm volatile("csrw pmpaddr0, %0" ::"r"(napot));
    asm volatile("csrr %0, pmpcfg0" : "=r"(cfg_val));
    cfg_val = (cfg_val & ~0xFFu) | cfg;
    asm volatile("csrw pmpcfg0, %0" ::"r"(cfg_val));
    break;
  case 1:
    asm volatile("csrw pmpaddr1, %0" ::"r"(napot));
    asm volatile("csrr %0, pmpcfg0" : "=r"(cfg_val));
    cfg_val = (cfg_val & ~0xFF00u) | ((uint32_t)cfg << 8);
    asm volatile("csrw pmpcfg0, %0" ::"r"(cfg_val));
    break;
  case 2:
    asm volatile("csrw pmpaddr2, %0" ::"r"(napot));
    asm volatile("csrr %0, pmpcfg0" : "=r"(cfg_val));
    cfg_val = (cfg_val & ~0xFF0000u) | ((uint32_t)cfg << 16);
    asm volatile("csrw pmpcfg0, %0" ::"r"(cfg_val));
    break;
  default:
    break;
  }
  asm volatile("fence" ::: "memory");
}

static void report_pass(void) {
  g_mem_after = *PROT_WORD;
  puts("MEM_AFTER: 0x");
  puthex(g_mem_after);
  putchar('\n');
  puts("M7-COMP-RESULT: PASS\n");
  sim_halt();
}

static void report_fail(void) {
  g_mem_after = *PROT_WORD;
  puts("MEM_AFTER: 0x");
  puthex(g_mem_after);
  putchar('\n');
  puts("M7-COMP-RESULT: FAIL\n");
  sim_halt();
}

static void wait_go(void) {
  while (*SYNC_GO == 0u) {
  }
}

static void wait_harness(void) {
  while (*SYNC_HRESULT == 0u) {
  }
}

static void drop_to_umode(void (*fn)(void)) {
  /* Stack inside Ibex boot RAM region covered by PMP R0. */
  uint32_t sp = IBEX_RAM_BASE + 0x4000u - 16u;
  uint32_t umode = 0x00001800u;
  asm volatile("csrc mstatus, %0\n"
               "mv sp, %1\n"
               "csrw mepc, %2\n"
               "mret\n"
               :
               : "r"(umode), "r"(sp), "r"(fn)
               : "memory");
}

static void umode_read_prot(void) {
  volatile uint32_t v = *PROT_WORD;
  (void)v;
}

static void umode_write_prot(void) {
  *PROT_WORD = CPU_VAL_COMP07;
}

static void setup_pmp_regions(void) {
  /* R0: 16KiB boot/code RAM at 0x00100000 RWX */
  pmp_napot_cfg(0, (void *)IBEX_RAM_BASE, 0x4000u, 0x1F);
  /* R1: 64KiB normal shared SRAM at 0x10000000 RWX */
  pmp_napot_cfg(1, (void *)NORMAL_SRAM_BASE, 0x10000u, 0x1F);
  /* R2: 64KiB protected SRAM at 0x20000000 — no U-mode R/W/X */
  pmp_napot_cfg(2, (void *)PROTECT_SRAM_BASE, 0x10000u, 0x18);
}

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;

  setup_pmp_regions();

  *PROT_WORD = 0x22222222u;
  g_mem_before = *PROT_WORD;

  switch (TEST_NUM) {
  case 1: /* IBEX-COMP-01 M-mode trusted write */
    *PROT_WORD = CPU_VAL_COMP01;
    report_pass();
    break;

  case 2: /* IBEX-COMP-02 U-mode protected read -> load fault */
    *SYNC_READY = 2u;
    wait_go();
    drop_to_umode(umode_read_prot);
    report_fail();
    break;

  case 3: /* IBEX-COMP-03 U-mode protected write -> store fault */
    *SYNC_READY = 3u;
    wait_go();
    drop_to_umode(umode_write_prot);
    report_fail();
    break;

  case 4: /* IBEX-COMP-04 unauthorized DMA write (CPU idle) */
    *SYNC_READY = 4u;
    wait_harness();
    report_pass();
    break;

  case 5: /* IBEX-COMP-05 authorized DMA write */
    *SYNC_READY = 5u;
    wait_harness();
    report_pass();
    break;

  case 6: /* IBEX-COMP-06 dual unauthorized write */
    *SYNC_READY = 6u;
    wait_go();
    drop_to_umode(umode_write_prot);
    report_fail();
    break;

  case 7: /* IBEX-COMP-07 unauthorized CPU + authorized DMA */
    *SYNC_READY = 7u;
    wait_go();
    drop_to_umode(umode_write_prot);
    report_fail();
    break;

  case 8: /* IBEX-COMP-08 authorized CPU + unauthorized DMA */
    *SYNC_READY = 8u;
    wait_go();
    *PROT_WORD = CPU_VAL_COMP08;
    report_pass();
    break;

  default:
    report_fail();
  }
  return 1;
}
