// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2017 by Wilson Snyder.
// SPDX-License-Identifier: CC0-1.0
//======================================================================

// For std::unique_ptr
#include <memory>

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vtop.h"

#if VM_TRACE
# include <verilated_vcd_c.h>	// Trace file format header
#endif

// Legacy function required only so linking works on Cygwin and MSVC++
static uint64_t trace_count = 0;
double sc_time_stamp() { return trace_count; }

int main(int argc, char** argv, char** env) {
    // This is a more complicated example, please also see the simpler examples/make_hello_c.

    // Prevent unused variable warnings
    if (false && argc && argv && env) {}

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs argument parsing
    Verilated::debug(0);

    // Randomization reset policy
    // May be overridden by commandArgs argument parsing
    Verilated::randReset(2);

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    Verilated::commandArgs(argc, argv);

    // Construct the Verilated model, from Vtop.h generated from Verilating "top.v".
    // Using unique_ptr is similar to "Vtop* top = new Vtop" then deleting at end.
    // "TOP" will be the hierarchical name of the module.
    const std::unique_ptr<Vtop> top{new Vtop{}};

#if VM_TRACE    // If verilator was invoked with --trace
    // Verilator must compute traced signals
    Verilated::traceEverOn(true);
    std::unique_ptr<VerilatedVcdC> tfp(new VerilatedVcdC());
    top->trace(tfp.get(), 4);	// Trace 4 levels of hierarchy
    tfp->open("dump.vcd");	    // Open the dump file
#endif

    // Set Vtop's input signals
    top->clock = 1;
    top->reset = 0;
    top->eval();

    top->clock = 0;
    top->reset = 1;
    top->eval();

    top->clock = 1;
    top->reset = 1;
    top->eval();

    top->clock = 0;
    top->reset = 0;
    top->eval();

    // Simulate until $finish
    while (!Verilated::gotFinish()) {
        // Historical note, before Verilator 4.200 Verilated::gotFinish()
        // was used above in place of contextp->gotFinish().
        // Most of the contextp-> calls can use Verilated:: calls instead;
        // the Verilated:: versions simply assume there's a single context
        // being used (per thread).  It's faster and clearer to use the
        // newer contextp-> versions.

        //Verilated::timeInc(1);  // 1 timeprecision period passes...
        // Historical note, before Verilator 4.200 a sc_time_stamp()
        // function was required instead of using timeInc.  Once timeInc()
        // is called (with non-zero), the Verilated libraries assume the
        // new API, and sc_time_stamp() will no longer work.

        // Evaluate model
        // (If you have multiple models being simulated in the same
        // timestep then instead of eval(), call eval_step() on each, then
        // eval_end_step() on each. See the manual.)
        top->clock = 1;
        top->eval();
#if VM_TRACE
	    tfp->dump(2 * trace_count);	// Create waveform trace for this timestamp
#endif
        top->clock = 0;
        top->eval();
#if VM_TRACE
	    tfp->dump(2 * trace_count + 1);	// Create waveform trace for this timestamp
#endif
        ++trace_count;
    }

    // Final model cleanup
    top->final();
#if VM_TRACE
    tfp->close();
#endif

    // Coverage analysis (calling write only after the test is known to pass)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    //Verilated::coveragep()->write("logs/coverage.dat");
#endif

    // Return good completion status
    // Don't use exit() or destructor won't get called
    return 0;
}
