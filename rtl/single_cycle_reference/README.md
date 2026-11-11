# Single-cycle reference RTL

This directory preserves the original single-cycle processor sources as a reference while the five-stage RV32IM rewrite is developed in `rtl/`.

The archived sources intentionally retain their original module names. Do not compile this directory together with the new pipeline RTL: modules such as `alu`, `regfile`, and `imm_gen` are reused by the pipeline and have different implementation requirements in the specification. The archived memory includes simulation-oriented initialization and is not suitable for the specified synthesis RTL rules.
