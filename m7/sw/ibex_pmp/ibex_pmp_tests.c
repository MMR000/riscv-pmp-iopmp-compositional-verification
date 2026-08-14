// M7 Ibex architectural PMP tests — real CSR configuration, no software emulation.
#include "simple_system_common.h"

#define RAM_BASE     0x00100000u
#define NORMAL_BASE  0x00101000u
#define PROTECT_BASE 0x00180000u

static volatile uint32_t *const normal_word = (uint32_t *)(NORMAL_BASE + 0x100);
static volatile uint32_t *const prot_word   = (uint32_t *)(PROTECT_BASE + 0x100);
static volatile uint32_t *const prot_last   = (uint32_t *)(PROTECT_BASE + 0x1000u - 4u);

volatile uint32_t g_mem_before;
volatile uint32_t g_mem_after;
#if TEST_NUM >= 101
volatile uint32_t g_cyc_req;
volatile uint32_t g_cyc_trap;
#endif

#ifndef TEST_NUM
#define TEST_NUM 0
#endif

static inline void pmp_napot_cfg(unsigned idx, void *addr, unsigned size_bytes, uint8_t cfg) {
  uint32_t napot = ((uint32_t)addr >> 2) | ((size_bytes >> 3) - 1u);
  uint32_t cfg_val;
  switch (idx) {
    case 0:
      asm volatile("csrw pmpaddr0, %0" :: "r"(napot));
      asm volatile("csrr %0, pmpcfg0" : "=r"(cfg_val));
      cfg_val = (cfg_val & ~0xFFu) | cfg;
      asm volatile("csrw pmpcfg0, %0" :: "r"(cfg_val));
      break;
    case 1:
      asm volatile("csrw pmpaddr1, %0" :: "r"(napot));
      asm volatile("csrr %0, pmpcfg0" : "=r"(cfg_val));
      cfg_val = (cfg_val & ~0xFF00u) | ((uint32_t)cfg << 8);
      asm volatile("csrw pmpcfg0, %0" :: "r"(cfg_val));
      break;
    default:
      break;
  }
  asm volatile("fence" ::: "memory");
}

static void report_pass(void) {
  puts("M7-RESULT: PASS\n");
  sim_halt();
}

static void report_fail(void) {
  puts("M7-RESULT: FAIL\n");
  sim_halt();
}

static void drop_to_umode(void (*fn)(void)) {
  /* Stack must lie inside a U-mode-accessible PMP region (link.ld stack is outside). */
  uint32_t sp = RAM_BASE + 0x4000u - 16u;
  uint32_t umode = 0x00001800u; /* clear MPP -> U-mode */
  asm volatile(
      "csrc mstatus, %0\n"
      "mv sp, %1\n"
      "csrw mepc, %2\n"
      "mret\n"
      :
      : "r"(umode), "r"(sp), "r"(fn)
      : "memory");
}

static void umode_read_normal(void) {
  volatile uint32_t v = *normal_word;
  (void)v;
  asm volatile("ecall");
}

static void umode_read_prot(void) {
  volatile uint32_t v = *prot_word;
  (void)v;
}

static void umode_write_prot(void) {
  *prot_word = 0xDEADBEEFu;
}

static void umode_read_prot_last(void) {
  volatile uint32_t v = *prot_last;
  (void)v;
}

#if TEST_NUM >= 101
static unsigned int get_mcycle(void) {
  uint32_t r;
  __asm__ volatile("csrr %0, mcycle" : "=r"(r));
  return r;
}

static unsigned int get_cycle_u(void) {
  uint32_t r;
  /* U-mode must use unprivileged cycle (0xC00), not mcycle. */
  __asm__ volatile("csrr %0, 0xC00" : "=r"(r));
  return r;
}

static void umode_read_prot_timed(void) {
  g_cyc_req = get_cycle_u();
  volatile uint32_t v = *prot_word;
  (void)v;
}

