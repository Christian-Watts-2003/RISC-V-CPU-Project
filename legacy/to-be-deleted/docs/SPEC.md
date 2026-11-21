# RV32IM Five-Stage Pipeline Specification

## 1. Purpose and experiment

Implement three processors from one codebase and compare area, power, and best closed clock period using Cadence Genus synthesis and Innovus. Measure IPC in simulation.

| Configuration | Top module | `PREDECODE` | `OR_SELECT` |
|---|---|---:|---:|
| Baseline | `rv32im_base` | 0 | 0 |
| Pre-decode | `rv32im_predec` | 1 | 0 |
| OR select | `rv32im_orsel` | 0 | 1 |

The combined pre-decode + OR-select configuration is omitted to reduce scope. This is a pipeline rewrite. Adapt earlier student modules only if available; do not assume they exist.

## 2. Decision log

| # | Decision | Value | Status |
|---|---|---|---|
| 1 | ISA | RV32IM, no CSR or exceptions | Paper |
| 2 | Pipeline | IF, ID, EX, MEM, WB | Paper |
| 3 | Pre-decode | Fetch-unit block; result passes through IF/ID | Paper |
| 4 | OR select | Replace execution-unit result mux with one-hot masking and OR | Paper |
| 5 | Multiply | Operands and result registered | Paper |
| 6 | Divide | Iterative radix-2, pipeline stalls until done | Paper |
| 7 | Forwarding | EX/MEM to EX and MEM/WB to EX | Default |
| 8 | Branches/jumps | Stall fetch until resolved in EX; same rule in all configs | Chosen |
| 9 | Load-use rule | Compare instruction rs1 and rs2 fields whether used or not; ignore rd=x0 | Chosen; x0 detail default |
| 10 | Load-use cost | One stall cycle in all configs | Default |
| 11 | Reset | Synchronous, active-high | Default |
| 12 | Memory | External; combinational read, synchronous write | Default |
| 13 | Register file | Write-through bypass during read/write collision | Default |
| 14 | RTL language | Plain Verilog-2001 | Default; verify tool support |
| 15 | Verification | Hand-written programs and hand-computed expected values | Chosen |
| 16 | OR-select scope | Execution-unit result selection only | Default |

## 3. Tool-flow constraints

The tutorial flow reads one `.v` file per run; each file name must match its top module name. Generate `rv32im_base.v`, `rv32im_predec.v`, and `rv32im_orsel.v`. Each file contains every synthesizable RTL module plus a small wrapper instantiating `rv32im_core` with the corresponding parameters. Do not include testbenches, `timescale`, or `include` directives in synthesis files. Instruction/data memories are external (testbench models only); the 31 writable registers plus hardwired x0 are inside the core.

## 4. Core interface and memory model

`rv32im_core` ports:

| Port | Direction | Width | Description |
|---|---|---:|---|
| `clk` | input | 1 | Rising-edge clock |
| `rst` | input | 1 | Synchronous active-high reset |
| `imem_addr` | output | 32 | Fetch address / PC |
| `imem_rdata` | input | 32 | Combinational instruction at fetch address |
| `dmem_addr` | output | 32 | Data address; word accesses use `[31:2]` |
| `dmem_wdata` | output | 32 | Store word, shifted into byte lanes |
| `dmem_wstrb` | output | 4 | Byte strobes, zero unless storing |
| `dmem_re` | output | 1 | Data read request |
| `dmem_rdata` | input | 32 | Full aligned 32-bit word, combinationally returned |

Reset PC is `0x00000000`; writes occur on the clock edge. Misaligned accesses are unsupported and untested. The core performs byte-lane selection and sign/zero extension for LB/LH/LBU/LHU. State that combinational memory read delay is excluded when reporting frequency.

## 5. ISA subset and NOP behavior

Implement: `LUI AUIPC JAL JALR BEQ BNE BLT BGE BLTU BGEU LB LH LW LBU LHU SB SH SW ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI ADD SUB SLL SLT SLTU XOR SRL SRA OR AND`, plus `MUL MULH MULHSU MULHU DIV DIVU REM REMU`.

