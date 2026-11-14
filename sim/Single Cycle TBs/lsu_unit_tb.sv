`timescale 1ns/1ps
module lsu_unit_tb;
  reg [31:0] address,store_data,read_word;reg [1:0] size;reg load_unsigned;
  wire [31:0] dmem_addr,dmem_wdata,load_data;wire [3:0] dmem_wstrb;
  integer pass_count=0,fail_count=0;
  lsu dut(.address(address),.store_data(store_data),.size(size),.load_unsigned(load_unsigned),.read_word(read_word),.dmem_addr(dmem_addr),.dmem_wdata(dmem_wdata),.dmem_wstrb(dmem_wstrb),.load_data(load_data));
  task check(input [31:0] addr,word,data,input [1:0] width,input uns,
             input [31:0] exp_load,exp_store,input [3:0] exp_strobe,input string name);
    begin address=addr;read_word=word;store_data=data;size=width;load_unsigned=uns;#1;
      if(load_data===exp_load&&dmem_wdata===exp_store&&dmem_wstrb===exp_strobe&&dmem_addr=={addr[31:2],2'b00}) begin pass_count++;$display("PASS | LSU %s | addr=%08h word=%08h store=%08h size=%0d unsigned=%b | expected load/store/strobe=%08h/%08h/%b actual=%08h/%08h/%b",name,addr,word,data,width,uns,exp_load,exp_store,exp_strobe,load_data,dmem_wdata,dmem_wstrb);end
      else begin fail_count++;$display("FAIL | LSU %s | addr=%08h word=%08h store=%08h size=%0d unsigned=%b | expected load/store/strobe=%08h/%08h/%b actual=%08h/%08h/%b",name,addr,word,data,width,uns,exp_load,exp_store,exp_strobe,load_data,dmem_wdata,dmem_wstrb);end
    end
  endtask
  initial begin
    check(0,32'h80ff_7f01,32'h0000_00ab,0,0,32'h0000_0001,32'h0000_00ab,1,"SB/lane0 and LB positive");
    check(1,32'h80ff_7f01,32'h0000_00ab,0,1,32'h0000_007f,32'h0000_ab00,2,"SB/lane1 and LBU");
    check(2,32'h80ff_7f01,32'h0000_1234,1,0,32'hffff_80ff,32'h1234_0000,12,"SH upper lane and LH sign");
    check(3,32'hff00_0080,32'h0000_00cd,0,0,32'hffff_ff00,32'hcd00_0000,8,"SB/lane3 and LB sign");
    check(3,32'hff00_0080,32'h0000_00cd,0,1,32'h0000_00ff,32'hcd00_0000,8,"SB/lane3 and LBU");
    check(0,32'hffff_8000,32'h0000_8001,1,0,32'hffff_8000,32'h8001_0000,3,"SH/lane0 and LH sign");
    check(0,32'h1234_5678,32'h1234_5678,3,0,32'h0000_0000,32'h1234_5678,0,"Invalid size");
    check(0,32'h80ff_7f01,32'h1234_5678,2,0,32'h80ff_7f01,32'h1234_5678,15,"SW/LW");
    $display("LSU SUMMARY | PASS=%0d FAIL=%0d",pass_count,fail_count);
    if(fail_count) begin
      $display("LSU FAILED CASES: see FAIL lines above.");
      $fatal(1, "LSU unit test failed");
    end else begin
      $display("LSU ALL TESTS PASSED");
    end
    $finish;
  end
endmodule
