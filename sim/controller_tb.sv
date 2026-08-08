`timescale 1ns / 1ps

module controller_tb;

    // DUT inputs
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    // DUT outputs
    logic [3:0] alu_op;
    logic       reg_write;
    logic       mem_read;
    logic       mem_write;
    logic [2:0] imm_src;
    logic       branch;
    logic       jump;
    logic       alu_src;
  
    controller dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(alu_op),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .imm_src(imm_src),
        .branch(branch),
        .jump(jump),
        .alu_src(alu_src)
    );

endmodule
