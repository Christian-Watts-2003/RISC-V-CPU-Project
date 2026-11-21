Basys3 RV32I edge-case image
==============================

Input image:
  basys3_rv32i_edgecase.hex

The image exercises the current multi-cycle RV32I subset:
LUI, AUIPC, JAL, JALR, all six conditional branches, byte/halfword/word
loads and stores, signed and unsigned loads, all OP-IMM and register ALU operations, x0 behavior, and an unsupported
encoding.

The program is self-checking. It branches to a failure loop on the first
incorrect result. It writes one of these markers to data memory address 0:

  0x600D600D  PASS
  0xDEADFA11  FAIL

For the multi-cycle Basys3 trace wrapper, set IMEM_FILE to this image's
absolute path. The default image tests RV32M instead.
Set sw[15] to run; sw[8] enables the UART RESULT field. The wrapper also
reports test events over UART. See ../../board/BASYS3_MULDIV_README.txt.
