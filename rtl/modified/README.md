# Modified multi-cycle RV32I core

`rv32i_multicycle.sv` is a timing-oriented RV32I core built from the existing
single-cycle controller, immediate generator, ALU, LSU, and register file.

The core separates execution into:

1. Fetch
2. Decode
3. Execute
4. Memory
5. Writeback

The instruction memory remains combinational through `instruction`, addressed
by `pc`. Data memory uses a simple valid/ready handshake:

- `mem_valid` indicates an active data-memory transaction.
- `mem_read` or `mem_write` selects the operation.
- `mem_ready` completes the transaction.
- `mem_write_strobe` preserves byte/halfword lane selection.

Tie `mem_ready` high when using the existing combinational Basys3 data-memory
wrapper. The original `rtl/single_cycle` core remains the functional reference.
