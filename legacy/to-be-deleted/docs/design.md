# RISC-V CPU Design Documentation

## Overview

This document describes the architecture of the RISC-V RV32I single-cycle processor.

## Phase 1: Component Design

### ALU (Arithmetic Logic Unit)

**Status:** In Development

The ALU is the computational core of the processor. It supports the following operations:

| Operation | Code | Example |
|-----------|------|---------|
| ADD       | 0000 | 5 + 3 = 8 |
| SUB       | 0001 | 10 - 3 = 7 |
| AND       | 0010 | 0xFF & 0x0F = 0x0F |
| OR        | 0011 | 0xFF \| 0x00 = 0xFF |
| XOR       | 0100 | 0xFF ^ 0x0F = 0xF0 |
| SLT       | 0101 | (5 < 10) = 1 |
| SLL       | 0110 | 1 << 4 = 16 |
| SRL       | 0111 | 16 >> 2 = 4 |
| SRA       | 1000 | -8 >>> 2 = -2 |

**Input Signals:**
- `a [31:0]` - First operand
- `b [31:0]` - Second operand
- `alu_op [3:0]` - Operation selector

**Output Signals:**
- `result [31:0]` - ALU result
- `zero` - Flag indicating result == 0

**Implementation Notes:**
- Uses case statement for operation selection
- Handles two's complement arithmetic correctly
- Includes overflow detection for SLT
- Masks shift amounts to [4:0] for safety

### Register File

**Status:** Planned

32 × 32-bit registers with 2 read ports and 1 write port.

### Instruction Memory

**Status:** Planned

### Data Memory

**Status:** Planned

## Testing Strategy

Each component is tested independently before integration:

1. ALU testbench verifies all operations
2. Register file testbench verifies read/write
3. Integration tests verify datapath

See [sim/](../sim/) for testbenches.
