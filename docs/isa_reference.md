# RISC-V RV32I Instruction Set Reference
 
Complete reference for the RISC-V RV32I (32-bit base integer) instruction set architecture.
 
## Instruction Formats
 
All RISC-V instructions are 32 bits. Different instruction types use different field layouts optimized for each operation type.
 
### R-Type (Register-Register Operations)
 
Used for operations with two source registers and one destination register.
 
```
Bit positions: 31    25 24    20 19    15 14   12 11   7 6      0
               [funct7 | rs2  | rs1  | funct3 | rd   | opcode]
               
Field widths:  7 bits  5 bits 5 bits 3 bits  5 bits 7 bits
```
 
**Fields:**
- **opcode [6:0]** (7 bits): Operation code (0x33 for R-type arithmetic)
- **rd [11:7]** (5 bits): Destination register (where to store result)
- **funct3 [14:12]** (3 bits): Function code (distinguishes operations)
- **rs1 [19:15]** (5 bits): Source register 1 (first operand)
- **rs2 [24:20]** (5 bits): Source register 2 (second operand)
- **funct7 [31:25]** (7 bits): Function code extension (distinguishes ADD from SUB, etc.)
**Operations:** ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
 
**Example: ADD x3, x1, x2**
```
Add x1 and x2, store result in x3
 
Encoding:
- opcode = 0x33 (0110011)
- rd = 3 (00011)
- funct3 = 0x0 (000)
- rs1 = 1 (00001)
- rs2 = 2 (00010)
- funct7 = 0x00 (0000000)
 
Binary: 0000000 00010 00001 000 00011 0110011
Hex:     0x00208233
```
 
---
 
### I-Type (Immediate Operations)
 
Used for operations with one source register, immediate value, and one destination register.
 
```
Bit positions: 31         20 19    15 14   12 11   7 6      0
               [imm[11:0]  | rs1  | funct3 | rd   | opcode]
               
Field widths:  12 bits     5 bits 3 bits  5 bits 7 bits
```
 
**Fields:**
- **opcode [6:0]** (7 bits): Operation code (varies: 0x13 for arithmetic, 0x03 for load, etc.)
- **rd [11:7]** (5 bits): Destination register
- **funct3 [14:12]** (3 bits): Function code (distinguishes operations)
- **rs1 [19:15]** (5 bits): Source register (first operand)
- **imm [31:20]** (12 bits): Immediate value (sign-extended to 32 bits)
**Operations (Arithmetic):** ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
 
**Operations (Load):** LW, LH, LB, LHU, LBU
 
**Operations (Jump):** JALR
 
**Example: ADDI x1, x2, 100**
```
Add immediate 100 to x2, store in x1
 
Encoding:
- opcode = 0x13 (0010011)
- rd = 1 (00001)
- funct3 = 0x0 (000)
- rs1 = 2 (00010)
- imm = 100 (0000 0110 0100)
 
Binary: 000001100100 00010 000 00001 0010011
Hex:     0x06410093
```
 
**Example: LW x1, 4(x2)**
```
Load word from memory at address (x2 + 4) into x1
 
Encoding:
- opcode = 0x03 (0000011)
- rd = 1 (00001)
- funct3 = 0x2 (010, for 32-bit word)
- rs1 = 2 (00010)
- imm = 4 (0000 0000 0100)
 
Binary: 000000000100 00010 010 00001 0000011
Hex:     0x00412083
```
 
---
 
### S-Type (Store Operations)
 
Used for storing data to memory. The immediate is split into two parts to make room for both rs1 and rs2 fields.
 
```
Bit positions: 31    25 24    20 19    15 14   12 11   7 6      0
               [imm[11:5] | rs2  | rs1  | funct3 | imm[4:0] | opcode]
               
Field widths:  7 bits     5 bits 5 bits 3 bits  5 bits     7 bits
```
 
**Fields:**
- **opcode [6:0]** (7 bits): Operation code (0x23 for store)
- **imm [11:7]** (5 bits): Immediate bits [4:0] (lower 5 bits of offset)
- **funct3 [14:12]** (3 bits): Function code (SW=0x2, SH=0x1, SB=0x0)
- **rs1 [19:15]** (5 bits): Base address register
- **rs2 [24:20]** (5 bits): Source register (data to store)
- **imm [31:25]** (7 bits): Immediate bits [11:5] (upper 7 bits of offset)
**Reconstructed immediate:** {imm[11:5], imm[4:0]} = 12-bit signed offset
 
