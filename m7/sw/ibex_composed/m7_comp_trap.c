// Trap handler for composed IBEX-COMP tests.
#include "simple_system_common.h"

#define PROT_WORD   ((volatile uint32_t *)0x20000100u)
#define SYNC_HRESULT ((volatile uint32_t *)0x50000014u)

extern unsigned int get_mcause(void);
extern unsigned int get_mepc(void);
extern unsigned int get_mtval(void);
extern volatile uint32_t g_mem_after;

void simple_exc_handler(void) {
  unsigned cause = get_mcause();
  unsigned spins = 0;

  puts("M7-COMP-TRAP\n");
  puts("MCAUSE: 0x");
  puthex(cause);
  puts("\nMEPc: 0x");
  puthex(get_mepc());
  puts("\nMTVAL: 0x");
  puthex(get_mtval());
  putchar('\n');

  /* Allow concurrent DMA harness to finish before observing memory. */
  while (*SYNC_HRESULT == 0u && spins < 100000u)
    spins++;

  g_mem_after = *PROT_WORD;
  puts("MEM_AFTER: 0x");
  puthex(g_mem_after);
  putchar('\n');
  sim_halt();
}
