`timescale 1ns/1ps
module controller_unit_tb;
  reg [6:0] opcode, funct7;
  reg [2:0] funct3;
  wire legal, reg_write, mem_read, mem_write, alu_src, branch, jump, jalr;
  wire [3:0] alu_op;
  wire [2:0] imm_src, branch_type, muldiv_op;
  wire [1:0] operand_a_sel, mem_size;
  wire load_unsigned, is_muldiv;
  integer pass_count = 0, fail_count = 0;

  controller dut (
    .opcode(opcode), .funct3(funct3), .funct7(funct7), .legal(legal),
    .alu_op(alu_op), .reg_write(reg_write), .mem_read(mem_read),
    .mem_write(mem_write), .imm_src(imm_src), .operand_a_sel(operand_a_sel),
    .alu_src(alu_src), .branch(branch), .branch_type(branch_type),
    .jump(jump), .jalr(jalr), .mem_size(mem_size),
    .load_unsigned(load_unsigned), .is_muldiv(is_muldiv),
    .muldiv_op(muldiv_op)
  );

  task check(
    input [6:0] test_opcode, input [2:0] test_funct3, input [6:0] test_funct7,
    input expected_legal, expected_reg_write, expected_mem_read, expected_mem_write,
    input expected_branch, expected_jump, expected_jalr, expected_muldiv,
    input [3:0] expected_alu, input [1:0] expected_size,
    input [2:0] expected_md_op, input string name
  );
    begin
      opcode=test_opcode; funct3=test_funct3; funct7=test_funct7; #1;
      if (legal === expected_legal && reg_write === expected_reg_write &&
          mem_read === expected_mem_read && mem_write === expected_mem_write &&
          branch === expected_branch && jump === expected_jump &&
          jalr === expected_jalr && is_muldiv === expected_muldiv &&
          alu_op === expected_alu && mem_size === expected_size &&
          muldiv_op === expected_md_op) begin
        pass_count = pass_count + 1;
        $display("PASS | CONTROLLER %s | opcode=%07b funct3=%03b funct7=%07b | expected legal/rw/mr/mw/br/j/jr/md=%b/%b/%b/%b/%b/%b/%b/%b actual=%b/%b/%b/%b/%b/%b/%b/%b",
                 name, test_opcode, test_funct3, test_funct7,
                 expected_legal, expected_reg_write, expected_mem_read,
                 expected_mem_write, expected_branch, expected_jump,
                 expected_jalr, expected_muldiv, legal, reg_write, mem_read,
                 mem_write, branch, jump, jalr, is_muldiv);
      end else begin
        fail_count = fail_count + 1;
        $display("FAIL | CONTROLLER %s | opcode=%07b funct3=%03b funct7=%07b | expected legal/rw/mr/mw/br/j/jr/md=%b/%b/%b/%b/%b/%b/%b/%b actual=%b/%b/%b/%b/%b/%b/%b/%b alu=%0d/%0d size=%0d/%0d mdop=%0d/%0d",
                 name, test_opcode, test_funct3, test_funct7,
                 expected_legal, expected_reg_write, expected_mem_read,
                 expected_mem_write, expected_branch, expected_jump,
                 expected_jalr, expected_muldiv, legal, reg_write, mem_read,
                 mem_write, branch, jump, jalr, is_muldiv,
                 expected_alu, alu_op, expected_size, mem_size,
                 expected_md_op, muldiv_op);
      end
    end
  endtask

  initial begin
    check(7'b0110111, 0, 0, 1,1,0,0,0,0,0,0, 0,2,0, "LUI");
    check(7'b0010111, 0, 0, 1,1,0,0,0,0,0,0, 0,2,0, "AUIPC");
    check(7'b1100111, 0, 0, 1,1,0,0,0,1,1,0, 0,2,0, "JALR");
    check(7'b1100011, 3'b000, 0, 1,0,0,0,1,0,0,0, 0,2,0, "BEQ");
    check(7'b0000011, 3'b100, 0, 1,1,1,0,0,0,0,0, 0,0,0, "LBU");
    check(7'b0100011, 3'b010, 0, 1,0,0,1,0,0,0,0, 0,2,0, "SW");
    check(7'b0010011, 3'b011, 0, 1,1,0,0,0,0,0,0, 6,2,0, "SLTIU");
    check(7'b0010011, 3'b101, 7'b0100000, 1,1,0,0,0,0,0,0, 9,2,0, "SRAI");
    check(7'b0110011, 3'b000, 7'b0000001, 1,1,0,0,0,0,0,1, 0,2,0, "MUL");
    check(7'b0110011, 3'b000, 7'b0100001, 0,0,0,0,0,0,0,0, 0,2,0, "Invalid M funct7");
    check(7'b0000011, 3'b011, 0, 0,0,0,0,0,0,0,0, 0,2,0, "Invalid load funct3");
    check(7'b0100011, 3'b011, 0, 0,0,0,0,0,0,0,0, 0,2,0, "Invalid store funct3");
    check(7'b1100011, 3'b010, 0, 0,0,0,0,0,0,0,0, 0,2,0, "Invalid branch funct3");
    check(7'b0010011, 3'b001, 7'b0100000, 0,0,0,0,0,0,0,0, 0,2,0, "Invalid SLLI funct7");
    check(7'b0110011, 3'b000, 7'b0000010, 0,0,0,0,0,0,0,0, 0,2,0, "Invalid R-type funct7");
    check(7'b0001111, 0, 0, 0,0,0,0,0,0,0,0, 0,2,0, "FENCE NOP");
    check(7'b1110011, 0, 0, 0,0,0,0,0,0,0,0, 0,2,0, "SYSTEM NOP");
    $display("CONTROLLER SUMMARY | PASS=%0d FAIL=%0d", pass_count, fail_count);
    if (fail_count) $fatal(1, "Controller test failed");
    $display("CONTROLLER ALL TESTS PASSED");
    $finish;
  end
endmodule
