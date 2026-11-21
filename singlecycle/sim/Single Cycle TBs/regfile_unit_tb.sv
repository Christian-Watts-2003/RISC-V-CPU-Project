`timescale 1ns/1ps
module regfile_unit_tb;
  reg clk;
  reg [4:0] rs1, rs2, rd;
  reg [31:0] write_data;
  reg reg_write;
  wire [31:0] read_data1, read_data2;
  integer pass_count = 0, fail_count = 0;

  regfile dut (
    .clk(clk), .rs1(rs1), .rs2(rs2), .rd(rd),
    .write_data(write_data), .reg_write(reg_write),
    .read_data1(read_data1), .read_data2(read_data2)
  );

  always #5 clk = ~clk;

  task check(input [31:0] expected1, input [31:0] expected2, input string name);
    begin
      #1;
      if (read_data1 === expected1 && read_data2 === expected2) begin
        pass_count = pass_count + 1;
        $display("PASS | REGFILE %s | rs1=x%0d rs2=x%0d | expected=%08h/%08h actual=%08h/%08h",
                 name, rs1, rs2, expected1, expected2, read_data1, read_data2);
      end else begin
        fail_count = fail_count + 1;
        $display("FAIL | REGFILE %s | rs1=x%0d rs2=x%0d | expected=%08h/%08h actual=%08h/%08h",
                 name, rs1, rs2, expected1, expected2, read_data1, read_data2);
      end
    end
  endtask

  initial begin
    clk=0; rs1=0; rs2=0; rd=0; write_data=0; reg_write=0;
    check(0, 0, "x0 reset value");
    rd=5'd5; write_data=32'h12345678; reg_write=1;
    @(posedge clk); #1; reg_write=0; rs1=5; rs2=5;
    check(32'h12345678, 32'h12345678, "write and read x5");
    rd=5'd31; write_data=32'hffffffff; reg_write=1; @(posedge clk); #1;
    reg_write=0; rs1=31; rs2=31; check(32'hffffffff, 32'hffffffff, "highest register x31");
    rs1=5; rs2=5; check(32'h12345678, 32'h12345678, "register retention");
    rd=5'd6; write_data=32'hdeadbeef; reg_write=0; @(posedge clk);
    rs1=6; rs2=0; check(0, 0, "write disabled and x0");
    rd=5'd0; write_data=32'hffffffff; reg_write=1; @(posedge clk);
    reg_write=0; rs1=0; rs2=5; check(0, 32'h12345678, "x0 write ignored");
    rd=5'd7; write_data=32'hcafebabe; reg_write=1; rs1=7; rs2=7;
    check(0, 0, "same-cycle read uses old value");
    @(posedge clk); #1; reg_write=0; check(32'hcafebabe, 32'hcafebabe, "stored value");
    $display("REGFILE SUMMARY | PASS=%0d FAIL=%0d", pass_count, fail_count);
    if (fail_count) $fatal(1, "Register-file test failed");
    $display("REGFILE ALL TESTS PASSED");
    $finish;
  end
endmodule
