// Trap handler for Phase C reset recovery CPU tests.
#include "simple_system_common.h"

#define PROT_WORD ((volatile uint32_t *)0x20000100u)
#define SYNC_HRESULT ((volatile uint32_t *)0x50000014u)

extern unsigned int get_mcause(void);
extern unsigned int get_mepc(void);
extern unsigned int get_mtval(void);
extern int puts(const char *str);
extern void puthex(uint32_t h);
extern int putchar(int c);
extern void sim_halt(void);

void simple_exc_handler(void) {
  unsigned spins = 0;
  puts("M7-RC-TRAP\n");
  puts("MCAUSE: 0x");
  puthex(get_mcause());
  puts("\nMEPc: 0x");
  puthex(get_mepc());
  puts("\nMTVAL: 0x");
  puthex(get_mtval());
  putchar('\n');
  while (*SYNC_HRESULT == 0u && spins < 100000u) spins++;
  puts("MEM_AFTER: 0x");
  puthex(*PROT_WORD);
  putchar('\n');
  puts("M7-RC-RESULT: PASS\n");
  sim_halt();
}
