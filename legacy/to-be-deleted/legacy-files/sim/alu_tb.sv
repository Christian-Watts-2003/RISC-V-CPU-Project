/**
 * ALU Testbench
 * 
 * Comprehensive tests for all ALU operations
 * 
 * @author Christian Watts
 */

module alu_tb;
    reg [31:0] a, b;
    reg [3:0] alu_op;
    wire [31:0] result;
    wire zero;
    
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    alu dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero)
    );
    
    initial begin
        $display("      ALU TESTBENCH - RISC-V Processor");
        $display("");
        
        // TEST 1: ADD basic: 5 + 3 = 8
        test_count = test_count + 1;
        $display("[Test %0d] ADD: 5 + 3 = 8", test_count);
        a = 32'h00000005;
        b = 32'h00000003;
        alu_op = 4'b0000;
        #10;
        if (result == 32'h00000008) begin
            $display("         PASS: result=0x%08h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected 0x00000008, got 0x%08h", result);
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 2: ADD zero operands: 0 + 0 = 0
        test_count = test_count + 1;
        $display("[Test %0d] ADD: 0 + 0 = 0 (zero flag)", test_count);
        a = 32'h00000000;
        b = 32'h00000000;
        alu_op = 4'b0000;
        #10;
        if ((result == 32'h00000000) && (zero == 1'b1)) begin
            $display("         PASS: result=0x%08h, zero=1", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected result=0, zero=1");
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 3: SUB basic: 10 - 3 = 7
        test_count = test_count + 1;
        $display("[Test %0d] SUB: 10 - 3 = 7", test_count);
        a = 32'h0000000A;  // 10
        b = 32'h00000003;  // 3
        alu_op = 4'b0001;
        #10;
        if (result == 32'h00000007) begin
            $display("         PASS: result=0x%08h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected 0x00000007, got 0x%08h", result);
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 4: SUB resulting in zero
        test_count = test_count + 1;
        $display("[Test %0d] SUB: 5 - 5 = 0", test_count);
        a = 32'h00000005;
        b = 32'h00000005;
        alu_op = 4'b0001;
        #10;
        if ((result == 32'h00000000) && (zero == 1'b1)) begin
            $display("         PASS: result=0x%08h, zero=1", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected result=0, zero=1");
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 5: AND operation
        test_count = test_count + 1;
        $display("[Test %0d] AND: 0xF0F0F0F0 & 0x0F0F0F0F = 0", test_count);
        a = 32'hF0F0F0F0;
        b = 32'h0F0F0F0F;
        alu_op = 4'b0010;
        #10;
        if (result == 32'h00000000) begin
            $display("         PASS: result=0x%08h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected 0x00000000, got 0x%08h", result);
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 6: OR operation
        test_count = test_count + 1;
        $display("[Test %0d] OR: 0xF0F0F0F0 | 0x0F0F0F0F = 0xFFFFFFFF", test_count);
        a = 32'hF0F0F0F0;
        b = 32'h0F0F0F0F;
        alu_op = 4'b0011;
        #10;
        if (result == 32'hFFFFFFFF) begin
            $display("         PASS: result=0x%08h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected 0xFFFFFFFF, got 0x%08h", result);
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 7: XOR operation
        test_count = test_count + 1;
        $display("[Test %0d] XOR: 0x12345678 ^ 0x12345678 = 0", test_count);
        a = 32'h12345678;
        b = 32'h12345678;
        alu_op = 4'b0100;
        #10;
        if (result == 32'h00000000) begin
            $display("         PASS: result=0x%08h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected 0x00000000, got 0x%08h", result);
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 8: SLT - true case
        test_count = test_count + 1;
        $display("[Test %0d] SLT: 5 < 10 = 1", test_count);
        a = 32'h00000005;
        b = 32'h0000000A;
        alu_op = 4'b0101;
        #10;
        if (result == 32'h00000001) begin
            $display("         PASS: result=0x%08h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected 0x00000001, got 0x%08h", result);
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 9: SLT - false case
        test_count = test_count + 1;
        $display("[Test %0d] SLT: 10 < 5 = 0", test_count);
        a = 32'h0000000A;
        b = 32'h00000005;
        alu_op = 4'b0101;
        #10;
        if (result == 32'h00000000) begin
            $display("         PASS: result=0x%08h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected 0x00000000, got 0x%08h", result);
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 10: SLL - shift left
        test_count = test_count + 1;
        $display("[Test %0d] SLL: 1 << 4 = 16", test_count);
        a = 32'h00000001;
        b = 32'h00000004;
        alu_op = 4'b0110;
        #10;
        if (result == 32'h00000010) begin
            $display("         PASS: result=0x%08h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected 0x00000010, got 0x%08h", result);
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 11: SRL - logical right shift
        test_count = test_count + 1;
        $display("[Test %0d] SRL: 16 >> 2 = 4", test_count);
        a = 32'h00000010;
        b = 32'h00000002;
        alu_op = 4'b0111;
        #10;
        if (result == 32'h00000004) begin
            $display("         PASS: result=0x%08h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected 0x00000004, got 0x%08h", result);
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Test 12: SRA - arithmetic right shift
        test_count = test_count + 1;
        $display("[Test %0d] SRA: -8 >>> 2 = -2", test_count);
        a = 32'hFFFFFFF8;  // -8 in two's complement
        b = 32'h00000002;
        alu_op = 4'b1000;
        #10;
        if (result == 32'hFFFFFFFE) begin  // -2 in two's complement
            $display("         PASS: result=0x%08h", result);
            pass_count = pass_count + 1;
        end else begin
            $display("         FAIL: expected 0xFFFFFFFE, got 0x%08h", result);
            fail_count = fail_count + 1;
        end
        $display("");
        
        // Summary
        $display("      TEST SUMMARY");
        $display("");
        $display("Total Tests:  %0d", test_count);
        $display("Passed:       %0d", pass_count);
        $display("Failed:       %0d", fail_count);
        $display("");
        
        if (fail_count == 0) begin
            $display("✓ ALL TESTS PASSED!");
        end else begin
            $display("✗ %0d TEST(S) FAILED", fail_count);
        end

        $display("");
        
        $finish;
    end
    
    // VCD dump
    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
    end

endmodule
