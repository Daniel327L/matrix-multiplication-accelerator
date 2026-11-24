# ---------------------------------------------------------------
#  Makefile for the systolic-array accelerator
#
#  Usage:
#    make test_pe      build + run tb/tb_pe.sv
#    make wave_pe      run the test, then open its waveform in GTKWave
#    make lint_pe      lint-only check of module "pe" (fast, no sim)
#    make test         run every tb/tb_*.sv, stop at the first failure
#    make clean        delete all build output
#
#  Conventions this relies on:
#    - Testbench for X lives in tb/tb_X.sv, and its module is named tb_X
#    - The testbench dumps waves to build/tb_X.vcd:
#          $dumpfile("build/tb_X.vcd"); $dumpvars;
#    - The testbench ends with $fatal on any failure, $finish otherwise
#      (non-zero exit code is what lets `make test` stop on failure)
# ---------------------------------------------------------------

RTL   := $(wildcard rtl/*.sv)
BUILD := build
TESTS := $(patsubst tb/tb_%.sv,%,$(wildcard tb/tb_*.sv))

# --binary            build a runnable sim directly (no C++ harness to write)
# --timing            allow #delays / clock generation in testbenches
# --trace             enable $dumpfile/$dumpvars VCD output
# -Wall               all warnings; they are fatal by default, which is what we want
#                     (add -Wno-fatal temporarily if one blocks you while debugging)
# -j 0                compile the generated C++ on all CPU cores
# --timescale 1ns/1ps auto set the timescale for each testbench and rtl modules

VFLAGS := --binary --timing --trace -Wall -j 0 --timescale 1ns/1ps

.PHONY: test clean

# Build and run one testbench: make test_pe
test_%:
	@mkdir -p $(BUILD)
	verilator $(VFLAGS) --top-module tb_$* --Mdir $(BUILD)/tb_$* -o tb_$* \
		$(RTL) tb/tb_$*.sv
	./$(BUILD)/tb_$*/tb_$*

# Run the test, then open the waveform. If waves/tb_X.gtkw exists
# (a saved GTKWave layout: File > Write Save File), it's loaded too.
wave_%: test_%
	gtkwave $(BUILD)/tb_$*.vcd $(wildcard waves/tb_$*.gtkw) &

# Lint one RTL module without simulating: make lint_pe
lint_%:
	verilator --lint-only -Wall --top-module $* $(RTL)

# Run every testbench in tb/
test: $(addprefix test_,$(TESTS))
	@echo "=== ALL TESTS PASSED ==="

clean:
	rm -rf $(BUILD)