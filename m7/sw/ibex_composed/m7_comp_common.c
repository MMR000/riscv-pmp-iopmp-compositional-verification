// M7 Phase B composed-system common helpers (no exception handler).
#include "simple_system_common.h"

int putchar(int c) {
  DEV_WRITE(SIM_CTRL_BASE + SIM_CTRL_OUT, (unsigned char)c);
  return c;
}

int puts(const char *str) {
  while (*str) putchar(*str++);
  return 0;
}

void puthex(uint32_t h) {
  for (int i = 0; i < 8; i++) {
    int d = h >> 28;
    putchar(d < 10 ? ('0' + d) : ('A' - 10 + d));
    h <<= 4;
  }
}

void sim_halt(void) { DEV_WRITE(SIM_CTRL_BASE + SIM_CTRL_CTRL, 1); }

unsigned int get_mepc(void) {
  uint32_t r;
  __asm__ volatile("csrr %0, mepc" : "=r"(r));
  return r;
}

unsigned int get_mcause(void) {
  uint32_t r;
  __asm__ volatile("csrr %0, mcause" : "=r"(r));
  return r;
}

unsigned int get_mtval(void) {
  uint32_t r;
  __asm__ volatile("csrr %0, mtval" : "=r"(r));
  return r;
}

void timer_enable(uint64_t time_base) { (void)time_base; }
void timer_disable(void) {}
uint64_t timer_read(void) { return 0; }
void timecmp_update(uint64_t new_time) { (void)new_time; }
uint64_t get_elapsed_time(void) { return 0; }
void simple_timer_handler(void) {}
