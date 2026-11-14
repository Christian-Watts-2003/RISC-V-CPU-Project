BASYS3 INSTRUCTION TRACE WRAPPER

Top module
----------
basys3_trace_top

Sources
-------
- vivado/basys3_trace_top.v
- vivado/instruction_trace_uart_reporter.v
- vivado/uart_tx.v
- rtl/single_cycle/*.sv
- vivado/basys3_trace.xdc

Switch controls
---------------
sw[15] is the run/enable switch. When it is off, the CPU is paused.

The UART baud rate and CPU stepping rate are independent. Keep
UART_BAUD_DIV at 868 for 115200 baud with the 100 MHz Basys3 clock. To slow
instruction execution, set CPU_DIVIDER in basys3_trace_top; for example,
CPU_DIVIDER=10000000 permits one instruction step approximately every 0.1 s.
When it is on, one instruction executes only after the previous UART trace
line has completed.

The rightmost eight switches select fields in every trace line:

  sw[0] PC
  sw[1] instruction
  sw[2] data address
  sw[3] store data
  sw[4] cycle count
  sw[5] instruction count
  sw[6] store count
  sw[7] load data
  sw[8] expected test result

The selected fields are transmitted as hexadecimal values at 115200 baud,
8-N-1. For example:

  PC=00000000 INSTR=00000013 CYCLES=00000001 OP=OPIMM

When sw[8] is enabled, the self-checking test image reports
`RESULT=PASS` when it writes marker `600D600D` to data address 0, or
`RESULT=FAIL` when it writes marker `DEADFA11`. Other instructions show
`RESULT=----`.

The trace automatically appends an opcode-class label (`OP=LUI`, `OP=AUIPC`,
`OP=JAL`, `OP=JALR`, `OP=BRANCH`, `OP=LOAD`, `OP=STORE`, `OP=OPIMM`,
`OP=ALU`, or `OP=ILLEGAL`) to each line.

The RV32I image also assigns each check a test number. Passing checks emit
`TEST=PASS 00000001`-style events, and a failing check emits `TEST=FAIL`
with its test number before the overall `RESULT=FAIL` marker. Test events use
reserved data addresses `0x100` and `0x104` and are handled by the wrapper.

The instruction ROM is initialized from IMEM_FILE. The default path is the
existing Basys3 test image; set the parameter or manage the HEX file in the
Vivado project if the path differs on the host machine.

The LEDs display the low 16 bits of the current PC. The center button is a
synchronous reset.
