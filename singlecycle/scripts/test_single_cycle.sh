#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! command -v iverilog >/dev/null 2>&1; then
  echo "ERROR: iverilog is required (install Icarus Verilog)." >&2
  exit 127
fi
OUT="$(mktemp "${TMPDIR:-/tmp}/single_cycle_tb.XXXXXX")"
trap 'rm -f "$OUT"' EXIT
iverilog -g2012 -Wall -s single_cycle_tb -o "$OUT" \
  "$ROOT"/rtl/alu.sv \
  "$ROOT"/rtl/branch_unit.sv \
  "$ROOT"/rtl/controller.sv \
  "$ROOT"/rtl/cpu.sv \
  "$ROOT"/rtl/datapath.sv \
  "$ROOT"/rtl/imm_gen.sv \
  "$ROOT"/rtl/lsu.sv \
  "$ROOT"/rtl/memory.sv \
  "$ROOT"/rtl/muldiv.sv \
  "$ROOT"/rtl/regfile.sv \
  "$ROOT"/rtl/top.sv \
  "$ROOT/sim/Single Cycle TBs/single_cycle_tb.sv"
vvp "$OUT"
