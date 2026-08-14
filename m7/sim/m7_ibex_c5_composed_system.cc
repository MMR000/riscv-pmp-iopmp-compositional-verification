#include <iostream>

#include "m7_ibex_c5_composed_system.h"
#include "verilator_sim_ctrl.h"

M7ResetComposedSystem::M7ResetComposedSystem()
    : _ram("TOP.m7_ibex_c5_composed_top.u_ram.u_ram", kRAM_SizeBytes / 4, 4) {}

int M7ResetComposedSystem::Main(int argc, char **argv) {
  VerilatorSimCtrl &simctrl = VerilatorSimCtrl::GetInstance();

  simctrl.SetTop(&_top, &_top.IO_CLK, &_top.IO_RST_N,
                 VerilatorSimCtrlFlags::ResetPolarityNegative);

  _memutil.RegisterMemoryArea("ram", kRAM_BaseAddr, &_ram);
  simctrl.RegisterExtension(&_memutil);

  bool exit_app = false;
  bool good_cmdline = simctrl.ParseCommandArgs(argc, argv, exit_app);
  if (!good_cmdline || exit_app) {
    return exit_app ? 0 : 1;
  }

  std::cout << "M7 Ibex C5 composed simulation" << std::endl;
  simctrl.RunSimulation();
  return simctrl.WasSimulationSuccessful() ? 0 : 1;
}
