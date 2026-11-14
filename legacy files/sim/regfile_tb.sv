/**
 * Register File Testbench
 * 
 * Comprehensive test suite for the 32x32 register file.
 * Tests read/write operations, x0 special handling, and edge cases.
 * 
 * @author Christian Watts
 * @version 1.0
 */

`timescale 1ns/1ps

module regfile_tb;

    reg clk;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] write_data;
    reg reg_write;
  
    wire [31:0] read_data1, read_data2;

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    regfile dut (
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .reg_write(reg_write),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Generate a 10 ns clock
    // Toggle every 5 ns
    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end
    
    initial begin
        $display("REGISTER FILE TESTBENCH");
        $display("");

        rs1 = 5'b0;
        rs2 = 5'b0;
        rd = 5'b0;
        write_data = 32'b0;
        reg_write = 1'b0;

        #10;

        test_count = test_count + 1;
        $display("[Test %0d] Basic write and read: x1", test_count);
        $display("  Action: Write 0x12345678 to x1");

        rs1 = 5'b00001;  // Read x1
        rd = 5'b00001;   // Write to x1
        write_data = 32'hDEADBEEF;  // Temp value 
        reg_write = 1'b0;  // Not writing yet
        #10;

        $display("  Clock cycle: Writing data...");
        write_data = 32'h12345678;
        reg_write = 1'b1;
        #10;

        $display("  Reading back x1...");
        reg_write = 1'b0; 
        #10;
        
        // Check
        if (read_data1 == 32'h12345678) begin
            $display("  ✓ PASS: read_data1 = 0x%08h", read_data1);
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ FAIL: Expected 0x12345678, got 0x%08h", read_data1);
            fail_count = fail_count + 1;
        end
        $display("");

        test_count = test_count + 1;
        $display("[Test %0d] x0 always returns 0 (read)", test_count);
        $display("  Action: Write 0xFFFFFFFF to x0, then read x0");
        
        $display("  Attempting write to x0...");
        rd = 5'b00000;   
        write_data = 32'hFFFFFFFF;
        reg_write = 1'b1;
        #10;  

        $display("  Reading from x0...");
        rs1 = 5'b00000;  
        reg_write = 1'b0;
        #10;

        if (read_data1 == 32'h00000000) begin
            $display("  ✓ PASS: read_data1 = 0x%08h (x0 hardwired to 0)", read_data1);
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ FAIL: Expected 0x00000000, got 0x%08h", read_data1);
            fail_count = fail_count + 1;
        end
        $display("");

        test_count = test_count + 1;
        $display("[Test %0d] Write to multiple registers (x2, x3, x4)", test_count);
        $display("  Action: Write different values to x2, x3, x4");
        

        $display("  Writing 0x22222222 to x2...");
        rd = 5'b00010;  
        write_data = 32'h22222222;
        reg_write = 1'b1;
        #10;
    
        $display("  Writing 0x33333333 to x3...");
        rd = 5'b00011;  
        write_data = 32'h33333333;
        #10;

        $display("  Writing 0x44444444 to x4...");
        rd = 5'b00100;  
        write_data = 32'h44444444;
        #10;

        $display("  Reading back x2, x3, x4...");
        reg_write = 1'b0;

        rs1 = 5'b00010;
        #10;
        if (read_data1 == 32'h22222222) begin
            $display("  ✓ x2 = 0x%08h", read_data1);
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ x2 FAILED: Expected 0x22222222, got 0x%08h", read_data1);
            fail_count = fail_count + 1;
        end

        rs1 = 5'b00011;
        #10;
        if (read_data1 == 32'h33333333) begin
            $display("  ✓ x3 = 0x%08h", read_data1);
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ x3 FAILED: Expected 0x33333333, got 0x%08h", read_data1);
            fail_count = fail_count + 1;
        end

        rs1 = 5'b00100;
        #10;
        if (read_data1 == 32'h44444444) begin
            $display("  ✓ x4 = 0x%08h", read_data1);
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ x4 FAILED: Expected 0x44444444, got 0x%08h", read_data1);
            fail_count = fail_count + 1;
        end
        $display("");

        test_count = test_count + 1;
        $display("[Test %0d] Simultaneous read and write", test_count);
        $display("  Action: Read x2 and x3 WHILE writing to x5");

        $display("  Setting up: rs1=2, rs2=3, rd=5, write_data=0x55555555");
        rs1 = 5'b00010;      // Read x2
        rs2 = 5'b00011;      // Read x3
        rd = 5'b00101;       // Write to x5
        write_data = 32'h55555555;
        reg_write = 1'b1;    // Enable
        #10;  // Clock edge happens

        if ((read_data1 == 32'h22222222) && (read_data2 == 32'h33333333)) begin
            $display("  ✓ PASS: Simultaneous read succeeded");
            $display("    read_data1 (x2) = 0x%08h", read_data1);
            $display("    read_data2 (x3) = 0x%08h", read_data2);
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ FAIL: Reads incorrect");
            $display("    read_data1 (x2) = 0x%08h (expected 0x22222222)", read_data1);
            $display("    read_data2 (x3) = 0x%08h (expected 0x33333333)", read_data2);
            fail_count = fail_count + 1;
        end

        $display("  Reading back x5 to verify write...");
        rs1 = 5'b00101;  // Read x5
        reg_write = 1'b0;  // Stop writing
        #10;
        
        if (read_data1 == 32'h55555555) begin
            $display("  ✓ PASS: Write to x5 succeeded");
            $display("    x5 = 0x%08h", read_data1);
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ FAIL: x5 write failed, got 0x%08h", read_data1);
            fail_count = fail_count + 1;
        end
        $display("");

        test_count = test_count + 1;
        $display("[Test %0d] Write enable control", test_count);
        $display("  Action: Try to write with reg_write=0 (should fail)");

        $display("  Setting rd=6, write_data=0x66666666, reg_write=0");
        rd = 5'b00110;
        write_data = 32'h66666666;
        reg_write = 1'b0;  // DISABLE
        #10;

        $display("  Reading x6 (should still be 0)...");
        rs1 = 5'b00110;
        #10;
        
        if (read_data1 == 32'h00000000) begin
            $display("  ✓ PASS: Write was blocked by reg_write=0");
            $display("    x6 = 0x%08h", read_data1);
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ FAIL: Write happened despite reg_write=0");
            $display("    x6 = 0x%08h (expected 0x00000000)", read_data1);
            fail_count = fail_count + 1;
        end
        $display("");

        test_count = test_count + 1;
        $display("[Test %0d] Edge case: x31 (highest register)", test_count);
        $display("  Action: Write and read x31");

        $display("  Writing 0xDEADBEEF to x31...");
        rd = 5'b11111;  // x31
        write_data = 32'hDEADBEEF;
        reg_write = 1'b1;
        #10;

        $display("  Reading x31...");
        rs1 = 5'b11111;
        reg_write = 1'b0;
        #10;
        
        if (read_data1 == 32'hDEADBEEF) begin
            $display("  ✓ PASS: x31 = 0x%08h", read_data1);
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ FAIL: Expected 0xDEADBEEF, got 0x%08h", read_data1);
            fail_count = fail_count + 1;
        end
        $display("");

        test_count = test_count + 1;
        $display("[Test %0d] Dual port simultaneous read", test_count);
        $display("  Action: Read from two different registers simultaneously");

        rs1 = 5'b00010;
        rs2 = 5'b00011;
        #10;
        
        if ((read_data1 == 32'h22222222) && (read_data2 == 32'h33333333)) begin
            $display("  ✓ PASS: Dual read successful");
            $display("    read_data1 (x2) = 0x%08h", read_data1);
            $display("    read_data2 (x3) = 0x%08h", read_data2);
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ FAIL: Dual read failed");
            $display("    read_data1 (x2) = 0x%08h (expected 0x22222222)", read_data1);
            $display("    read_data2 (x3) = 0x%08h (expected 0x33333333)", read_data2);
            fail_count = fail_count + 1;
        end
        $display("");

        $display("Total Tests:  %0d", test_count);
        $display("Passed:       %0d", pass_count);
        $display("Failed:       %0d", fail_count);
        $display("");
        
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
          $display("%0d TEST(S) FAILED", fail_count);
        end
        $finish;
    end

    initial begin
        $dumpfile("regfile.vcd");
        $dumpvars(0, regfile_tb);
    end

endmodule
