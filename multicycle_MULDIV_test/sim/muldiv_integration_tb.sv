`timescale 1ns/1ps

module muldiv_integration_tb;
    reg clk = 0;
    reg reset = 1;
    reg enable = 0;
    reg mem_ready = 1;
    reg [31:0] imem [0:127];
    reg [31:0] dmem [0:3];
    reg [31:0] expected_value [0:127];
    integer expected_rd [0:127];
    reg [31:0] expected_regs [0:31];
    integer program_length = 0;
    integer retired = 0, reads = 0, writes = 0;
    integer store_pc, load_pc;
    reg execute_pause_done = 0, wb_pause_done = 0, memory_pause_done = 0;

    wire [31:0] pc, mem_addr, mem_write_data;
    wire [31:0] retire_pc, retire_instruction;
    wire [3:0] mem_write_strobe;
    wire mem_valid, mem_read, mem_write, retire_valid;
    wire [31:0] instruction = (pc[31:2] < 128) ? imem[pc[31:2]] : 32'b0;
    wire [31:0] mem_read_data = (mem_addr[31:2] < 4) ? dmem[mem_addr[31:2]] : 32'b0;

    always #5 clk = ~clk;

    rv32im_multicycle dut (
        .clk(clk), .reset(reset), .enable(enable),
        .instruction(instruction), .mem_read_data(mem_read_data), .mem_ready(mem_ready),
        .pc(pc), .mem_addr(mem_addr), .mem_write_data(mem_write_data),
        .mem_write_strobe(mem_write_strobe), .mem_valid(mem_valid),
        .mem_read(mem_read), .mem_write(mem_write), .retire_valid(retire_valid),
        .retire_pc(retire_pc), .retire_instruction(retire_instruction)
    );

    function [31:0] enc_i(input integer imm, input integer rs1,
                          input integer f3, input integer rd, input integer op);
        enc_i = ((imm & 12'hfff) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op;
    endfunction

    function [31:0] enc_r(input integer f7, input integer rs2, input integer rs1,
                          input integer f3, input integer rd);
        enc_r = (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 7'h33;
    endfunction

    function [31:0] enc_s(input integer imm, input integer rs2, input integer rs1,
                          input integer f3);
        enc_s = (((imm >> 5) & 7'h7f) << 25) | (rs2 << 20) | (rs1 << 15) |
                (f3 << 12) | ((imm & 5'h1f) << 7) | 7'h23;
    endfunction

    task emit(input [31:0] insn, input integer rd, input [31:0] value);
        begin
            imem[program_length] = insn;
            expected_rd[program_length] = rd;
            expected_value[program_length] = value;
            program_length = program_length + 1;
        end
    endtask

    task m(input integer f3, input integer rs1, input integer rs2,
           input integer rd, input [31:0] value);
        emit(enc_r(1, rs2, rs1, f3, rd), rd, value);
    endtask

    always @(posedge clk) begin
        if (!reset && enable && mem_valid && mem_ready) begin
            if (mem_addr !== 0 || mem_read === mem_write)
                $fatal(1, "FAIL unexpected memory request addr=%08x read=%b write=%b",
                       mem_addr, mem_read, mem_write);
            if (mem_write) begin
                if (writes != 0 || mem_write_strobe !== 4'b1111 ||
                    mem_write_data !== 32'hffffffeb)
                    $fatal(1, "FAIL store data=%08x strobe=%b", mem_write_data, mem_write_strobe);
                dmem[0] <= mem_write_data;
                writes = writes + 1;
                $display("PASS store data=%08x", mem_write_data);
            end else begin
                if (reads != 0 || mem_read_data !== 32'hffffffeb)
                    $fatal(1, "FAIL load data=%08x", mem_read_data);
                reads = reads + 1;
                $display("PASS load data=%08x", mem_read_data);
            end
        end
    end

    always @(posedge clk) begin
        #1;
        if (!reset && retire_valid) begin
            if (retired >= program_length ||
                retire_pc !== 4*retired || retire_instruction !== imem[retired])
                $fatal(1, "FAIL retirement %0d PC=%08x instruction=%08x",
                       retired, retire_pc, retire_instruction);
            if (expected_rd[retired] > 0)
                expected_regs[expected_rd[retired]] = expected_value[retired];
            for (integer r = 0; r < 32; r = r + 1)
                if (dut.u_regfile.registers[r] !== expected_regs[r])
                    $fatal(1, "FAIL PC=%08x x%0d expected=%08x actual=%08x",
                           retire_pc, r, expected_regs[r], dut.u_regfile.registers[r]);
            $display("PASS retire %0d PC=%08x instruction=%08x rd=%0d result=%08x",
                     retired + 1, retire_pc, retire_instruction,
                     expected_rd[retired], expected_value[retired]);
            retired = retired + 1;
        end
    end

    initial begin : program_and_checks
        integer i;
        for (i = 0; i < 128; i = i + 1) begin
            imem[i] = 32'h00000013;
            expected_rd[i] = -1;
            expected_value[i] = 0;
        end
        for (i = 0; i < 32; i = i + 1) expected_regs[i] = 0;
        for (i = 0; i < 4; i = i + 1) dmem[i] = 0;

        emit(enc_i(-7, 0, 0, 1, 'h13), 1, 32'hfffffff9);
        emit(enc_i(3, 0, 0, 2, 'h13), 2, 3);
        m(0, 1, 2, 3, 32'hffffffeb);
        m(1, 1, 2, 3, 32'hffffffff);
        m(2, 1, 2, 3, 32'hffffffff);
        m(3, 1, 2, 3, 32'h00000002);
        m(4, 1, 2, 3, 32'hfffffffe);
        m(5, 1, 2, 3, 32'h55555553);
        m(6, 1, 2, 3, 32'hffffffff);
        m(7, 1, 2, 3, 0);
        m(0, 1, 2, 3, 32'hffffffeb);
        m(0, 3, 2, 4, 32'hffffffc1);
        m(0, 1, 2, 0, 0);

        emit(enc_i(-1, 0, 0, 5, 'h13), 5, 32'hffffffff);
        emit(32'h80000337, 6, 32'h80000000);
        m(1, 6, 5, 3, 0);
        m(2, 6, 5, 3, 32'h80000000);
        m(3, 6, 5, 3, 32'h7fffffff);
        m(4, 6, 5, 3, 32'h80000000);
        m(6, 6, 5, 3, 0);
        m(4, 1, 0, 3, 32'hffffffff);
        m(5, 1, 0, 3, 32'hffffffff);
        m(6, 1, 0, 3, 32'hfffffff9);
        m(7, 1, 0, 3, 32'hfffffff9);
        m(4, 2, 1, 3, 0);
        m(6, 2, 1, 3, 3);

        m(0, 1, 2, 3, 32'hffffffeb);
        store_pc = program_length * 4;
        emit(enc_s(0, 3, 0, 2), -1, 0);
        load_pc = program_length * 4;
        emit(enc_i(0, 0, 2, 7, 'h03), 7, 32'hffffffeb);
        m(0, 7, 2, 8, 32'hffffffc1);
        emit(enc_i(1, 8, 0, 9, 'h13), 9, 32'hffffffc2);
        emit(enc_r(2, 2, 1, 0, 3), -1, 0);
        emit(32'h0000006f, -1, 0);

        repeat (2) @(negedge clk);
        reset = 0;
        enable = 1;
        wait (dut.state == 3'd2 && dut.instruction_pc == 8);
        @(negedge clk);
        enable = 0;
        repeat (3) begin
            @(posedge clk);
            #1;
            if (dut.state !== 3'd2 || pc !== 8 || retire_valid ||
                dut.u_regfile.registers[3] !== 0)
                $fatal(1, "FAIL paused MulDiv execute");
        end
        @(negedge clk);
        enable = 1;
        execute_pause_done = 1;
        $display("PASS pause during MulDiv execute");

        wait (dut.state == 3'd4 && dut.instruction_pc == 8);
        @(negedge clk);
        enable = 0;
        repeat (3) begin
            @(posedge clk);
            #1;
            if (dut.state !== 3'd4 || pc !== 8 || retire_valid ||
                dut.u_regfile.registers[3] !== 0)
                $fatal(1, "FAIL paused MulDiv writeback");
        end
        @(negedge clk);
        enable = 1;
        wb_pause_done = 1;
        $display("PASS pause during MulDiv writeback");

        wait (mem_valid && mem_write && pc == store_pc);
        @(negedge clk);
        mem_ready = 0;
        enable = 0;
        repeat (2) @(negedge clk);
        mem_ready = 1;
        repeat (2) @(negedge clk);
        if (!mem_valid || !mem_write || mem_addr !== 0 ||
            mem_write_data !== 32'hffffffeb || mem_write_strobe !== 4'b1111 ||
            writes != 0 || dmem[0] !== 0)
            $fatal(1, "FAIL paused store request");
        enable = 1;
        mem_ready = 0;
        repeat (2) @(negedge clk);
        if (!mem_valid || !mem_write || writes != 0)
            $fatal(1, "FAIL waiting store request");
        mem_ready = 1;
        @(negedge clk);
        memory_pause_done = 1;
        $display("PASS memory pause and wait");

        wait (retired == program_length);
        #2;
        if (!execute_pause_done || !wb_pause_done || !memory_pause_done ||
            reads != 1 || writes != 1 || dmem[0] !== 32'hffffffeb)
            $fatal(1, "FAIL final checks reads=%0d writes=%0d memory=%08x",
                   reads, writes, dmem[0]);
        $display("PASS RV32IM integration: %0d retirements, %0d read, %0d write",
                 retired, reads, writes);
        $finish;
    end

    initial begin
        #50000;
        $fatal(1, "FAIL timeout PC=%08x retirements=%0d", pc, retired);
    end
endmodule