**Operations:** SW (store word), SH (store halfword), SB (store byte)
 
**Example: SW x2, 8(x1)**
```
Store x2 to memory at address (x1 + 8)
 
Offset 8 in binary: 0000 0000 1000
Split:
- imm[11:5] = 0000001
- imm[4:0]  = 01000
 
Encoding:
- opcode = 0x23 (0100011)
- imm[4:0] = 01000 (bits 11:7)
- funct3 = 0x2 (010, for 32-bit word)
- rs1 = 1 (00001)
- rs2 = 2 (00010)
- imm[11:5] = 0000001 (bits 31:25)
 
Binary: 0000001 00010 00001 010 01000 0100011
Hex:     0x00212423
```
 
---
 
### B-Type (Branch Operations)
 
Used for conditional branching. The immediate is split and shifted left by 1 (for 2-byte alignment).
 
```
Bit positions: 31 30    25 24    20 19    15 14   12 11   8 7 6      0
               [imm[12]|imm[10:5]| rs2  | rs1  | funct3 |imm[4:1]|imm[11]|opcode]
               
Field widths:  1 bit   6 bits   5 bits  5 bits 3 bits   4 bits  1 bit 7 bits
```
 
**Fields:**
- **opcode [6:0]** (7 bits): Operation code (0x63 for branch)
- **imm [11]** (1 bit): Immediate bit 11
- **imm [4:1]** (4 bits): Immediate bits [4:1]
- **funct3 [14:12]** (3 bits): Function code (BEQ=0x0, BNE=0x1, BLT=0x4, BGE=0x5, etc.)
- **rs1 [19:15]** (5 bits): First compare register
- **rs2 [24:20]** (5 bits): Second compare register
- **imm [10:5]** (6 bits): Immediate bits [10:5]
- **imm [12]** (1 bit): Immediate bit 12 (sign bit)
**Reconstructed immediate:** {imm[12], imm[11], imm[10:5], imm[4:1]} << 1 = 13-bit signed offset in 2-byte increments
 
**Operations:** BEQ, BNE, BLT, BGE, BLTU, BGEU
 
**Example: BEQ x1, x2, +8**
```
Branch to PC+8 if x1 == x2
 
Offset 8 needs to be shifted: 8 >> 1 = 4
4 in binary: 0000 0100
After reconstruction: 0000 0100 << 1 = 8
 
Split:
- imm[12]   = 0
- imm[11]   = 0
- imm[10:5] = 000001
- imm[4:1]  = 0100
 
Encoding:
- opcode = 0x63 (1100011)
- imm[11] = 0 (bit 7)
- imm[4:1] = 0100 (bits 11:8)
- funct3 = 0x0 (000, for BEQ)
- rs1 = 1 (00001)
- rs2 = 2 (00010)
- imm[10:5] = 000001 (bits 30:25)
- imm[12] = 0 (bit 31)
 
Binary: 0 000001 00010 00001 000 0100 0 1100011
Hex:     0x00208463
```
 
---
 
### U-Type (Upper Immediate)
 
Used to load a 20-bit immediate into the upper 20 bits of a register. Lower 12 bits are zeroed.
 
```
Bit positions: 31         12 11   7 6      0
               [imm[31:12] | rd   | opcode]
               
Field widths:  20 bits     5 bits 7 bits
```
 
**Fields:**
- **opcode [6:0]** (7 bits): Operation code (0x37 for LUI, 0x17 for AUIPC)
- **rd [11:7]** (5 bits): Destination register
- **imm [31:12]** (20 bits): Immediate value (placed in bits [31:12] of result)
**Operations:** LUI (Load Upper Immediate), AUIPC (Add Upper Immediate to PC)
 
**Example: LUI x1, 0x12345**
```
Load 0x12345 into upper 20 bits of x1
 
Result: x1 = 0x12345000
 
Encoding:
- opcode = 0x37 (0110111)
- rd = 1 (00001)
- imm = 0x12345 (0001 0010 0011 0100 0101)
 
Binary: 00010010001101000101 00001 0110111
Hex:     0x12345037
```
 
