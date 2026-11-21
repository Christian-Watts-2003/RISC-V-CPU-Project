#!/usr/bin/env python3
"""Generate a self-checking RV32I image for the Basys3 wrapper."""

from pathlib import Path


words = []
labels = {}
next_test_id = 1


def label(name):
    labels[name] = 4 * len(words)


def emit(kind, *args):
    words.append((kind, args))


def r(funct7, rs2, rs1, funct3, rd):
    emit("r", funct7, rs2, rs1, funct3, rd)


def i(imm, rs1, funct3, rd, opcode=0b0010011):
    if not -2048 <= imm <= 2047:
        raise ValueError(f"I-immediate out of range: {imm}")
    emit("i", imm, rs1, funct3, rd, opcode)


def s(imm, rs2, rs1, funct3):
    if not -2048 <= imm <= 2047:
        raise ValueError(f"S-immediate out of range: {imm}")
    emit("s", imm, rs2, rs1, funct3)


def b(target, rs1, rs2, funct3):
    emit("b", target, rs1, rs2, funct3)


def u(imm20, rd, opcode):
    emit("u", imm20, rd, opcode)


def j(target, rd):
    emit("j", target, rd)


def addi(rd, rs1, imm):
    i(imm, rs1, 0b000, rd)


def li(rd, value):
    value &= 0xFFFFFFFF
    signed_value = value if value < 0x80000000 else value - 0x100000000
    if -2048 <= signed_value <= 2047:
        addi(rd, 0, signed_value)
        return
    upper = (value + 0x800) >> 12
    low = value - (upper << 12)
    if low >= 0x800:
        low -= 0x1000
    u(upper & 0xFFFFF, rd, 0b0110111)
    addi(rd, rd, low)


def bne(rs1, rs2, target):
    b(target, rs1, rs2, 0b001)


def beq(rs1, rs2, target):
    b(target, rs1, rs2, 0b000)


def check(reg, expected):
    global next_test_id
    li(24, expected)
    li(25, next_test_id)
    bne(reg, 24, "fail")
    s(0x100, 25, 0, 0b010)  # pass event: reserved test-report address
    next_test_id += 1


# RV32I upper/immediate and PC-relative operations.
li(1, 0x12345000)
check(1, 0x12345000)
emit("raw", 0xFFFFFFFF)  # Unsupported encoding must behave as a NOP.
u(0, 2, 0b0010111)       # AUIPC x2, 0
u(0, 3, 0b0010111)       # AUIPC x3, 0
addi(3, 3, -4)
bne(2, 3, "fail")

# OP-IMM operations.
li(1, 0x7FFFFFFF)
li(2, -1)
addi(3, 0, 1)
i(0, 1, 0b010, 4)        # SLTI
check(4, 0)
i(0, 2, 0b010, 5)
check(5, 1)
i(0, 2, 0b011, 6)        # SLTIU
check(6, 0)
i(0, 1, 0b011, 7)
check(7, 0)
i(0x555, 1, 0b100, 8)    # XORI
check(8, 0x7FFFFAAA)
i(0x155, 0, 0b110, 9)    # ORI
check(9, 0x155)
i(0x55, 9, 0b111, 10)    # ANDI
check(10, 0x55)
i(31, 3, 0b001, 11)      # SLLI
check(11, 0x80000000)
i(31, 1, 0b101, 12)      # SRLI
check(12, 0)
i((0b0100000 << 5) | 31, 2, 0b101, 13)  # SRAI
check(13, 0xFFFFFFFF)

# Register-register ALU operations.
r(0, 3, 1, 0b000, 14)    # ADD
check(14, 0x80000000)
r(0b0100000, 2, 1, 0b000, 15)  # SUB
check(15, 0x80000000)
r(0, 3, 3, 0b001, 16)    # SLL
check(16, 2)
r(0, 3, 11, 0b101, 17)   # SRL
check(17, 0x40000000)
r(0b0100000, 3, 2, 0b101, 18)   # SRA
check(18, 0xFFFFFFFF)
r(0, 3, 2, 0b010, 19)    # SLT
check(19, 1)
r(0, 3, 2, 0b011, 20)    # SLTU
check(20, 0)
r(0, 2, 1, 0b100, 21)    # XOR
check(21, 0x80000000)
r(0, 2, 1, 0b110, 22)    # OR
check(22, 0xFFFFFFFF)
r(0, 2, 1, 0b111, 23)    # AND
check(23, 0x7FFFFFFF)

