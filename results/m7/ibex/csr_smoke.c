int main(void) {
  unsigned long v;
  __asm__ volatile("csrr %0, mhartid" : "=r"(v));
  return (int)v;
}
