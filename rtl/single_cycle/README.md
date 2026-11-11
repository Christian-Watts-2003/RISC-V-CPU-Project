# Single-cycle RV32IM backup

This folder is the maintained, isolated single-cycle implementation. It is intentionally separate from `rtl/pipeline/` and from the preserved originals in `rtl/` and `rtl/single_cycle_reference/`. Compile only files in this directory together; these modules reuse common names such as `alu`, `regfile`, and `imm_gen`.

## Supported behavior

The decoder implements RV32I `LUI`, `AUIPC`, `JAL`, `JALR`, all six conditional branches, `LB/LH/LW/LBU/LHU`, `SB/SH/SW`, immediate ALU operations (`ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI`), register ALU operations (`ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND`), and RV32M (`MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU`). `FENCE`, `ECALL`, `EBREAK`, and illegal encodings behave as NOPs.

Data memory returns an aligned 32-bit word combinationally; the LSU selects lanes and extends loads. Stores present lane-shifted data and byte strobes for synchronous byte writes. Misaligned halfword/word accesses and accesses crossing a word boundary are unsupported. RV32M is combinational (including divide/remainder), so timing closure may require a very conservative clock or a later iterative unit.

`top` includes behavioral memories for simulation/FPGA-oriented use. For ASIC implementation, replace `memory.sv` with the target memory macros and constrain/verify the selected synthesis flow. This implementation has not yet been compiled, simulated, or synthesized in this change set; directed verification is the next step.
