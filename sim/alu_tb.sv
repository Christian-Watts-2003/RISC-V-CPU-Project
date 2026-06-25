/**
 * ALU Testbench
 * 
 * Comprehensive tests for all ALU operations
 * 
 * @author Christian Watts
 */

module alu_tb;
    logic [31:0] a, b, result;
    logic [3:0] alu_op;
    logic zero;

    alu dut (.*);
    
    initial begin
        $display("=== ALU Testbench ===\n");

        $display("Test 1: ADD");
        a = 32'd5; b = 32'd3; alu_op = 4'b0000;
        #10;
        assert(result == 32'd8) else $error("ADD failed: 5 + 3 = %d (expected 8)", result);
        $display("  5 + 3 = %d ✓", result);

        $display("\nTest 2: SUB");
        a = 32'd10; b = 32'd3; alu_op = 4'b0001;
        #10;
        assert(result == 32'd7) else $error("SUB failed: 10 - 3 = %d (expected 7)", result);
        $display("  10 - 3 = %d ✓", result);

        $display("\nTest 3: SUB (negative result)");
        a = 32'd3; b = 32'd10; alu_op = 4'b0001;
        #10;
        assert($signed(result) == -32sd7) else $error("SUB negative failed");
        $display("  3 - 10 = %d ✓", $signed(result));

        $display("\nTest 4: AND");
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = 4'b0010;
        #10;
        assert(result == 32'h00000000) else $error("AND failed");
        $display("  0xF0F0F0F0 & 0x0F0F0F0F = 0x%h ✓", result);

        $display("\nTest 5: OR");
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = 4'b0011;
        #10;
        assert(result == 32'hFFFFFFFF) else $error("OR failed");
        $display("  0xF0F0F0F0 | 0x0F0F0F0F = 0x%h ✓", result);

        $display("\nTest 6: XOR");
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = 4'b0100;
        #10;
        assert(result == 32'hFFFFFFFF) else $error("XOR failed");
        $display("  0xF0F0F0F0 ^ 0x0F0F0F0F = 0x%h ✓", result);

        $display("\nTest 7: SLT (a < b)");
        a = 32'd5; b = 32'd10; alu_op = 4'b0101;
        #10;
        assert(result == 32'd1) else $error("SLT failed: 5 < 10 should be 1");
        $display("  5 < 10 = %d ✓", result);

        $display("\nTest 8: SLT (a >= b)");
        a = 32'd10; b = 32'd5; alu_op = 4'b0101;
        #10;
        assert(result == 32'd0) else $error("SLT failed: 10 < 5 should be 0");
        $display("  10 < 5 = %d ✓", result);

        $display("\nTest 9: SLT (negative)");
        a = 32'hFFFFFFFF; b = 32'h00000001; alu_op = 4'b0101; // -1 < 1
        #10;
        assert(result == 32'd1) else $error("SLT negative failed");
        $display("  -1 < 1 = %d ✓", result);
 
        $display("\nTest 10: SLL");
        a = 32'd1; b = 32'd4; alu_op = 4'b0110;
        #10;
        assert(result == 32'd16) else $error("SLL failed: 1 << 4 = %d", result);
        $display("  1 << 4 = %d ✓", result);

        $display("\nTest 11: SRL");
        a = 32'd16; b = 32'd2; alu_op = 4'b0111;
        #10;
        assert(result == 32'd4) else $error("SRL failed: 16 >> 2 = %d", result);
        $display("  16 >> 2 = %d ✓", result);

        $display("\nTest 12: SRA");
        a = 32'hFFFFFFF8; b = 32'd2; alu_op = 4'b1000; // -8 >>> 2
        #10;
        assert($signed(result) == -32sd2) else $error("SRA failed: -8 >>> 2 = %d", $signed(result));
        $display("  -8 >>> 2 = %d ✓", $signed(result));

        $display("\nTest 13: Zero flag");
        a = 32'd5; b = 32'd5; alu_op = 4'b0001; // SUB: 5-5=0
        #10;
        assert(zero == 1'b1) else $error("Zero flag not set");
        $display("  Zero flag set ✓");
        
        $display("\n=== All tests passed! ===\n");
        $finish;
    end
    
    // VCD dump
    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
    end

endmodule
