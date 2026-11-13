`timescale 1ns/1ps
module imm_gen_unit_tb;
  reg [31:0] insn;reg [2:0] format;wire [31:0] imm;
  integer pass_count=0,fail_count=0;
  imm_gen dut(.instruction(insn),.imm_src(format),.imm_value(imm));
  task check(input [2:0] f,input [31:0] code,input [31:0] expected,input string name);
    begin format=f;insn=code;#1;
      if(imm===expected) begin pass_count++;$display("PASS | instruction=%08h | immediate %s | format=%0d expected=%08h actual=%08h",code,name,f,expected,imm);end
      else begin fail_count++;$display("FAIL | instruction=%08h | immediate %s | format=%0d expected=%08h actual=%08h",code,name,f,expected,imm);end
    end
  endtask
  initial begin
    check(0,32'hfff00093,32'hffff_ffff,"I-type sign extension (-1)");
    check(1,32'hfe208fa3,32'hffff_ffff,"S-type sign extension (-1)");
    check(2,32'hfe208ee3,32'hffff_fffc,"B-type negative aligned offset");
    check(3,32'h800000b7,32'h8000_0000,"U-type upper immediate");
    check(4,32'hff1ff0ef,32'hffff_fffe,"J-type negative aligned offset");
    format=7;insn=0;#1;
    if(imm===0) begin pass_count++;$display("PASS | instruction=00000000 | invalid format default | expected=00000000 actual=%08h",imm);end
    else begin fail_count++;$display("FAIL | instruction=00000000 | invalid format default | expected=00000000 actual=%08h",imm);end
    $display("IMM_GEN SUMMARY | PASS=%0d FAIL=%0d",pass_count,fail_count);
    if(fail_count) $display("IMM_GEN FAILED CASES: see FAIL lines above.");else $display("IMM_GEN ALL TESTS PASSED");$finish;
  end
endmodule