static void umode_write_prot_timed(void) {
  g_cyc_req = get_cycle_u();
  *prot_word = 0xDEADBEEFu;
}

static void enable_ucycle(void) {
  unsigned inhibit = 0;
  unsigned cenv = 1u;
  __asm__ volatile("csrw 0x320, %0" :: "r"(inhibit));
  __asm__ volatile("csrw 0x306, %0" :: "r"(cenv));
}

static void report_cyc_pair(uint32_t t0, uint32_t t1) {
  puts("M7-CYC-REQ: 0x");
  puthex(t0);
  puts("\nM7-CYC-DONE: 0x");
  puthex(t1);
  puts("\nM7-CYC-DELTA: 0x");
  puthex(t1 - t0);
  putchar('\n');
}
#endif

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;

  *normal_word = 0x11111111u;
  *prot_word = 0x22222222u;
  g_mem_before = *prot_word;

  /* Region0: 16KiB NAPOT from RAM base — covers .text/.vectors and normal data (R|W|X) */
  pmp_napot_cfg(0, (void *)RAM_BASE, 0x4000u, 0x1F);
  /* Region1: 4KiB protected — default no access (U-mode subject to PMP) */
  pmp_napot_cfg(1, (void *)PROTECT_BASE, 0x1000u, 0x18); /* NAPOT, no R/W/X */

  switch (TEST_NUM) {
  case 1: /* IBEX-PMP-01 M-mode write normal */
    *normal_word = 0xAAAA0001u;
    report_pass();
    break;
  case 2: /* IBEX-PMP-02 M-mode read normal */
    if (*normal_word == 0xAAAA0001u || *normal_word == 0x11111111u)
      report_pass();
    report_fail();
    break;
  case 3: /* IBEX-PMP-03 M-mode PMP CSR setup */
    report_pass();
    break;
  case 4: /* IBEX-PMP-04 U-mode protected read -> load fault */
    drop_to_umode(umode_read_prot);
    report_fail(); /* should not reach */
    break;
  case 5: /* IBEX-PMP-05 U-mode protected write -> store fault, mem unchanged */
    drop_to_umode(umode_write_prot);
    if (*prot_word == g_mem_before)
      report_pass();
    report_fail();
    break;
  case 6: /* IBEX-PMP-06 U-mode authorized normal read */
    drop_to_umode(umode_read_normal);
    report_pass();
    break;
  case 7: /* IBEX-PMP-07 boundary protected read -> load fault */
    drop_to_umode(umode_read_prot_last);
    report_fail();
    break;
  case 8: /* IBEX-PMP-08 M-mode reconfig then protected write */
    pmp_napot_cfg(1, (void *)PROTECT_BASE, 0x1000u, 0x1F);
    *prot_word = 0x33333333u;
    report_pass();
    break;
#if TEST_NUM >= 101
  case 101: /* PERF-CPU-01 M-mode authorized protected load */
    enable_ucycle();
    {
      uint32_t t0 = get_mcycle();
      volatile uint32_t v = *prot_word;
      uint32_t t1 = get_mcycle();
      (void)v;
      report_cyc_pair(t0, t1);
    }
    report_pass();
    break;
  case 102: /* PERF-CPU-02 M-mode authorized protected store */
    enable_ucycle();
    {
      uint32_t t0 = get_mcycle();
      *prot_word = 0xA11D0002u;
      uint32_t t1 = get_mcycle();
      report_cyc_pair(t0, t1);
    }
    report_pass();
    break;
  case 103: /* PERF-CPU-03 U-mode denied protected load, mcause=5 */
    enable_ucycle();
    drop_to_umode(umode_read_prot_timed);
    report_fail();
    break;
  case 104: /* PERF-CPU-04 U-mode denied protected store, mcause=7 */
    enable_ucycle();
    drop_to_umode(umode_write_prot_timed);
    report_fail();
    break;
#endif
  default:
    report_fail();
  }
  return 1;
}
