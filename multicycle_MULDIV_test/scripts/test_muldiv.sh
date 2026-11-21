#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
    echo "ERROR: Icarus Verilog (iverilog and vvp) is required." >&2
    exit 127
fi
OUT="$(mktemp "${TMPDIR:-/tmp}/muldiv_tb.XXXXXX")"
trap 'rm -f "$OUT"' EXIT

iverilog -g2012 -Wall -s muldiv_integration_tb -o "$OUT" \
    "$ROOT"/rtl/*.sv "$ROOT/sim/muldiv_integration_tb.sv"
vvp "$OUT"