`FENCE`, `ECALL`, `EBREAK`, and illegal encodings act as NOPs. Opcodes: LOAD `0000011`, STORE `0100011`, BRANCH `1100011`, JALR `1100111`, JAL `1101111`, OP-IMM `0010011`, OP `0110011`, LUI `0110111`, AUIPC `0010111`, MISC-MEM `0001111`, SYSTEM `1110011`. M-extension is OP with `funct7=0000001`. Shift amount is `[4:0]`; JALR clears target bit 0.

M corner cases: divide by zero returns all ones for DIV/DIVU and the dividend for REM/REMU. Signed overflow `-2^31 / -1` returns `-2^31` for DIV and zero for REM.

## 6. Microarchitecture

### 6.1 Pipeline stages and registers

Five stages: IF, ID, EX, MEM, WB; stage registers IF/ID, ID/EX, EX/MEM, MEM/WB. Each has a valid bit so bubbles do not retire. Reset clears valid/control bits and PC; data fields need not reset.

### 6.2 Fetch

PC drives `imem_addr`; normal flow advances by four. Capture `imem_rdata` and its PC into IF/ID.

### 6.3 Decode, register file, immediates

Decode generates ALU operation, operand source (register, immediate, PC, zero), branch/jump type, memory read/write/size/signedness, register-write enable, writeback source, execution-unit select, and mul/div start/op. The register file has 32 x 32-bit registers, two combinational read ports, and a WB write port. x0 reads zero and ignores writes. A read colliding with a write returns the new value (write-through). Immediate generator supports I/S/B/U/J formats.

### 6.4 Execute

ALU implements add, sub, and, or, xor, sll, srl, sra, slt, sltu. LUI uses operand A=0; AUIPC uses operand A=PC. Loads/stores use ALU for address calculation. Branch unit compares forwarded rs1/rs2. Branch/JAL target is PC+imm; JALR target is `(rs1+imm)&~1`; link is PC+4. Result candidates are ALU, mul/div, and link.

### 6.5 Forwarding

EX operand forwarding priority:
1. EX/MEM result if its instruction writes a register, rd != 0, and it is not a load.
2. MEM/WB writeback value (including load data).
3. Register-file output.

Apply forwarding to store data and branch operands as well as ordinary EX operands.

### 6.6 Hazards and stalls

| Event | Action |
|---|---|
| Load-use | Hold PC and IF/ID for one cycle; bubble ID/EX |
| Branch/jump | Use rule below |
| Mul/div busy | Hold PC, IF/ID, ID/EX; insert bubbles into EX/MEM until done |

Mul/div hold has priority over all upstream actions.

Load-use: stall if a load in ID/EX has rd != x0 and its rd matches either rs1 or rs2 instruction field of the following ID instruction. Compare fields whether or not instruction uses them; extra stalls are acceptable. One stall in every configuration.

Branches/jumps: when branch/jump in ID advances to EX, bubble the following instruction and hold PC. On EX resolution, set PC to target for a taken branch or any jump; otherwise PC+4, then resume fetch. Cost is two bubbles per branch/jump. Trigger stall from ID in all configurations; do not use pre-decode branch class to stall earlier.

### 6.7 Memory and writeback

MEM drives dmem outputs from EX/MEM. Compute byte strobes and shift store data for SB/SH/SW. Load extraction/sign- or zero-extension and registration into MEM/WB. WB selects load data or EX result and writes the register file.

### 6.8 Multiply/divide

Multiply: register operands at start (cycle 0), register product at end of cycle 1, result available in cycle 2. The instruction occupies EX for three cycles. `*` is allowed. Use 33-bit sign-extended operands so MULH/MULHSU/MULHU share one multiplier.

Divide: iterative radix-2 restoring or non-restoring, fixed latency of 32 iterations plus setup; expose latency as a localparam. Divide magnitudes, then correct signs. Apply ISA corner cases above. Early-exit divide-by-zero is optional and must not be added unless requested.

## 7. Configurations

### 7.1 Baseline

Flat ID decode from opcode/funct3/funct7. Detect load-use in ID by comparing ID instruction rs1/rs2 fields with ID/EX load rd. Select EX result with binary encoding and a mux across ALU, mul/div, and link.

### 7.2 Pre-decode (`PREDECODE=1`)

Combinational IF pre-decode of `imem_rdata` produces `pd_class[1:0]` (ALU, load/store, branch/jump, mul/div), `pd_is_load`, and `pd_load_use`. `pd_load_use` is true if the instruction currently in ID is a valid load with rd != x0 and that rd equals fetched instruction rs1 or rs2. Register these with the instruction in IF/ID, following the same hold/clear behavior.

