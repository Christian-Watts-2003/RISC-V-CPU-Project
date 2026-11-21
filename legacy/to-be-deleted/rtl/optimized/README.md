# Five-stage RV32IM implementation and optimization variants

This directory contains a separate pipelined experiment; the original single-cycle RTL remains unchanged.

## Variants

Compile `rtl/optimized/rv32im_pipeline.sv` with `rtl/pipeline/regfile.v`. It defines four top modules with the same external interface:

| Top module | Fetch pre-decode | OR-gated ALU/M-extension result selection |
|---|---:|---:|
| `rv32im_pipe_baseline` | No | No |
| `rv32im_pipe_predecode` | Yes | No |
| `rv32im_pipe_or_select` | No | Yes |
| `rv32im_pipe_predecode_or_select` | Yes | Yes |

All are five-stage IF/ID/EX/MEM/WB pipelines. `PREDECODE` moves control classification to the fetch side and registers the control bundle alongside the fetched instruction. The load-use interlock uses the decoded source-use information, holds PC and IF/ID, and injects one bubble into ID/EX. Taken branches and jumps flush younger fetched/decode work. The OR-select experiment changes only the ALU-versus-M-extension execution-result selection; it is intended to be equivalent to a mux when the enables are one-hot.

## Interface and memory assumptions

- Instruction memory is external and combinational: `instruction` must be the word addressed by the current `pc`.
- Data memory is external. `mem_addr` is a byte address; `mem_read_data` is the aligned 32-bit word at `mem_addr[31:2]` and is expected to be combinational for the MEM stage.
- Stores provide `mem_write_data` shifted into the addressed byte lanes and `mem_byte_enable` for SB/SH/SW. The external memory should apply writes on the active clock edge when `mem_write` is asserted.
- Loads implement LB/LH/LW/LBU/LHU. Misaligned accesses that cross a word boundary are not implemented.
- The current MulDiv arithmetic is combinational. It is functionally RV32M-oriented but DIV/REM may be a long critical path; a multi-cycle unit and stall/ready handshake are future work.

## Validation notes

This is a structural implementation intended for simulation and synthesis comparison, not a measured timing claim. Run the same instruction stream on each top and compare architectural register/memory effects. Measure timing/resource differences with the same FPGA part, constraints, and tool settings. This RTL has not yet been run through a simulator or synthesis tool; treat it as an initial implementation requiring lint and directed tests before relying on results.

Suggested directed tests: dependent ALU instructions, load followed immediately by ALU/store/branch, taken and untaken branches, JAL/JALR link and target behavior, all RV32M operations including divide-by-zero/overflow, byte/halfword loads and stores, and x0 writes.
