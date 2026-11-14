# Single-cycle backup: first end-to-end test

`Single Cycle TBs/single_cycle_tb.sv` builds a small instruction program directly with RV32I encoders and checks register and memory results after execution. It covers byte/halfword/word memory operations, signed and unsigned loads, immediate/register arithmetic and comparisons, branch and jump links/targets, multiply high variants, and divide/remainder corner cases.

Run from any directory with `bash scripts/test_single_cycle.sh` after installing Icarus Verilog. The script compiles only `rtl/single_cycle/` sources to avoid duplicate module names from the pipeline and archived RTL.

This test is the beginning of directed integration verification, not full ISA certification. It has not yet been executed in this environment; the first local/CI run may expose testbench or RTL issues to resolve.
