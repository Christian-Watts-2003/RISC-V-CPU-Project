# RISC-V Single-Cycle Processor

A RISC-V RV32I processor implementation on FPGA, designed as a master's thesis project to explore power-efficient CPU architectures for AI workloads.

## Project Goals

- Implement a complete single-cycle RISC-V RV32I processor
- Extend to pipelined architecture with hazard detection
- Explore power optimization techniques (dynamic voltage scaling, power gating)
- Target: Xilinx Basys3 FPGA

## Architecture Overview

### Current Status: ALU Development

- [x] ALU module (add, sub, and, or, xor, slt, shifts)
- [ ] Register file
- [ ] Instruction memory
- [ ] Data memory
- [ ] Control unit
- [ ] Datapath integration
- [ ] Single-cycle CPU
- [ ] Pipelined CPU (Phase 2)

## Repository Structure

- `rtl/single_cycle/` - maintained single-cycle implementation.
- `rtl/pipeline/` - five-stage pipeline implementation scaffold.
- `rtl/optimized/` - experimental optimization variants.
- `sim/Single Cycle TBs/` - maintained single-cycle testbenches.
- `legacy files/` - superseded RTL and testbenches retained for reference.
- `docs/` - project specifications and design documentation.
- `scripts/` - repeatable simulation helpers.

## Building & Simulation

### Prerequisites

- Vivado 2023.1+ (WebPACK free version)
- ModelSim or Vivado Simulator (for testbenches)
- SystemVerilog knowledge

### Running Simulations

```bash
# In Vivado, add only rtl/single_cycle/*.sv as design sources and
# sim/Single Cycle TBs/single_cycle_tb.sv as the simulation source.
# 4. Run simulation

# Or via command line:
vlog rtl/single_cycle/*.sv "sim/Single Cycle TBs/single_cycle_tb.sv"
vsim single_cycle_tb
run -all
```

## Design Details

See [docs/design.md](docs/design.md) for detailed architecture documentation.

See [docs/isa_reference.md](docs/isa_reference.md) for RISC-V instruction set reference.

## Author

Christian Watts\
B.S. in Electrical Engineering from The University of Alabama\
Master's Student, Electrical Engineering at UT San Antonio
## License

MIT License - See [LICENSE](LICENSE) file

## References

- Harris & Harris - "Digital Design and Computer Architecture: RISC-V Edition"
- RISC-V Specification - https://riscv.org/technical/specifications/
- Xilinx Basys3 Board - https://digilent.com/shop/basys-3-artix-7-fpga-trainer-board/
