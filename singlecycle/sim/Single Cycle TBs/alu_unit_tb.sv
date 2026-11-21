`timescale 1ns/1ps
module alu_unit_tb;
  reg [31:0] a,b; reg [3:0] op; wire [31:0] result; wire zero,illegal_op;
  integer pass_count=0,fail_count=0;
  alu dut(.a(a),.b(b),.alu_op(op),.result(result),.zero(zero),.illegal_op(illegal_op));
  task check(input [3:0] code,input [31:0] lhs,rhs,expected,input string name);
    begin a=lhs;b=rhs;op=code;#1;
      if(result===expected && !illegal_op) begin pass_count=pass_count+1;
        $display("PASS | ALU op=%h | %s | a=%h b=%h | expected=%h actual=%h",code,name,lhs,rhs,expected,result); end
      else begin fail_count=fail_count+1;
        $display("FAIL | ALU op=%h | %s | a=%h b=%h | expected=%h actual=%h illegal=%b",code,name,lhs,rhs,expected,result,illegal_op); end
    end
  endtask
  initial begin
    check(0,32'd7,32'd5,32'd12,"ADD"); check(1,7,5,2,"SUB");
    check(2,32'hf0,32'h3c,32'h30,"AND"); check(3,32'hf0,32'h3c,32'hfc,"OR");
    check(4,32'hf0,32'h3c,32'hcc,"XOR"); check(5,32'hffff_ffff,1,1,"SLT signed");
    check(6,32'hffff_ffff,1,0,"SLTU unsigned"); check(7,1,4,16,"SLL");
    check(8,32'h8000_0000,1,32'h4000_0000,"SRL");
    check(9,32'h8000_0000,1,32'hc000_0000,"SRA");
    check(0,32'hffff_ffff,1,0,"ADD wraparound");
    check(1,0,1,32'hffff_ffff,"SUB underflow");
    check(5,32'h8000_0000,0,1,"SLT minimum signed");
    check(5,0,32'h8000_0000,0,"SLT signed boundary");
    check(6,32'hffff_ffff,0,1,"SLTU maximum unsigned");
    check(6,0,32'hffff_ffff,1,"SLTU unsigned boundary");
    check(7,32'h8000_0000,31,0,"SLL shift amount 31");
    check(8,32'h8000_0000,31,1,"SRL shift amount 31");
    check(9,32'h8000_0000,31,32'hffff_ffff,"SRA shift amount 31");
    a=1;b=2;op=15;#1;
    if(illegal_op && result==0) begin pass_count++;$display("PASS | ALU op=f | illegal op | expected=illegal/0 actual=illegal/%h",result); end
    else begin fail_count++;$display("FAIL | ALU op=f | illegal op | expected=illegal/0 actual=%b/%h",illegal_op,result); end
    $display("ALU SUMMARY | PASS=%0d FAIL=%0d",pass_count,fail_count);
    if(fail_count) begin
      $display("ALU FAILED CASES: see FAIL lines above.");
      $fatal(1, "ALU unit test failed");
    end else begin
      $display("ALU ALL TESTS PASSED");
    end
    $finish;
  end
endmodule
