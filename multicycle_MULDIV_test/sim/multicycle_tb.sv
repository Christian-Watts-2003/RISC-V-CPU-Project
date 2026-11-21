`timescale 1ns/1ps

module multicycle_tb;
    reg clk = 0;
    reg reset = 1;
    reg enable = 0;
    reg mem_ready = 1;
    reg [31:0] imem [0:63];
    reg [31:0] dmem [0:15];
    wire [31:0] pc, mem_addr, mem_write_data;
    wire [31:0] retire_pc, retire_instruction;
    wire [3:0] mem_write_strobe;
    wire mem_valid, mem_read, mem_write, retire_valid;
    wire [31:0] instruction = (pc[31:2] < 64) ? imem[pc[31:2]] : 32'b0;
    wire [31:0] mem_read_data = (mem_addr[31:2] < 16) ? dmem[mem_addr[31:2]] : 32'b0;

    integer i, retire_count = 0, read_count = 0, write_count = 0;
    reg [31:0] expected_pc = 0;
    reg store_pause_done = 0, load_pause_done = 0;
    reg [31:0] held_pc, held_addr, held_data, held_regs [0:31];
    reg [2:0] held_state;
    reg [3:0] held_strobe;
    reg held_valid, held_read, held_write;

    always #5 clk = ~clk;

    rv32im_multicycle dut (
        .clk(clk), .reset(reset), .enable(enable),
        .instruction(instruction), .mem_read_data(mem_read_data),
        .mem_ready(mem_ready), .pc(pc), .mem_addr(mem_addr),
        .mem_write_data(mem_write_data), .mem_write_strobe(mem_write_strobe),
        .mem_valid(mem_valid), .mem_read(mem_read), .mem_write(mem_write),
        .retire_valid(retire_valid), .retire_pc(retire_pc),
        .retire_instruction(retire_instruction)
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

    function [31:0] enc_b(input integer imm, input integer rs2, input integer rs1,
                          input integer f3);
        enc_b = (((imm >> 12) & 1) << 31) | (((imm >> 5) & 6'h3f) << 25) |
                (rs2 << 20) | (rs1 << 15) | (f3 << 12) |
                (((imm >> 1) & 4'hf) << 8) | (((imm >> 11) & 1) << 7) | 7'h63;
    endfunction

    function [31:0] enc_u(input integer imm20, input integer rd, input integer op);
        enc_u = (imm20 << 12) | (rd << 7) | op;
    endfunction

    function [31:0] enc_j(input integer imm, input integer rd);
        enc_j = (((imm >> 20) & 1) << 31) | (((imm >> 1) & 10'h3ff) << 21) |
                (((imm >> 11) & 1) << 20) | (((imm >> 12) & 8'hff) << 12) |
                (rd << 7) | 7'h6f;
    endfunction

    task check_reg(input integer number, input [31:0] expected);
        begin
            if (dut.u_regfile.registers[number] !== expected)
                $fatal(1, "FAIL x%0d expected %08x got %08x",
                       number, expected, dut.u_regfile.registers[number]);
            $display("PASS x%0d = %08x", number, expected);
        end
    endtask

    task pause_memory(input integer is_store);
        begin
            wait (mem_valid && (is_store ? mem_write : mem_read));
            @(negedge clk);
            mem_ready = 0;
            enable = 0;
            $display("WAIT %s: paused with ready low", is_store ? "store" : "load ");
            repeat (2) @(negedge clk);
            mem_ready = 1;
            $display("WAIT %s: ready high while paused", is_store ? "store" : "load ");
            repeat (2) @(negedge clk);
            mem_ready = 0;
            enable = 1;
            $display("WAIT %s: enabled with ready low", is_store ? "store" : "load ");
            repeat (2) @(negedge clk);
            mem_ready = 1;
            @(negedge clk);
            if (is_store) store_pause_done = 1;
            else load_pause_done = 1;
        end
    endtask

    // The core advances a memory transaction only on an enabled, ready edge.
    always @(posedge clk) begin
        if (!reset && enable && mem_valid && mem_ready) begin
            if (mem_addr[31:2] >= 16)
                $fatal(1, "FAIL memory address out of range: %08x", mem_addr);
            if (mem_read) begin
                if (mem_write || mem_addr !== ((read_count == 4) ? 32'd4 : 32'd0))
                    $fatal(1, "FAIL read %0d addr=%08x write=%b", read_count, mem_addr, mem_write);
                read_count = read_count + 1;
                $display("READ  addr=%08x data=%08x", mem_addr, mem_read_data);
            end
            if (mem_write) begin
                case (write_count)
                    0: if (mem_addr !== 0 || mem_write_data !== 32'hffff8000 ||
                           mem_write_strobe !== 4'b0010)
                           $fatal(1, "FAIL byte store");
                    1: if (mem_addr !== 0 || mem_write_data !== 32'hff800000 ||
                           mem_write_strobe !== 4'b1100)
                           $fatal(1, "FAIL halfword store");
                    2: if (mem_addr !== 4 || mem_write_data !== 32'h12345000 ||
                           mem_write_strobe !== 4'b1111)
                           $fatal(1, "FAIL word store");
                    default: $fatal(1, "FAIL unexpected store %0d", write_count);
                endcase
                write_count = write_count + 1;
                for (integer lane = 0; lane < 4; lane = lane + 1)
                    if (mem_write_strobe[lane])
                        dmem[mem_addr[31:2]][8*lane +: 8] <= mem_write_data[8*lane +: 8];
                $display("WRITE addr=%08x data=%08x strobe=%b",
                         mem_addr, mem_write_data, mem_write_strobe);
            end
        end
    end

    always @(posedge clk) begin
        if (!reset && (!enable || (mem_valid && !mem_ready))) begin
            held_pc = pc;
            held_state = dut.state;
            held_addr = mem_addr;
            held_data = mem_write_data;
            held_strobe = mem_write_strobe;
            held_valid = mem_valid;
            held_read = mem_read;
            held_write = mem_write;
            for (integer r = 0; r < 32; r = r + 1)
                held_regs[r] = dut.u_regfile.registers[r];
            #1;
            if (pc !== held_pc || dut.state !== held_state ||
                mem_addr !== held_addr || mem_write_data !== held_data ||
                mem_write_strobe !== held_strobe || mem_valid !== held_valid ||
                mem_read !== held_read || mem_write !== held_write)
                $fatal(1, "FAIL state or memory request changed while held");
            for (integer r = 0; r < 32; r = r + 1)
                if (dut.u_regfile.registers[r] !== held_regs[r])
                    $fatal(1, "FAIL x%0d changed while held", r);
            if (retire_valid)
                $fatal(1, "FAIL retirement while held");
        end
    end

    always @(posedge clk) begin
        #1;
        if (!reset && retire_valid) begin
            if (retire_pc !== expected_pc ||
                retire_instruction !== imem[expected_pc[31:2]])
                $fatal(1, "FAIL retirement %0d: expected PC=%08x instruction=%08x, got PC=%08x instruction=%08x",
                       retire_count, expected_pc, imem[expected_pc[31:2]],
                       retire_pc, retire_instruction);
            retire_count = retire_count + 1;
            $display("RETIRE %0d PC=%08x INSTR=%08x", retire_count, retire_pc, retire_instruction);
            case (expected_pc)
                32*4, 34*4, 36*4, 38*4, 40*4, 42*4, 45*4:
                    expected_pc = expected_pc + 8;
                48*4: expected_pc = 51*4;
                default: expected_pc = expected_pc + 4;
            endcase
        end
    end

    initial begin
        for (i = 0; i < 64; i = i + 1) imem[i] = enc_i(0, 0, 0, 0, 7'h13);
        for (i = 0; i < 16; i = i + 1) dmem[i] = 0;
        imem[0]  = enc_i(-128, 0, 0, 1, 7'h13);
        imem[1]  = enc_i(1, 0, 0, 2, 7'h13);
        imem[2]  = enc_i(7, 0, 0, 0, 7'h13);
        imem[3]  = enc_u('h12345, 3, 7'h37);
        imem[4]  = enc_u(0, 4, 7'h17);
        imem[5]  = enc_r(0, 2, 1, 0, 5);
        imem[6]  = enc_r('h20, 1, 2, 0, 6);
        imem[7]  = enc_r(0, 2, 1, 2, 7);
        imem[8]  = enc_r(0, 2, 1, 3, 8);
        imem[9]  = enc_r(0, 2, 1, 4, 9);
        imem[10] = enc_r(0, 2, 1, 6, 10);
        imem[11] = enc_r(0, 2, 1, 7, 11);
        imem[12] = enc_r(0, 2, 2, 1, 12);
        imem[13] = enc_r(0, 2, 1, 5, 13);
        imem[14] = enc_r('h20, 2, 1, 5, 14);
        imem[15] = enc_i(5, 0, 0, 15, 7'h13);
        imem[16] = enc_i(0, 1, 2, 16, 7'h13);
        imem[17] = enc_i(1, 1, 3, 17, 7'h13);
        imem[18] = enc_i(3, 2, 4, 18, 7'h13);
        imem[19] = enc_i(2, 2, 6, 19, 7'h13);
        imem[20] = enc_i(255, 1, 7, 20, 7'h13);
        imem[21] = enc_i(3, 2, 1, 21, 7'h13);
        imem[22] = enc_i(3, 1, 5, 22, 7'h13);
        imem[23] = enc_i('h403, 1, 5, 23, 7'h13);
        imem[24] = enc_s(1, 1, 0, 0);
        imem[25] = enc_i(1, 0, 0, 24, 7'h03);
        imem[26] = enc_i(1, 0, 4, 25, 7'h03);
        imem[27] = enc_s(2, 1, 0, 1);
        imem[28] = enc_i(2, 0, 1, 26, 7'h03);
        imem[29] = enc_i(2, 0, 5, 27, 7'h03);
        imem[30] = enc_s(4, 3, 0, 2);
        imem[31] = enc_i(4, 0, 2, 28, 7'h03);
        imem[32] = enc_b(8, 2, 2, 0);
        imem[34] = enc_b(8, 0, 2, 1);
        imem[36] = enc_b(8, 2, 1, 4);
        imem[38] = enc_b(8, 1, 2, 5);
        imem[40] = enc_b(8, 1, 2, 6);
        imem[42] = enc_b(8, 2, 1, 7);
        imem[44] = enc_b(8, 2, 1, 0);
        imem[45] = enc_j(8, 29);
        imem[47] = enc_i(204, 0, 0, 30, 7'h13);
        imem[48] = enc_i(1, 30, 0, 31, 7'h67);
        imem[51] = 32'hffffffff;
        imem[52] = enc_r(2, 2, 1, 0, 3);
        imem[53] = enc_j(0, 0);

        repeat (2) @(negedge clk);
        reset = 0;
        enable = 1;
        wait (dut.state == 3'd2);
        @(negedge clk);
        enable = 0;
        $display("PAUSE execute");
        repeat (2) @(negedge clk);
        enable = 1;
        wait (dut.state == 3'd4);
        @(negedge clk);
        enable = 0;
        $display("PAUSE writeback");
        repeat (2) @(negedge clk);
        enable = 1;
        pause_memory(1);
        pause_memory(0);
        wait (retire_count == 45);
        #2;
        if (retire_pc !== 53*4 || !store_pause_done || !load_pause_done)
            $fatal(1, "FAIL completion or pause scenarios");
        if (read_count != 5 || write_count != 3)
            $fatal(1, "FAIL transaction counts: reads=%0d writes=%0d", read_count, write_count);
        if (dmem[0] !== 32'hff80_8000 || dmem[1] !== 32'h1234_5000)
            $fatal(1, "FAIL memory: [0]=%08x [1]=%08x", dmem[0], dmem[1]);
        check_reg(0, 0); check_reg(1, 32'hffffff80); check_reg(2, 1);
        check_reg(3, 32'h12345000); check_reg(4, 16); check_reg(5, 32'hffffff81);
        check_reg(6, 129); check_reg(7, 1); check_reg(8, 0);
        check_reg(9, 32'hffffff81); check_reg(10, 32'hffffff81); check_reg(11, 0);
        check_reg(12, 2); check_reg(13, 32'h7fffffc0); check_reg(14, 32'hffffffc0);
        check_reg(15, 5); check_reg(16, 1); check_reg(17, 0);
        check_reg(18, 2); check_reg(19, 3); check_reg(20, 128);
        check_reg(21, 8); check_reg(22, 32'h1ffffff0); check_reg(23, 32'hfffffff0);
        check_reg(24, 32'hffffff80); check_reg(25, 128);
        check_reg(26, 32'hffffff80); check_reg(27, 32'h0000ff80);
        check_reg(28, 32'h12345000); check_reg(29, 184);
        check_reg(30, 204); check_reg(31, 196);
        $display("PASS multi-cycle: %0d retirements, %0d reads, %0d writes", retire_count, read_count, write_count);
        $finish;
    end

    initial begin
        #50000;
        $fatal(1, "FAIL timeout: PC=%08x retirements=%0d", pc, retire_count);
    end
endmodule
