`timescale 1ns/1ps
module muldiv_unit_tb;
  reg clk, reset, start;
  reg [2:0] op;
  reg [31:0] a, b;
  wire [31:0] result;
  wire valid;
  integer pass_count = 0, fail_count = 0;

  muldiv dut (
    .clk(clk), .reset(reset), .start(start), .muldiv_op(op),
    .a(a), .b(b), .result(result), .valid(valid)
  );

  task check(input [2:0] test_op, input [31:0] lhs, rhs, expected, input string name);
    begin
      op=test_op; a=lhs; b=rhs; start=1; #1;
      if (result === expected && valid === 1'b1) begin
        pass_count = pass_count + 1;
        $display("PASS | MULDIV %s | op=%03b a=%08h b=%08h | expected=%08h actual=%08h valid=%b",
                 name, test_op, lhs, rhs, expected, result, valid);
      end else begin
        fail_count = fail_count + 1;
        $display("FAIL | MULDIV %s | op=%03b a=%08h b=%08h | expected=%08h actual=%08h valid=%b",
                 name, test_op, lhs, rhs, expected, result, valid);
      end
    end
  endtask

  initial begin
    clk=0; reset=0; start=0; op=0; a=0; b=0;
    check(3'b000, 32'h80000000, 32'hffffffff, 32'h80000000, "MUL low");
    check(3'b001, 32'h80000000, 32'hffffffff, 32'h00000000, "MULH");
    check(3'b010, 32'h80000000, 32'hffffffff, 32'h80000000, "MULHSU");
    check(3'b011, 32'h80000000, 32'hffffffff, 32'h7fffffff, "MULHU");
    check(3'b100, 32'h80000000, 32'hffffffff, 32'h80000000, "DIV overflow");
    check(3'b110, 32'h80000000, 32'hffffffff, 32'h00000000, "REM overflow");
    check(3'b100, 32'h12345678, 32'h00000000, 32'hffffffff, "DIV by zero");
    check(3'b101, 32'h12345678, 32'h00000000, 32'hffffffff, "DIVU by zero");
    check(3'b110, 32'h12345678, 32'h00000000, 32'h12345678, "REM by zero");
    check(3'b111, 32'h12345678, 32'h00000000, 32'h12345678, "REMU by zero");
    start=0; #1;
    if (valid === 1'b0) begin pass_count=pass_count+1; $display("PASS | MULDIV idle valid | expected=0 actual=%b", valid); end
    else begin fail_count=fail_count+1; $display("FAIL | MULDIV idle valid | expected=0 actual=%b", valid); end
    $display("MULDIV SUMMARY | PASS=%0d FAIL=%0d", pass_count, fail_count);
    if (fail_count) $fatal(1, "Muldiv test failed");
    $display("MULDIV ALL TESTS PASSED");
    $finish;
  end
endmodule
