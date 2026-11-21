# Project guidance

- The current design is the multi-cycle RV32I core in `CURRENT_multicycle/`.
  `multicycle_MULDIV/` is an independent future-integration copy, not an
  enabled RV32M implementation. `singlecycle/` is a separate reference.
- Pipeline and older experiments under `legacy/to-be-deleted/` are retained
  for review. Do not remove them permanently without an explicit request.
- Compile only the relevant project and source set; module names overlap.
  Preserve the existing core behavior unless a change is requested.
- New synthesizable CPU RTL should use a single rising-edge clock,
  synchronous reset, combinational defaults, nonblocking sequential
  assignments, and no latches, gated clocks or variable `/` or `%`.
  Existing FPGA memory initialization and the historical combinational
  MulDiv source are separate from that guideline.
- Keep experiments separate from the current baseline. Do not add CSRs,
  exceptions, interrupts, caches, prediction, or compressed instructions
  unless requested. Ask when behavior or architecture is ambiguous.
- The project owner runs simulations personally; do not simulate remotely.
