`timescale 1ns/1ps
module single_cycle_tb;
    reg clk=0;
    reg reset=1;
    always #5 clk=~clk;

    top #(.IMEM_DEPTH(64), .DMEM_DEPTH(16)) dut (.clk(clk), .reset(reset));

    function automatic [31:0] enc_i(
        input integer imm, input [4:0] rs1, input [2:0] funct3,
        input [4:0] rd, input [6:0] opcode
    );
        enc_i={imm[11:0],rs1,funct3,rd,opcode};
    endfunction
    function automatic [31:0] enc_r(
        input [6:0] funct7, input [4:0] rs2, input [4:0] rs1,
        input [2:0] funct3, input [4:0] rd
    );
        enc_r={funct7,rs2,rs1,funct3,rd,7'b0110011};
    endfunction
    function automatic [31:0] enc_s(
        input integer imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3
    );
        enc_s={imm[11:5],rs2,rs1,funct3,imm[4:0],7'b0100011};
    endfunction
    function automatic [31:0] enc_b(
        input integer imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3
    );
        enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], 7'b1100011};
    endfunction
    function automatic [31:0] enc_u(input [19:0] imm, input [4:0] rd, input [6:0] opcode);
        enc_u={imm,rd,opcode};
    endfunction
    function automatic [31:0] enc_j(input integer imm, input [4:0] rd);
        enc_j={imm[20],imm[10:1],imm[11],imm[19:12],rd,7'b1101111};
    endfunction

    task automatic check_reg(input integer index, input [31:0] expected);
        begin
            if (dut.u_cpu.u_datapath.u_regfile.registers[index] !== expected) begin
                $display("FAIL x%0d expected %08x got %08x", index, expected,
                         dut.u_cpu.u_datapath.u_regfile.registers[index]);
                $fatal(1);
            end
        end
    endtask

    integer i;
    initial begin
        // Allow memory's initialization block to finish, then fill a short
        // machine-code program. Data words are initialized by the memory model.
        #1;
        for (i=0;i<64;i=i+1) dut.u_memory.imem[i]=32'h00000013; // ADDI x0,x0,0
        dut.u_memory.imem[0]  = enc_i(-128,0,3'b000,1,7'b0010011); // addi x1,x0,-128
        dut.u_memory.imem[1]  = enc_s(0,1,0,3'b000);                // sb x1,0(x0)
        dut.u_memory.imem[2]  = enc_i(0,0,3'b000,2,7'b0000011);    // lb x2,0(x0)
        dut.u_memory.imem[3]  = enc_i(0,0,3'b100,3,7'b0000011);    // lbu x3,0(x0)
        dut.u_memory.imem[4]  = enc_i('h123,0,3'b000,4,7'b0010011);// addi x4,x0,0x123
        dut.u_memory.imem[5]  = enc_s(2,4,0,3'b001);               // sh x4,2(x0)
        dut.u_memory.imem[6]  = enc_i(2,0,3'b001,5,7'b0000011);    // lh x5,2(x0)
        dut.u_memory.imem[7]  = enc_i(2,0,3'b101,6,7'b0000011);    // lhu x6,2(x0)
        dut.u_memory.imem[8]  = enc_s(4,4,0,3'b010);               // sw x4,4(x0)
        dut.u_memory.imem[9]  = enc_i(4,0,3'b010,7,7'b0000011);    // lw x7,4(x0)
        dut.u_memory.imem[10] = enc_u(20'h80000,8,7'b0110111);     // lui x8,0x80000
        dut.u_memory.imem[11] = enc_i(-1,0,3'b000,9,7'b0010011);   // addi x9,x0,-1
        dut.u_memory.imem[12] = enc_r(0,9,8,3'b000,10);            // add x10,x8,x9
        dut.u_memory.imem[13] = enc_r(0,8,9,3'b011,11);            // sltu x11,x9,x8
        dut.u_memory.imem[14] = enc_r(0,9,8,3'b010,12);            // slt x12,x8,x9
        dut.u_memory.imem[15] = enc_r(7'b0100000,14,9,3'b101,13); // sra x13,x9,x14 (shift 0 until x14 set)
        dut.u_memory.imem[16] = enc_i(1,0,3'b000,14,7'b0010011);   // addi x14,x0,1
        dut.u_memory.imem[17] = enc_r(7'b0100000,14,9,3'b101,13); // sra x13,x9,x14
        dut.u_memory.imem[18] = enc_b(8,6,6,3'b000);               // beq x6,x6,+8
        dut.u_memory.imem[19] = enc_i(1,0,3'b000,15,7'b0010011);   // skipped
        dut.u_memory.imem[20] = enc_j(8,16);                       // jal x16,+8
        dut.u_memory.imem[21] = enc_i(2,0,3'b000,15,7'b0010011);   // skipped
        dut.u_memory.imem[22] = enc_i(96,0,3'b000,17,7'b0010011);
        dut.u_memory.imem[23] = enc_i(0,17,3'b000,18,7'b1100111); // jalr x18,x17,0 -> address 96
        dut.u_memory.imem[24] = enc_r(1,9,8,3'b000,19);            // mul x19,x8,x9
        dut.u_memory.imem[25] = enc_r(1,9,8,3'b001,20);            // mulh x20,x8,x9
        dut.u_memory.imem[26] = enc_r(1,9,8,3'b010,21);            // mulhsu x21,x8,x9
        dut.u_memory.imem[27] = enc_r(1,9,8,3'b011,22);            // mulhu x22,x8,x9
        dut.u_memory.imem[28] = enc_r(1,0,8,3'b100,23);             // div x23,x8,x0
        dut.u_memory.imem[29] = enc_r(1,0,8,3'b110,24);             // rem x24,x8,x0
        dut.u_memory.imem[30] = enc_r(1,9,8,3'b100,25);            // div x25,x8,x9 overflow
        dut.u_memory.imem[31] = enc_r(1,9,8,3'b110,26);            // rem x26,x8,x9 overflow
        dut.u_memory.imem[32] = enc_j(0,0);                         // stop: jal x0,0

        repeat (2) @(posedge clk);
        @(negedge clk) reset=0;
        repeat (45) @(posedge clk);
        #1;

        check_reg(2,32'hffff_ff80);
        check_reg(0,32'h0000_0000);
        check_reg(3,32'h0000_0080);
        check_reg(5,32'h0000_0123);
        check_reg(6,32'h0000_0123);
        check_reg(7,32'h0000_0123);
        check_reg(10,32'h7fff_ffff);
        check_reg(11,32'h0000_0000);
        check_reg(12,32'h0000_0001);
        check_reg(13,32'hffff_ffff);
        check_reg(15,32'h0000_0000);
        check_reg(16,32'd84);
        check_reg(18,32'd96);
        check_reg(19,32'h8000_0000);
        check_reg(20,32'h0000_0000);
        check_reg(21,32'h8000_0000);
        check_reg(22,32'h7fff_ffff);
        check_reg(23,32'hffff_ffff);
        check_reg(24,32'h8000_0000);
        check_reg(25,32'h8000_0000);
        check_reg(26,32'h0000_0000);

        if (dut.u_memory.dmem[0] !== 32'h0123_0080) begin
            $display("FAIL dmem[0] expected 01230080 got %08x",dut.u_memory.dmem[0]);
            $fatal(1);
        end
        if (dut.u_memory.dmem[1] !== 32'h0000_0123) begin
            $display("FAIL dmem[1] expected 00000123 got %08x",dut.u_memory.dmem[1]);
            $fatal(1);
        end
        $display("PASS single_cycle_tb");
        $finish;
    end
    initial begin
        #2000; $fatal(1,"TIMEOUT");
    end
endmodule
