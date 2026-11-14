`timescale 1ns / 1ps

module controller_tb;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [3:0] alu_op;
    logic reg_write, mem_read, mem_write;
    logic [2:0] imm_src;
    logic branch, jump, alu_src, is_muldiv;
    logic [2:0] muldiv_op;
    integer failures = 0;

    controller dut (.*);

    task automatic expect_controls(
        input string name,
        input logic [3:0] exp_alu_op,
        input logic exp_reg_write,
        input logic exp_mem_read,
        input logic exp_mem_write,
        input logic [2:0] exp_imm_src,
        input logic exp_branch,
        input logic exp_jump,
        input logic exp_alu_src,
        input logic exp_is_muldiv,
        input logic [2:0] exp_muldiv_op
    );
        #1;
        if ({alu_op, reg_write, mem_read, mem_write, imm_src, branch, jump,
             alu_src, is_muldiv, muldiv_op} !==
            {exp_alu_op, exp_reg_write, exp_mem_read, exp_mem_write,
             exp_imm_src, exp_branch, exp_jump, exp_alu_src,
             exp_is_muldiv, exp_muldiv_op}) begin
            $error("FAIL %s: alu=%b rw=%b mr=%b mw=%b imm=%b br=%b j=%b src=%b md=%b/%b",
                   name, alu_op, reg_write, mem_read, mem_write, imm_src,
                   branch, jump, alu_src, is_muldiv, muldiv_op);
            failures++;
        end else begin
            $display("PASS %s", name);
        end
    endtask

    task automatic set_instruction(
        input logic [6:0] op,
        input logic [2:0] f3,
        input logic [6:0] f7
    );
        opcode = op;
        funct3 = f3;
        funct7 = f7;
    endtask

    initial begin
        // Register-register integer instructions, including exact funct7 validation.
        set_instruction(7'b0110011, 3'b000, 7'b0000000);
        expect_controls("ADD", 4'b0000, 1, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b0110011, 3'b000, 7'b0100000);
        expect_controls("SUB", 4'b0001, 1, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b0110011, 3'b011, 7'b0000000);
        expect_controls("SLTU", 4'b1001, 1, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b0110011, 3'b011, 7'b0100000);
        expect_controls("reject invalid SLTU funct7", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b0110011, 3'b000, 7'b0000010);
        expect_controls("reject invalid ADD/SUB funct7", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b0110011, 3'b101, 7'b0100000);
        expect_controls("SRA", 4'b1000, 1, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b0110011, 3'b101, 7'b0000010);
        expect_controls("reject invalid shift funct7", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        // OP-IMM operations and shift-immediate legality.
        set_instruction(7'b0010011, 3'b000, 7'b0000000);
        expect_controls("ADDI", 0, 1, 0, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b0010011, 3'b010, 7'b0000000);
        expect_controls("SLTI", 4'b0101, 1, 0, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b0010011, 3'b011, 7'b0000000);
        expect_controls("SLTIU", 4'b1001, 1, 0, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b0010011, 3'b100, 7'b0000000);
        expect_controls("XORI", 4'b0100, 1, 0, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b0010011, 3'b110, 7'b0000000);
        expect_controls("ORI", 4'b0011, 1, 0, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b0010011, 3'b111, 7'b0000000);
        expect_controls("ANDI", 4'b0010, 1, 0, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b0010011, 3'b001, 7'b0000000);
        expect_controls("SLLI", 4'b0110, 1, 0, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b0010011, 3'b001, 7'b0000001);
        expect_controls("reject invalid SLLI", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b0010011, 3'b101, 7'b0000000);
        expect_controls("SRLI", 4'b0111, 1, 0, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b0010011, 3'b101, 7'b0100000);
        expect_controls("SRAI", 4'b1000, 1, 0, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b0010011, 3'b101, 7'b0000001);
        expect_controls("reject invalid SRLI/SRAI", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b0010011, 3'b001, 7'b0000001);
        expect_controls("reject unsupported OP-IMM funct3", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        // Deliberately supported word memory operations and BEQ only.
        set_instruction(7'b0000011, 3'b010, 7'b0000000);
        expect_controls("LW", 0, 1, 1, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b0000011, 3'b000, 7'b0000000);
        expect_controls("reject LB", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b0100011, 3'b010, 7'b0000000);
        expect_controls("SW", 0, 0, 0, 1, 1, 0, 0, 1, 0, 0);
        set_instruction(7'b0100011, 3'b001, 7'b0000000);
        expect_controls("reject SH", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b1100011, 3'b000, 7'b0000000);
        expect_controls("BEQ", 1, 0, 0, 0, 2, 1, 0, 0, 0, 0);
        set_instruction(7'b1100011, 3'b001, 7'b0000000);
        expect_controls("reject BNE", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        // Jumps, U-type instructions, and deliberate unsupported base instructions.
        set_instruction(7'b1101111, 3'b000, 7'b0000000);
        expect_controls("JAL", 0, 1, 0, 0, 4, 0, 1, 0, 0, 0);
        set_instruction(7'b1100111, 3'b000, 7'b0000000);
        expect_controls("JALR", 0, 1, 0, 0, 0, 0, 1, 1, 0, 0);
        set_instruction(7'b1100111, 3'b001, 7'b0000000);
        expect_controls("reject invalid JALR funct3", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b0110111, 3'b000, 7'b0000000);
        expect_controls("LUI", 0, 1, 0, 0, 3, 0, 0, 0, 0, 0);
        set_instruction(7'b0010111, 3'b000, 7'b0000000);
        expect_controls("AUIPC", 0, 1, 0, 0, 3, 0, 0, 0, 0, 0);
        set_instruction(7'b0001111, 3'b000, 7'b0000000);
        expect_controls("unsupported FENCE", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        set_instruction(7'b1110011, 3'b000, 7'b0000000);
        expect_controls("unsupported ECALL", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        // M-extension qualification: legal for R-type, not unrelated formats.
        set_instruction(7'b0110011, 3'b111, 7'b0000001);
        expect_controls("REMU", 0, 1, 0, 0, 0, 0, 0, 0, 1, 3'b111);
        set_instruction(7'b0010011, 3'b000, 7'b0000001);
        expect_controls("M funct7 on OP-IMM is not M-extension", 0, 1, 0, 0, 0, 0, 0, 1, 0, 0);
        set_instruction(7'b1100011, 3'b000, 7'b0000001);
        expect_controls("M funct7 on branch is not M-extension", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

        if (failures != 0)
            $fatal(1, "%0d controller test(s) failed", failures);
        $display("All controller tests passed");
        $finish;
    end
endmodule
