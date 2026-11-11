#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${TMPDIR:-/tmp}/single_cycle_tb.vvp"
if ! command -v iverilog >/dev/null 2>&1; then
  echo "ERROR: iverilog is required (install Icarus Verilog)." >&2
  exit 127
fi
iverilog -g2012 -Wall -s single_cycle_tb -o "$OUT" \
  "$ROOT"/rtl/single_cycle/alu.sv \
  "$ROOT"/rtl/single_cycle/branch_unit.sv \
  "$ROOT"/rtl/single_cycle/controller.sv \
  "$ROOT"/rtl/single_cycle/cpu.sv \
  "$ROOT"/rtl/single_cycle/datapath.sv \
  "$ROOT"/rtl/single_cycle/imm_gen.sv \
  "$ROOT"/rtl/single_cycle/lsu.sv \
  "$ROOT"/rtl/single_cycle/memory.sv \
  "$ROOT"/rtl/single_cycle/muldiv.sv \
  "$ROOT"/rtl/single_cycle/regfile.sv \
  "$ROOT"/rtl/single_cycle/top.sv \
  "$ROOT"/sim/single_cycle_tb.sv
vvp "$OUT"
