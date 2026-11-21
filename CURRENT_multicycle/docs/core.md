# Current multi-cycle RV32I core

`rtl/rv32i_multicycle.sv` uses the local controller, immediate generator, ALU,
branch unit, LSU, and register file. It has fetch, decode, execute, optional
memory, and writeback phases. Instruction memory must supply the word at
`pc` combinationally. Retirement reports the completed instruction's PC and
encoding; unsupported encodings, including RV32M, retire without side effects.

Data memory uses aligned word reads and byte strobes. Misaligned halfword and
word accesses are unsupported. The core holds `mem_valid`, operation,
address, write data and strobes during a wait. **An external memory must
accept a transaction only when `enable && mem_valid && mem_ready` is true on
the clock edge**: the core does not advance when `enable` is low, even if
`mem_ready` is high. This is not an ordinary independent valid/ready
handshake.

The existing Basys3 wrapper ties ready high but does not gate RAM writes or
store counting with the core enable. A store held during a pause or divider
interval can therefore be written and counted repeatedly. Ordinary RAM
repeatedly receives the same data, but counts and side-effecting devices are
not safe. This cleanup preserves that behavior; account for it when using
the wrapper. See [board setup](../board/BASYS3_MODIFIED_README.txt).

The owner reports that this core has been verified and meets timing; the
timing report is not included. No new timing measurement is claimed.

## Local test

From the repository root:

```sh
bash CURRENT_multicycle/scripts/test_multicycle.sh
```

The path above is relative to the repository root; the script itself can be
invoked by absolute path from elsewhere. It requires `iverilog` and `vvp`,
compiles only this project's RTL, and prints retirement, memory, pause, and
register checks. It covers RV32I operations, taken and untaken control flow,
illegal/RV32M NOPs, x0, memory waits and enable pauses, with a timeout. It has
not been run as part of this cleanup; the owner will run it locally.