---
 
### J-Type (Jump and Link)
 
Used for unconditional jumps with link register update. The immediate is split and shifted left by 1.
 
```
Bit positions: 31 30    21 20 19    12 11   7 6      0
               [imm[20]|imm[10:1]|imm[11]|imm[19:12]| rd | opcode]
               
Field widths:  1 bit   10 bits    1 bit  8 bits     5 bits 7 bits
```
 
**Fields:**
- **opcode [6:0]** (7 bits): Operation code (0x6F for JAL)
- **rd [11:7]** (5 bits): Destination register (return address)
- **imm [19:12]** (8 bits): Immediate bits [19:12]
- **imm [11]** (1 bit): Immediate bit 11
- **imm [10:1]** (10 bits): Immediate bits [10:1]
- **imm [20]** (1 bit): Immediate bit 20 (sign bit)
**Reconstructed immediate:** {imm[20], imm[19:12], imm[11], imm[10:1]} << 1 = 21-bit signed offset in 2-byte increments
 
**Operations:** JAL (Jump and Link)
 
**Example: JAL x1, +100**
```
Jump to PC+100, save return address (PC+4) in x1
 
Offset 100 needs to be shifted: 100 >> 1 = 50
50 in binary: 0000 110010
 
Split (in weird order):
- imm[20]    = 0
- imm[19:12] = 0000 0000
- imm[11]    = 0
- imm[10:1]  = 0011 0010
 
Encoding:
- opcode = 0x6F (1101111)
- rd = 1 (00001)
- imm[19:12] = 00000000 (bits 19:12)
- imm[11] = 0 (bit 20)
- imm[10:1] = 0011 0010 (bits 30:21)
- imm[20] = 0 (bit 31)
 
Binary: 0 0011001000 0 00000000 00001 1101111
Hex:     0x06400067
```
 
---
 
## Complete Instruction Encodings
 
### Arithmetic Operations (R-Type, opcode=0x33)
 
| Instruction | funct7 | funct3 | Description |
|-------------|--------|--------|-------------|
| ADD | 0x00 | 0x0 | rd = rs1 + rs2 |
| SUB | 0x20 | 0x0 | rd = rs1 - rs2 |
| SLL | 0x00 | 0x1 | rd = rs1 << rs2[4:0] (shift left logical) |
| SLT | 0x00 | 0x2 | rd = (rs1 < rs2 signed) ? 1 : 0 |
| SLTU | 0x00 | 0x3 | rd = (rs1 < rs2 unsigned) ? 1 : 0 |
| XOR | 0x00 | 0x4 | rd = rs1 ^ rs2 |
| SRL | 0x00 | 0x5 | rd = rs1 >> rs2[4:0] (shift right logical) |
| SRA | 0x20 | 0x5 | rd = rs1 >>> rs2[4:0] (shift right arithmetic, sign-extends) |
| OR | 0x00 | 0x6 | rd = rs1 \| rs2 |
| AND | 0x00 | 0x7 | rd = rs1 & rs2 |
 
### Arithmetic Immediate (I-Type, opcode=0x13)
 
| Instruction | funct3 | Description |
|-------------|--------|-------------|
| ADDI | 0x0 | rd = rs1 + sign_ext(imm[11:0]) |
| SLTI | 0x2 | rd = (rs1 < sign_ext(imm)) ? 1 : 0 |
| SLTIU | 0x3 | rd = (rs1 < sign_ext(imm) unsigned) ? 1 : 0 |
| XORI | 0x4 | rd = rs1 ^ sign_ext(imm[11:0]) |
| ORI | 0x6 | rd = rs1 \| sign_ext(imm[11:0]) |
| ANDI | 0x7 | rd = rs1 & sign_ext(imm[11:0]) |
| SLLI | 0x1 | rd = rs1 << imm[4:0] (funct7=0x00) |
| SRLI | 0x5 | rd = rs1 >> imm[4:0] (logical, funct7=0x00) |
| SRAI | 0x5 | rd = rs1 >>> imm[4:0] (arithmetic, funct7=0x20) |
 
### Load (I-Type, opcode=0x03)
 
