`timescale 1ns/1ps
module memory_unit_tb;
  reg clk;
  reg [31:0] pc, addr, write_data;
  reg [3:0] write_strobe;
  reg mem_read, mem_write;
  wire [31:0] instruction, read_data;
  integer pass_count = 0, fail_count = 0;

  memory #(.IMEM_DEPTH(4), .DMEM_DEPTH(2)) dut (
    .clk(clk), .pc(pc), .addr(addr), .write_data(write_data),
    .write_strobe(write_strobe), .mem_read(mem_read), .mem_write(mem_write),
    .instruction(instruction), .read_data(read_data)
  );

  always #5 clk = ~clk;

  task check(input [31:0] expected_instruction, expected_read, input string name);
    begin
      #1;
      if (instruction === expected_instruction && read_data === expected_read) begin
        pass_count=pass_count+1;
        $display("PASS | MEMORY %s | pc=%08h addr=%08h | expected instruction/read=%08h/%08h actual=%08h/%08h",
                 name, pc, addr, expected_instruction, expected_read, instruction, read_data);
      end else begin
        fail_count=fail_count+1;
        $display("FAIL | MEMORY %s | pc=%08h addr=%08h | expected instruction/read=%08h/%08h actual=%08h/%08h",
                 name, pc, addr, expected_instruction, expected_read, instruction, read_data);
      end
    end
  endtask

  initial begin
    clk=0; pc=0; addr=0; write_data=0; write_strobe=0; mem_read=0; mem_write=0;
    dut.imem[0]=32'h12345678;
    dut.dmem[0]=32'h00000000;
    check(32'h12345678, 0, "combinational instruction read");
    addr=0; write_data=32'h0000beef; write_strobe=4'b0011; mem_write=1;
    @(posedge clk); #1; mem_write=0; mem_read=1;
    check(32'h12345678, 32'h0000beef, "halfword synchronous write/read");
    write_data=32'hab000000; write_strobe=4'b1000; mem_write=1; mem_read=0;
    @(posedge clk); #1; mem_write=0; mem_read=1;
    check(32'h12345678, 32'hab00beef, "byte-lane write");
    pc=32'h00000010; check(0, 32'hab00beef, "out-of-range instruction read");
    $display("MEMORY SUMMARY | PASS=%0d FAIL=%0d", pass_count, fail_count);
    if (fail_count) $fatal(1, "Memory test failed");
    $display("MEMORY ALL TESTS PASSED");
    $finish;
  end
endmodule