# All six conditional branches, including taken paths.
beq(1, 1, "beq_ok")
j("fail", 0)
label("beq_ok")
bne(1, 0, "bne_ok")
j("fail", 0)
label("bne_ok")
b( "blt_ok", 2, 3, 0b100)
j("fail", 0)
label("blt_ok")
b( "bge_ok", 3, 2, 0b101)
j("fail", 0)
label("bge_ok")
b( "bltu_ok", 3, 2, 0b110)
j("fail", 0)
label("bltu_ok")
b( "bgeu_ok", 2, 3, 0b111)
j("fail", 0)
label("bgeu_ok")

# JAL link and target, followed by JALR link and target.
j("jal_target", 5)
j("fail", 0)
label("jal_target")
u(0, 24, 0b0010111)
addi(24, 24, -4)
bne(5, 24, "fail")
u(0, 6, 0b0010111)
addi(6, 6, 16)
jalr = 0b1100111
i(0, 6, 0b000, 7, jalr)
j("fail", 0)
label("jalr_target")
u(0, 24, 0b0010111)
addi(24, 24, -4)
bne(7, 24, "fail")

# Byte, halfword, and word stores/loads, signed and unsigned.
li(1, -128)
s(4, 1, 0, 0b000)       # SB
i(4, 0, 0b000, 2, 0b0000011)   # LB
bne(2, 1, "fail")
li(3, 128)
i(4, 0, 0b100, 4, 0b0000011)   # LBU
bne(4, 3, "fail")
li(5, 0xFFFFF123)
s(6, 5, 0, 0b001)       # SH
i(6, 0, 0b001, 6, 0b0000011)   # LH
bne(6, 5, "fail")
i(6, 0, 0b101, 7, 0b0000011)   # LHU
check(7, 0xF123)
li(8, 0x12345678)
s(8, 8, 0, 0b010)       # SW
i(8, 0, 0b010, 9, 0b0000011)   # LW
bne(9, 8, "fail")

label("pass")
li(30, 0x600D600D)
s(0, 30, 0, 0b010)       # dmem[0] = PASS marker
label("pass_loop")
i(0, 0, 0b010, 31, 0b0000011)
j("pass_loop", 0)

label("fail")
s(0x104, 25, 0, 0b010)       # fail event: reserved test-report address
li(30, 0xDEADFA11)
s(0, 30, 0, 0b010)       # dmem[0] = FAIL marker
label("fail_loop")
i(0, 0, 0b010, 31, 0b0000011)
j("fail_loop", 0)


def signed12(value):
    return value & 0xFFF


def encode(kind, args, pc):
    if kind == "raw":
        return args[0]
    if kind == "r":
        funct7, rs2, rs1, funct3, rd = args
        return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33
    if kind == "i":
        imm, rs1, funct3, rd, opcode = args
        return (signed12(imm) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    if kind == "s":
        imm, rs2, rs1, funct3 = args
        value = signed12(imm)
        return (((value >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | ((value & 0x1F) << 7) | 0x23
    if kind == "b":
        target, rs1, rs2, funct3 = args
        value = labels[target] - pc
        if value % 2 or not -(1 << 12) <= value < (1 << 12):
            raise ValueError(f"branch offset out of range: {target} at {pc}")
        return (((value >> 12) & 1) << 31) | (((value >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (((value >> 1) & 0xF) << 8) | (((value >> 11) & 1) << 7) | 0x63
    if kind == "u":
        imm20, rd, opcode = args
        return (imm20 << 12) | (rd << 7) | opcode
    if kind == "j":
        target, rd = args
        value = labels[target] - pc
        if value % 2 or not -(1 << 20) <= value < (1 << 20):
            raise ValueError(f"jump offset out of range: {target} at {pc}")
        return (((value >> 20) & 1) << 31) | (((value >> 1) & 0x3FF) << 21) | (((value >> 11) & 1) << 20) | (((value >> 12) & 0xFF) << 12) | (rd << 7) | 0x6F
    raise ValueError(kind)


output = Path(__file__).with_name("basys3_rv32i_edgecase.hex")
with output.open("w", encoding="ascii") as file:
    for index, (kind, args) in enumerate(words):
        file.write(f"{encode(kind, args, index * 4):08x}\n")

print(f"wrote {len(words)} instructions to {output}")