| Instruction | funct3 | Description |
|-------------|--------|-------------|
| LW | 0x2 | rd = mem[rs1 + sign_ext(imm)] (32-bit, signed) |
| LH | 0x1 | rd = mem[rs1 + sign_ext(imm)] (16-bit, sign-extended) |
| LB | 0x0 | rd = mem[rs1 + sign_ext(imm)] (8-bit, sign-extended) |
| LHU | 0x5 | rd = mem[rs1 + sign_ext(imm)] (16-bit, zero-extended) |
| LBU | 0x4 | rd = mem[rs1 + sign_ext(imm)] (8-bit, zero-extended) |
 
### Store (S-Type, opcode=0x23)
 
| Instruction | funct3 | Description |
|-------------|--------|-------------|
| SW | 0x2 | mem[rs1 + sign_ext(imm)] = rs2 (32-bit word) |
| SH | 0x1 | mem[rs1 + sign_ext(imm)] = rs2[15:0] (16-bit halfword) |
| SB | 0x0 | mem[rs1 + sign_ext(imm)] = rs2[7:0] (8-bit byte) |
 
### Branch (B-Type, opcode=0x63)
 
| Instruction | funct3 | Description |
|-------------|--------|-------------|
| BEQ | 0x0 | Branch if rs1 == rs2 |
| BNE | 0x1 | Branch if rs1 != rs2 |
| BLT | 0x4 | Branch if rs1 < rs2 (signed) |
| BGE | 0x5 | Branch if rs1 >= rs2 (signed) |
| BLTU | 0x6 | Branch if rs1 < rs2 (unsigned) |
| BGEU | 0x7 | Branch if rs1 >= rs2 (unsigned) |
 
### Jump and Link (J-Type, opcode=0x6F)
 
| Instruction | Description |
|-------------|-------------|
| JAL | Jump to PC + sign_ext(imm), save return address (PC+4) in rd |
 
### Jump and Link Register (I-Type, opcode=0x67)
 
| Instruction | funct3 | Description |
|-------------|--------|-------------|
| JALR | 0x0 | Jump to (rs1 + sign_ext(imm)), save return address in rd |
 
### Upper Immediate
 
| Instruction | opcode | Description |
|-------------|--------|-------------|
| LUI | 0x37 | rd = imm[31:12] << 12 (load upper immediate) |
| AUIPC | 0x17 | rd = PC + (imm[31:12] << 12) (add upper immediate to PC) |
 
---
 
## Register Conventions
 
### RISC-V Registers (x0-x31)
 
| Register | ABI Name | Purpose | Preserved? |
|----------|----------|---------|-----------|
| x0 | zero | Always zero (hardwired) | N/A |
| x1 | ra | Return address | Caller |
| x2 | sp | Stack pointer | Callee |
| x3 | gp | Global pointer | - |
| x4 | tp | Thread pointer | - |
| x5-x7 | t0-t2 | Temporary | Caller |
| x8 | s0/fp | Saved/Frame pointer | Callee |
| x9 | s1 | Saved register | Callee |
| x10-x11 | a0-a1 | Arguments/Return values | Caller |
| x12-x17 | a2-a7 | Arguments | Caller |
| x18-x27 | s2-s11 | Saved registers | Callee |
| x28-x31 | t3-t6 | Temporary | Caller |
 
**Preserved by Caller (Caller-saved):** x5-x7, x10-x17, x28-x31  
**Preserved by Callee (Callee-saved):** x8, x9, x18-x27
 
---
 
## Immediate Value Handling
 
### Sign Extension
 
All immediate values in RISC-V are **sign-extended** to 32 bits unless otherwise specified.
 
**Example:** ADDI with imm = 0xFFF (12 bits, all ones)
```
12-bit value:  1111 1111 1111
Sign bit:      1 (negative)
Sign-extended: 1111 1111 1111 1111 1111 1111 1111 1111 (32 bits) = -1
Result:        rd = rs1 + (-1)
```
 
### Shift Left Operations
 
Branch (B-type) and Jump (J-type) immediates are **shifted left by 1** because targets are always 2-byte (word) aligned:
 
```
Branch offset 8 (bytes):
- Shifted: 8 >> 1 = 4
- Stored in imm field: 4
- CPU shifts back: 4 << 1 = 8
- Result: PC += 8 (to 2-byte boundary)
```
 
