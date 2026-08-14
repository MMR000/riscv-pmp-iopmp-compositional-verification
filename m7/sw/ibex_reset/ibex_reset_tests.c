// M7 Phase C recovery firmware: PMP init + PMP_READY + RC-04..08/12 CPU ops.
#include "simple_system_common.h"

#define IBEX_RAM_BASE     0x00100000u
#define NORMAL_SRAM_BASE  0x10000000u
#define PROTECT_SRAM_BASE 0x20000000u
#define TEST_SYNC_BASE    0x50000000u
#define PROT_WORD   ((volatile uint32_t *)(PROTECT_SRAM_BASE + 0x100u))
#define SYNC_READY  ((volatile uint32_t *)(TEST_SYNC_BASE + 0x00u))
#define SYNC_GO     ((volatile uint32_t *)(TEST_SYNC_BASE + 0x04u))
#define SYNC_HRESULT ((volatile uint32_t *)(TEST_SYNC_BASE + 0x14u))
#define SYNC_PMP_READY ((volatile uint32_t *)(TEST_SYNC_BASE + 0x28u))

#ifndef TEST_NUM
#define TEST_NUM 4
#endif

extern int putchar(int c);
extern int puts(const char *str);
extern void puthex(uint32_t h);
extern void sim_halt(void);
extern unsigned int get_mcause(void);
extern unsigned int get_mepc(void);
extern unsigned int get_mtval(void);

static void pmp_napot_cfg(unsigned idx, void *addr, unsigned size_bytes, uint8_t cfg) {
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

static void setup_pmp(void) {
  pmp_napot_cfg(0, (void *)IBEX_RAM_BASE, 0x4000u, 0x1F);
  pmp_napot_cfg(1, (void *)NORMAL_SRAM_BASE, 0x10000u, 0x1F);
  pmp_napot_cfg(2, (void *)PROTECT_SRAM_BASE, 0x10000u, 0x18);
}

static void drop_to_umode(void (*fn)(void)) {
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

static void umode_read(void) {
  volatile uint32_t v = *PROT_WORD;
  (void)v;
}
static void umode_write(void) {
  *PROT_WORD = 0xCAFE00C5u;
}

static void wait_go(void) {
  while (*SYNC_GO == 0u) {
  }
}

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;
  setup_pmp();
  *SYNC_PMP_READY = 1u; /* firmware milestone, not Ibex HW */

  switch (TEST_NUM) {
  case 4: /* RC-04 authorized M write after recovery */
    wait_go();
    *PROT_WORD = 0xB0040004u;
    puts("MEM_AFTER: 0x");
    puthex(*PROT_WORD);
    puts("\nM7-RC-RESULT: PASS\n");
    sim_halt();
    break;
  case 5: /* RC-05 U store fault */
    wait_go();
    drop_to_umode(umode_write);
    puts("M7-RC-RESULT: FAIL\n");
    sim_halt();
    break;
  case 6: /* RC-06 U load fault */
    wait_go();
    drop_to_umode(umode_read);
    puts("M7-RC-RESULT: FAIL\n");
    sim_halt();
    break;
  case 7: /* RC-07 authorized DMA observed by CPU */
  case 8: /* RC-08 unauthorized DMA */
    wait_go();
    while (*SYNC_HRESULT == 0u) {
    }
    puts("MEM_AFTER: 0x");
    puthex(*PROT_WORD);
    putchar('\n');
    puts("M7-RC-RESULT: PASS\n");
    sim_halt();
    break;
  case 12: /* RC-12 attribution: U write + auth DMA */
    wait_go();
    drop_to_umode(umode_write);
    puts("M7-RC-RESULT: FAIL\n");
    sim_halt();
    break;
  default:
    /* RC-01..03/09..11: CPU may be held; if we run, just halt quietly */
    puts("M7-RC-RESULT: IDLE\n");
    sim_halt();
    break;
  }
  return 1;
}
