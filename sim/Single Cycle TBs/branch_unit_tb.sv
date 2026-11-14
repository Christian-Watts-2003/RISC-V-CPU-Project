`timescale 1ns/1ps
module branch_unit_tb;
  reg [31:0] pc, imm, rs1_value, rs2_value;
  reg branch_en, jump_en, jalr_en;
  reg [2:0] branch_type;
  wire taken;
  wire [31:0] target, link_value;
  integer pass_count = 0, fail_count = 0;

  branch_unit dut (
    .pc(pc), .imm(imm), .rs1_value(rs1_value), .rs2_value(rs2_value),
    .branch_en(branch_en), .branch_type(branch_type), .jump_en(jump_en),
    .jalr_en(jalr_en), .taken(taken), .target(target), .link_value(link_value)
  );

  task check(
    input [31:0] test_pc, test_imm, lhs, rhs,
    input test_branch, input [2:0] test_type,
    input test_jump, test_jalr,
    input expected_taken, input [31:0] expected_target,
    input [31:0] expected_link, input string name
  );
    begin
      pc=test_pc; imm=test_imm; rs1_value=lhs; rs2_value=rhs;
      branch_en=test_branch; branch_type=test_type;
      jump_en=test_jump; jalr_en=test_jalr; #1;
      if (taken === expected_taken && target === expected_target &&
          link_value === expected_link) begin
        pass_count = pass_count + 1;
        $display("PASS | BRANCH %s | pc=%08h imm=%08h rs1=%08h rs2=%08h | expected taken/target/link=%b/%08h/%08h actual=%b/%08h/%08h",
                 name, test_pc, test_imm, lhs, rhs, expected_taken, expected_target,
                 expected_link, taken, target, link_value);
      end else begin
        fail_count = fail_count + 1;
        $display("FAIL | BRANCH %s | pc=%08h imm=%08h rs1=%08h rs2=%08h | expected taken/target/link=%b/%08h/%08h actual=%b/%08h/%08h",
                 name, test_pc, test_imm, lhs, rhs, expected_taken, expected_target,
                 expected_link, taken, target, link_value);
      end
    end
  endtask

  initial begin
    check(32'h100, 32'h20, 1, 1, 1, 3'b000, 0, 0, 1, 32'h120, 32'h104, "BEQ taken");
    check(32'h100, 32'h20, 1, 2, 1, 3'b001, 0, 0, 1, 32'h120, 32'h104, "BNE taken");
    check(32'h100, 32'h20, -1, 1, 1, 3'b100, 0, 0, 1, 32'h120, 32'h104, "BLT signed");
    check(32'h100, 32'h20, 1, -1, 1, 3'b101, 0, 0, 1, 32'h120, 32'h104, "BGE signed");
    check(32'h100, 32'h20, 1, 2, 1, 3'b110, 0, 0, 1, 32'h120, 32'h104, "BLTU unsigned");
    check(32'h100, 32'h20, 2, 1, 1, 3'b111, 0, 0, 1, 32'h120, 32'h104, "BGEU unsigned");
    check(32'h100, 32'h20, 1, 1, 1, 3'b001, 0, 0, 0, 32'h120, 32'h104, "BNE not taken");
    check(32'h100, 32'h20, 0, 0, 0, 3'b000, 1, 0, 1, 32'h120, 32'h104, "JAL target");
    check(32'h100, 32'h20, 32'h200, 0, 0, 3'b000, 1, 1, 1, 32'h220, 32'h104, "JALR aligned target");
    $display("BRANCH SUMMARY | PASS=%0d FAIL=%0d", pass_count, fail_count);
    if (fail_count) $fatal(1, "Branch-unit test failed");
    $display("BRANCH ALL TESTS PASSED");
    $finish;
  end
endmodule
