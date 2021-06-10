######################################################################
#
# This file ONLY is placed under the Creative Commons Public Domain, for
# any use, without warranty, 2020 by Wilson Snyder.
# SPDX-License-Identifier: CC0-1.0
#
######################################################################
# Check for sanity to avoid later confusion

ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

######################################################################
# Set up variables

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package install, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

ifneq ($(XLEN),)
VERILATOR_FLAGS += -DXLEN=$(XLEN)
endif

VERILATOR_TOP = top

# Generate C++ in executable form
VERILATOR_FLAGS += -cc --exe
# Generate makefile dependencies (not shown as complicates the Makefile)
#VERILATOR_FLAGS += -MMD
# Optimize
VERILATOR_FLAGS += -O3 --x-assign fast --x-initial fast --noassert
# Warn abount lint issues; may not want this on less solid designs
VERILATOR_FLAGS += -Wall -Wno-fatal
# Make waveforms
VERILATOR_FLAGS += --trace
# Check SystemVerilog assertions
#VERILATOR_FLAGS += --assert
# Generate coverage analysis
#VERILATOR_FLAGS += --coverage
# Run Verilator in debug mode
#VERILATOR_FLAGS += --debug
# Add this trace to get a backtrace in gdb
#VERILATOR_FLAGS += --gdbbt
# Setup top module
VERILATOR_FLAGS += --top-module $(VERILATOR_TOP)

# Input files for Verilator
VERILATOR_INPUT = -I../rtl ../rtl/*.v sim_main.cpp

######################################################################
default: build

build:
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)
	$(MAKE) -j -C obj_dir -f V$(VERILATOR_TOP).mk

run: build
	@rm -rf logs
	@mkdir -p logs
	obj_dir/V$(VERILATOR_TOP) +trace

coverage: run
	@rm -rf logs/annotated
	$(VERILATOR_COVERAGE) --annotate logs/annotated logs/coverage.dat

clean:
	-rm -rf obj_dir logs *.log *.dmp *.vpd coverage.dat core *.vcd *.out
