Basys3 RV32I edge-case image
==============================

Input image:
  basys3_rv32i_edgecase.hex

The image exercises the maintained single-cycle RV32I subset:
LUI, AUIPC, JAL, JALR, all six conditional branches, byte/halfword/word
loads and stores, signed and unsigned loads, all OP-IMM and register ALU operations, x0 behavior, and an unsupported
encoding.

The program is self-checking. It branches to a failure loop on the first
incorrect result. It writes one of these markers to data memory address 0:

  0x600D600D  PASS
  0xDEADFA11  FAIL

For the Basys3 wrapper, set:

  DEBUG_MODE = 0
  PERF_LIMIT = 1000
  IMEM_FILE = "sim/test_programs/basys3_rv32i_edgecase.hex"

After the run, set sw[3:0] to 7 to display the final marker through dmem_rdata.
The UART report remains useful for confirming that the run reached its limit,
but it does not transmit the marker value.
