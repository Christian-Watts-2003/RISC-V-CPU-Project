#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(mktemp "${TMPDIR:-/tmp}/multicycle_tb.XXXXXX")"
trap 'rm -f "$OUT"' EXIT

if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
    echo "ERROR: Icarus Verilog (iverilog and vvp) is required." >&2
    exit 127
fi

iverilog -g2012 -Wall -s multicycle_tb -o "$OUT" \
    "$ROOT"/rtl/rv32i_multicycle.sv "$ROOT"/rtl/controller.sv \
    "$ROOT"/rtl/imm_gen.sv "$ROOT"/rtl/alu.sv \
    "$ROOT"/rtl/branch_unit.sv "$ROOT"/rtl/lsu.sv \
    "$ROOT"/rtl/regfile.sv "$ROOT/sim/multicycle_tb.sv"
vvp "$OUT"