---
 
## Quick Reference: Common Instructions
 
### Arithmetic
```asm
ADD x1, x2, x3       # x1 = x2 + x3
ADDI x1, x2, 100     # x1 = x2 + 100
SUB x1, x2, x3       # x1 = x2 - x3
```
 
### Logic
```asm
AND x1, x2, x3       # x1 = x2 & x3
ANDI x1, x2, 0xFF    # x1 = x2 & 0xFF
OR x1, x2, x3        # x1 = x2 | x3
ORI x1, x2, 0x0F     # x1 = x2 | 0x0F
XOR x1, x2, x3       # x1 = x2 ^ x3
XORI x1, x2, -1      # x1 = x2 ^ -1 (bitwise NOT)
```
 
### Shifts
```asm
SLL x1, x2, x3       # x1 = x2 << x3
SLLI x1, x2, 4       # x1 = x2 << 4
SRL x1, x2, x3       # x1 = x2 >> x3 (logical, zero-fill)
SRLI x1, x2, 4       # x1 = x2 >> 4 (logical)
SRA x1, x2, x3       # x1 = x2 >>> x3 (arithmetic, sign-extend)
SRAI x1, x2, 4       # x1 = x2 >>> 4 (arithmetic)
```
 
### Comparison
```asm
SLT x1, x2, x3       # x1 = (x2 < x3 signed) ? 1 : 0
SLTI x1, x2, 100     # x1 = (x2 < 100 signed) ? 1 : 0
SLTU x1, x2, x3      # x1 = (x2 < x3 unsigned) ? 1 : 0
SLTIU x1, x2, 100    # x1 = (x2 < 100 unsigned) ? 1 : 0
```
 
### Load/Store
```asm
LW x1, 4(x2)         # x1 = mem[x2+4] (word, 32-bit)
LH x1, 2(x2)         # x1 = mem[x2+2] (halfword, signed)
LB x1, 1(x2)         # x1 = mem[x2+1] (byte, signed)
LHU x1, 2(x2)        # x1 = mem[x2+2] (halfword, unsigned)
LBU x1, 1(x2)        # x1 = mem[x2+1] (byte, unsigned)
 
SW x1, 4(x2)         # mem[x2+4] = x1 (word)
SH x1, 2(x2)         # mem[x2+2] = x1 (halfword)
SB x1, 1(x2)         # mem[x2+1] = x1 (byte)
```
 
### Branch
```asm
BEQ x1, x2, label    # If x1 == x2, jump to label
BNE x1, x2, label    # If x1 != x2, jump to label
BLT x1, x2, label    # If x1 < x2 (signed), jump
BGE x1, x2, label    # If x1 >= x2 (signed), jump
BLTU x1, x2, label   # If x1 < x2 (unsigned), jump
BGEU x1, x2, label   # If x1 >= x2 (unsigned), jump
```
 
### Jump
```asm
JAL x1, label        # Jump to label, save return address (PC+4) in x1
JALR x1, 0(x2)       # Jump to x2, save return address in x1
```
 
### Upper Immediate
```asm
LUI x1, 0x12345      # x1 = 0x12345000 (load upper 20 bits)
AUIPC x1, 0x12345    # x1 = PC + 0x12345000
```
 
---
 
## Opcode Map (Summary)
 
| Opcode | Type | Instructions |
|--------|------|--------------|
| 0x03 | I | Load (LW, LH, LB, LHU, LBU) |
| 0x13 | I | Arithmetic Immediate (ADDI, SLTI, etc.) |
| 0x17 | U | AUIPC |
| 0x23 | S | Store (SW, SH, SB) |
| 0x33 | R | Arithmetic (ADD, SUB, AND, etc.) |
| 0x37 | U | LUI |
| 0x63 | B | Branch (BEQ, BNE, BLT, etc.) |
| 0x67 | I | JALR |
| 0x6F | J | JAL |
 
---
 
## References
 
- [RISC-V Specification v2.2](https://riscv.org/technical/specifications/)
- [Unprivileged ISA Specification](https://github.com/riscv/riscv-isa-manual/releases)
- RISC-V Tools and Simulator: [riscv-tools GitHub](https://github.com/riscv/riscv-tools)
 
