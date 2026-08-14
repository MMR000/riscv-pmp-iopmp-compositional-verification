// M7 trap handler override for PMP tests (replaces simple_system_common.c handler at link).
#include "simple_system_common.h"

extern unsigned int get_mcause(void);
extern unsigned int get_mepc(void);
extern unsigned int get_mtval(void);
extern volatile uint32_t g_mem_before;
extern volatile uint32_t g_mem_after;
#ifdef PERF_MEASURE
extern volatile uint32_t g_cyc_req;
extern volatile uint32_t g_cyc_trap;
static unsigned int get_mcycle(void) {
  uint32_t r;
  __asm__ volatile("csrr %0, mcycle" : "=r"(r));
  return r;
}
#endif

void simple_exc_handler(void) {
  unsigned cause = get_mcause();
#ifdef PERF_MEASURE
  g_cyc_trap = get_mcycle();
#endif
  if (cause == 8u) {
    /* Environment call from U-mode — authorized-read success path (IBEX-PMP-06). */
    puts("M7-RESULT: PASS\n");
    sim_halt();
    return;
  }
  puts("M7-TRAP\n");
  puts("MCAUSE: 0x");
  puthex(get_mcause());
  puts("\nMEPc: 0x");
  puthex(get_mepc());
  puts("\nMTVAL: 0x");
  puthex(get_mtval());
  putchar('\n');
  g_mem_after = *(volatile uint32_t *)0x00180100u;
  puts("MEM_AFTER: 0x");
  puthex(g_mem_after);
  putchar('\n');
#ifdef PERF_MEASURE
  puts("M7-CYC-REQ: 0x");
  puthex(g_cyc_req);
  puts("\nM7-CYC-TRAP: 0x");
  puthex(g_cyc_trap);
  putchar('\n');
#endif
  sim_halt();
}
