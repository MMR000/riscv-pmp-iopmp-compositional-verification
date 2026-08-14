#include "verilated_toplevel.h"
#include "verilator_memutil.h"

class M7ResetComposedSystem {
 public:
  static constexpr uint32_t kRAM_BaseAddr = 0x100000u;
  static constexpr uint32_t kRAM_SizeBytes = 0x100000u;

  M7ResetComposedSystem();
  int Main(int argc, char **argv);

 private:
  m7_ibex_reset_composed_top _top;
  VerilatorMemUtil _memutil;
  MemArea _ram;
};
