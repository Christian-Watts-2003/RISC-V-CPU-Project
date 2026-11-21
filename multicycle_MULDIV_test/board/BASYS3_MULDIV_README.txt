Basys3 multi-cycle RV32M experiment
==================================

Vivado design sources, relative to multicycle_MULDIV_test:

  rtl/rv32im_multicycle.sv
  rtl/controller.sv
  rtl/imm_gen.sv
  rtl/alu.sv
  rtl/branch_unit.sv
  rtl/lsu.sv
  rtl/regfile.sv
  rtl/muldiv.sv
  board/basys3_muldiv_top.v
  board/instruction_trace_uart_reporter.v
  board/uart_tx.v

Set basys3_muldiv_top as the synthesis top. Add board/basys3_trace.xdc as
the constraints source for synthesis and implementation. It assigns Basys3
clock, button, switch, LED, and UART pins and constrains clk to 10 ns
(100 MHz). It declares the static buttons/switches and asynchronous
LED/UART outputs false paths; internal register-to-register paths remain
timed. Review those exceptions if the I/O environment changes.

The default IMEM_FILE is sim/test_programs/basys3_muldiv.hex relative to
this project directory. For Vivado, set the parameter to an absolute path
to that file if necessary and add the HEX as a memory initialization source.
The image includes all eight RV32M instructions and checks divide-by-zero
and signed overflow; it emits per-test events and overall PASS/FAIL markers.
Regenerate it with python sim/test_programs/generate_basys3_muldiv.py.

btnC resets the CPU; sw[15] enables it. sw[8] enables RESULT on UART;
TEST and OP fields are always emitted. TEST=PASS/FAIL reports the test ID;
RESULT=PASS/FAIL indicates the overall marker. RV32M instructions are
currently labeled OP=ALU by the shared opcode-class reporter. UART defaults
to 115200 baud, 8-N-1. CPU_DIVIDER defaults to 1.

After synthesis and implementation, inspect timing summary, worst setup
path, unconstrained paths, and utilization. The 10 ns constraint is a
target, not evidence that timing is met. Compare against the original using
the same part, clock, XDC, tool settings, and comparable board setup; a
different ROM image can affect optimization and resource results. Examine
whether the synthesized MulDiv is present. No synthesis or timing report
is supplied with this experiment.