ID uses `pd_class` for execution-unit selection and decodes remaining fields within that class, yielding the same controls as baseline. Load-use stall in ID uses registered `pd_load_use`; do not compare registers in ID for this configuration. The comparison is between program-adjacent instructions: the fetched instruction being captured and the current ID instruction.

Expected stall behavior is logically identical across configurations; IPC should match. Timing/area may differ. The paper’s IPC gain is relative to a baseline that inserts two bubbles; this project uses one (default).

### 7.3 OR select (`OR_SELECT=1`)

Replace binary result select/mux with one-hot `sel_alu`, `sel_md`, `sel_link`, exactly one asserted for each valid instruction. Mask each source to zero when its select is low, then OR the three masked values. Only execution-unit-level selection changes; ALU internal operation selection remains the same unless explicitly expanded later. A one-hot mux may synthesize to equivalent logic; that is an acceptable result.

## 8. RTL module list

One module per file under `rtl/`:

| Module | Purpose |
|---|---|
| `rv32im_core` | Parameterized top (`PREDECODE`, `OR_SELECT`), interface in §4 |
| `fetch_unit` | PC, IF/ID register, optional pre-decode |
| `predecode` | §7.2 pre-decode block |
| `decode_unit` | Flat or two-level decode |
| `regfile` | §6.3 register file |
| `imm_gen` | Immediate generation |
| `alu` | §6.4 arithmetic/logic |
| `branch_unit` | Compare and target |
| `muldiv_unit` | §6.8; `busy` and `done` |
| `hazard_unit` | Stall, hold, bubble, redirect |
| `forward_unit` | §6.5 forwarding |
| `lsu` | Byte strobes, lane selection, extension |
| `result_select` | Baseline mux or OR path |

## 9. Verification

Use SystemVerilog testbenches under `tb/`: clock/reset, instruction memory loaded with `$readmemh` (one 32-bit word per line), and data memory with combinational reads and synchronous byte-strobed writes. Programs end in a self-loop (`jal x0,0`); stop when PC repeats and include a timeout. Compare hierarchical register-file values and selected memory words with hand-computed expected values. Print PASS/FAIL per test. Count cycles and WB-valid retired instructions; report IPC. Programs initialize every register they read; register file itself has no reset.

Required programs:
1. Every R/I ALU operation, edge operands and shifts.
2. LUI/AUIPC.
3. All load/store sizes, sign and zero extension.
4. Six branch conditions, taken/not-taken; JAL/JALR link values.
5. Forwarding at distances 1, 2, 3.
6. Load-use on rs1, rs2, store data, branch operand, JALR; load rd=x0 (no stall); accidental field match (extra stall, correct result).
7. Four multiply variants with edge operands.
8. Divide/remainder by zero and signed overflow.
9. Back-to-back mul/div and dependent follower.
10. Branch after load and load after branch.

Cross-configuration: all three configurations must have identical architectural results and cycle counts for every test.

## 10. Build script

Create a Python or shell script that concatenates synthesizable RTL modules in dependency order and appends one wrapper. Emit `build/rv32im_base.v`, `build/rv32im_predec.v`, and `build/rv32im_orsel.v`. Each wrapper instantiates `rv32im_core` with its corresponding parameter values; output names match top modules. No testbench code in outputs.

## 11. Suggested implementation order

1. ALU, regfile, imm_gen with unit tests.
2. Flat `decode_unit`, `branch_unit`, `lsu`, `forward_unit`.
3. Baseline pipeline without M; test programs 1–6 and 10.
4. `muldiv_unit` and stall; test 7–9.
5. Pre-decode and two-level decode; rerun all tests and compare cycles.
6. OR-select; rerun all tests and compare cycles.
7. Build script, generate three files, run each through the Genus synthesis step.

## 12. Open items

Confirm before implementation if these affect a task: Genus SystemVerilog acceptance (spec assumes plain Verilog); assembler and exact `.hex` format (e.g. RARS); whether OR-select should extend into ALU internal operation selection (default is no); exact multiply/divide latency (defaults above); division of test-program and RTL work among teammates.

When a task depends on an unresolved item, ask rather than guess.
