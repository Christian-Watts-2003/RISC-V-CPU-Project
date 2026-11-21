#!/usr/bin/env python3
"""Generate a small self-checking RV32M program for the Basys3 trace wrapper."""

from pathlib import Path

words = []
fail_branches = []


def i(imm, rs1, funct3, rd, opcode=0x13):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def li(rd, value):
    value &= 0xFFFFFFFF
    signed = value if value < 0x80000000 else value - 0x100000000
    if -2048 <= signed <= 2047:
        words.append(i(signed, 0, 0, rd))
    else:
        upper = ((value + 0x800) >> 12) & 0xFFFFF
        words.append((upper << 12) | (rd << 7) | 0x37)
        words.append(i(value & 0xFFF, rd, 0, rd))


def store(imm, rs2):
    words.append((((imm >> 5) & 0x7F) << 25) | (rs2 << 20) |
                 (2 << 12) | ((imm & 31) << 7) | 0x23)


def bne(rs1, rs2, offset):
    if offset % 2 or not -4096 <= offset <= 4094:
        raise ValueError(f"Branch offset out of range: {offset}")
    return (((offset >> 12) & 1) << 31) | (((offset >> 5) & 0x3F) << 25) | \
           (rs2 << 20) | (rs1 << 15) | (1 << 12) | \
           (((offset >> 1) & 0xF) << 8) | (((offset >> 11) & 1) << 7) | 0x63


cases = [
    (0, -7, 3, 0xFFFFFFEB),
    (1, -7, 3, 0xFFFFFFFF),
    (2, 0x80000000, 0xFFFFFFFF, 0x80000000),
    (3, 0x80000000, 0xFFFFFFFF, 0x7FFFFFFF),
    (4, -7, 3, 0xFFFFFFFE),
    (5, -7, 3, 0x55555553),
    (6, -7, 3, 0xFFFFFFFF),
    (7, -7, 3, 0),
    (4, 0x80000000, -1, 0x80000000),
    (6, 0x80000000, -1, 0),
    (4, -7, 0, 0xFFFFFFFF),
    (5, -7, 0, 0xFFFFFFFF),
    (6, -7, 0, 0xFFFFFFF9),
    (7, -7, 0, 0xFFFFFFF9),
]

for test_id, (funct3, a, b, expected) in enumerate(cases, 1):
    li(25, test_id)
    li(1, a)
    li(2, b)
    words.append((1 << 25) | (2 << 20) | (1 << 15) | (funct3 << 12) | (3 << 7) | 0x33)
    li(4, expected)
    fail_branches.append(len(words))
    words.append(0)
    store(0x100, 25)

li(30, 0x600D600D)
store(0, 30)
words.append(0x0000006F)
fail = len(words)
store(0x104, 25)
li(30, 0xDEADFA11)
store(0, 30)
words.append(0x0000006F)

for index in fail_branches:
    words[index] = bne(3, 4, 4 * (fail - index))

output = Path(__file__).with_name("basys3_muldiv.hex")
output.write_text("".join(f"{word:08x}\n" for word in words), encoding="ascii")
print(f"Wrote {len(words)} instructions to {output}")
