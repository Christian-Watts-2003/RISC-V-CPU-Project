# Copilot standing rules for the RV32IM project

- RTL under `rtl/` must be synthesizable plain Verilog-2001. Do not use SystemVerilog constructs (`logic`, `always_ff`, interfaces, packages, structs). Testbenches under `tb/` may use SystemVerilog.
- Use one rising-edge clock, `clk`, and synchronous active-high reset, `rst`.
- No `initial` blocks, `$display`, delays, latches, tri-states, gated clocks, or multiple clock domains in synthesizable RTL.
- Do not use `/` or `%` on variables in RTL. Multiplication may use `*`; division must be iterative.
- Combinational logic uses `always @*` and assigns defaults to every output. Sequential logic uses nonblocking assignments.
- One module per RTL file, with the file named after the module.
- Select configurations using module parameters and `generate if`, not `ifdef`.
- Do not add features outside the spec: no branch prediction, caches, CSRs, exceptions, interrupts, or compressed instructions.
- Keep the baseline straightforward and unoptimized for a fair comparison.
- All configurations must be architecturally identical and have identical cycle counts on every test. Any difference is a bug.
- When the specification is silent or ambiguous, ask before choosing an interpretation.
- Consult `docs/SPEC.md` for the detailed architecture, interfaces, ISA subset, pipeline behavior, optimizations, verification, and build requirements.
