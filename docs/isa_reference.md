# RISC-V RV32I Instruction Set Reference

## Instruction Formats

### R-Type (Register-Register)

31    25 24    20 19    15 14   12 11   7 6      0

[funct7 | rs2  | rs1  | funct3 | rd   | opcode]

31         20 19    15 14   12 11   7 6      0

[imm[11:0]  | rs1  | funct3 | rd   | opcode]

Operations: ADDI, ANDI, ORI, XORI, SLTI, LW, LH, LB

### S-Type (Store)
31    25 24    20 19    15 14   12 11   7 6      0

[imm[11:5] | rs2  | rs1  | funct3 | imm[4:0] | opcode]

Operations: SW, SH, SB

### B-Type (Branch)
31 30   25 24    20 19    15 14   12 11 8  7 6      0

[imm[12] | imm[10:5] | rs2  | rs1  | funct3 | imm[4:1] | imm[11] | opcode]

Operations: BEQ, BNE, BLT, BGE, BLTU, BGEU

### U-Type (Upper Immediate)
31         12 11   7 6      0

[imm[31:12] | rd   | opcode]

Operations: LUI, AUIPC

### J-Type (Jump)
31    20 19    15 14   12 11   7 6      0

[imm[20] | imm[10:1] | imm[11] | imm[19:12] | rd | opcode]

Operations: JAL

## Instruction Encodings (Opcodes)

| Instruction | Opcode | funct3 | funct7 |
|-------------|--------|--------|--------|
| ADD, SUB    | 0x33   | 0x0    | 0x00/0x20 |
| AND         | 0x33   | 0x7    | 0x00   |
| OR          | 0x33   | 0x6    | 0x00   |
| ... | ... | ... | ... |

See RISC-V spec for complete table.
