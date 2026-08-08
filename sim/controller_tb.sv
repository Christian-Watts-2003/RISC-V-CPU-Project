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

    task check(
        input string        instr_name,
        input logic [3:0]   exp_alu_op,
        input logic         exp_reg_write,
        input logic         exp_mem_read,
        input logic         exp_mem_write,
        input logic [2:0]   exp_imm_src,
        input logic         exp_branch,
        input logic         exp_jump,
        input logic         exp_alu_src
    );
        
        if (alu_op !== exp_alu_op || reg_write !== exp_reg_write || mem_read !== exp_mem_read || mem_write !== exp_mem_write || imm_src !== exp_imm_src || branch !== exp_branch || jump !== exp_jump  || alu_src !== exp_alu_src) begin
            $error("FAIL: %s", instr_name);
            $display("  Got: alu_op=%b, reg_write=%b, mem_read=%b, mem_write=%b, imm_src=%b, branch=%b, jump=%b, alu_src=%b", alu_op, reg_write, mem_read, mem_write, imm_src, branch, jump, alu_src);
        end else begin
            $display("PASS: %s", instr_name);
        end
    endtask

    initial begin
        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0000000; // ADD
        #1 check("ADD", 4'b0000, 1, 0, 0, 3'b000, 0, 0, 0);

        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0100000; // SUB
        #1 check("SUB", 4'b0001, 1, 0, 0, 3'b000, 0, 0, 0);

        // ========== I-type ==========
        opcode = 7'b0010011; funct3 = 3'b000; funct7 = 7'b0000000; // ADDI
        #1 check("ADDI", 4'b0000, 1, 0, 0, 3'b000, 0, 0, 1);

        // ========== Load ==========
        opcode = 7'b0000011; funct3 = 3'b010; funct7 = 7'b0000000; // LW
        #1 check("LW", 4'b0000, 1, 1, 0, 3'b000, 0, 0, 1);

        // ========== Store ==========
        opcode = 7'b0100011; funct3 = 3'b010; funct7 = 7'b0000000; // SW
        #1 check("SW", 4'b0000, 0, 0, 1, 3'b001, 0, 0, 1);

        // ========== Branch ==========
        opcode = 7'b1100011; funct3 = 3'b000; funct7 = 7'b0000000; // BEQ
        #1 check("BEQ", 4'b0000, 0, 0, 0, 3'b010, 1, 0, 0);

        // ========== JAL ==========
        opcode = 7'b1101111; funct3 = 3'b000; funct7 = 7'b0000000;
        #1 check("JAL", 4'b0000, 1, 0, 0, 3'b100, 0, 1, 0);

        // ========== JALR ==========
        opcode = 7'b1100111; funct3 = 3'b000; funct7 = 7'b0000000;
        #1 check("JALR", 4'b0000, 1, 0, 0, 3'b000, 0, 1, 1);

        // ========== LUI / AUIPC ==========
        opcode = 7'b0110111; funct3 = 3'b000; funct7 = 7'b0000000; // LUI
        #1 check("LUI", 4'b0000, 1, 0, 0, 3'b011, 0, 0, 0);

        opcode = 7'b0010111; funct3 = 3'b000; funct7 = 7'b0000000; // AUIPC
        #1 check("AUIPC", 4'b0000, 1, 0, 0, 3'b011, 0, 0, 0);

        $finish;
    end
        
endmodule
