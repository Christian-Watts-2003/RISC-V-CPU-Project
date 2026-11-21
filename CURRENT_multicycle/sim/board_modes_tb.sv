`timescale 1ns/1ps

module board_modes_tb;
    localparam integer BAUD_DIV = 8;
    reg clk = 0;
    reg btnC = 1;
    reg [15:0] sw = 16'h4000;
    wire [15:0] led;
    wire uart_tx;
    string line = "";
    string last_line = "";
    integer lines = 0;
    integer i, bit_index;
    reg [7:0] byte_value;
    reg [2:0] held_state;
    reg [31:0] held_pc;
    reg capture_uart = 1;

    always #5 clk = ~clk;

    basys3_modified_top #(
        .IMEM_DEPTH(64), .DMEM_DEPTH(16), .UART_BAUD_DIV(BAUD_DIV),
        .IMEM_FILE("")
    ) dut (.clk(clk), .btnC(btnC), .sw(sw), .led(led), .uart_tx(uart_tx));

    initial begin
        forever begin
            @(negedge uart_tx);
            #(BAUD_DIV * 15);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                byte_value[bit_index] = uart_tx;
                #(BAUD_DIV * 10);
            end
            if (uart_tx !== 1'b1) $fatal(1, "FAIL UART stop bit");
            if (capture_uart) begin
                line = $sformatf("%s%c", line, byte_value);
                if (byte_value == 8'h0a) begin
                    last_line = line;
                    line = "";
                    lines = lines + 1;
                end
            end
        end
    end

    initial begin
        #1;
        dut.imem[0] = 32'h00500093;  // addi x1,x0,5
        dut.imem[1] = 32'h00102223;  // sw x1,4(x0)
        dut.imem[2] = 32'h00402103;  // lw x2,4(x0)
        dut.imem[3] = 32'h600d61b7;  // lui x3,0x600d6
        dut.imem[4] = 32'h00d18193;  // addi x3,x3,13
        dut.imem[5] = 32'h00302023;  // sw x3,0(x0)
        repeat (2) @(negedge clk);
        btnC = 0;
        sw[15] = 1;

        wait (dut.mem_valid && dut.mem_write && dut.mem_addr == 4);
        @(negedge clk);
        sw[15] = 0;
        repeat (3) @(negedge clk);
        if (!dut.mem_valid || !dut.mem_write || dut.dmem[1] !== 0 ||
            dut.performance_stores !== 0)
            $fatal(1, "FAIL paused store was accepted");
        sw[15] = 1;

        wait (lines == 1);
        if (last_line != $sformatf("RESULT=PASS,CYCLES=27,RETIRED=6,LOADS=1,STORES=2,WAITS=0%c%c", 13, 10))
            $fatal(1, "FAIL PASS summary: %s", last_line);
        if (!dut.performance_done || dut.dmem[1] !== 5 ||
            dut.dmem[0] !== 32'h600d600d)
            $fatal(1, "FAIL performance completion");
        $display("PASS performance mode: %s", last_line);

        @(negedge clk);
        btnC = 1;
        sw[15] = 0;
        dut.imem[3] = 32'hdeae01b7;
        dut.imem[4] = 32'ha1118193;
        repeat (2) @(negedge clk);
        btnC = 0;
        sw[15] = 1;
        wait (lines == 2);
        if (last_line != $sformatf("RESULT=FAIL,CYCLES=27,RETIRED=6,LOADS=1,STORES=2,WAITS=0%c%c", 13, 10))
            $fatal(1, "FAIL FAIL summary: %s", last_line);
        $display("PASS failure-marker summary: %s", last_line);

        @(negedge clk);
        capture_uart = 0;
        btnC = 1;
        sw = 0;
        repeat (2) @(negedge clk);
        btnC = 0;
        sw[15] = 1;
        wait (dut.trace_busy);
        @(negedge clk);
        held_pc = dut.core_pc;
        held_state = dut.u_cpu.state;
        repeat (5) begin
            @(posedge clk);
            #1;
            if (!dut.trace_busy || dut.core_enable ||
                dut.core_pc !== held_pc || dut.u_cpu.state !== held_state)
                $fatal(1, "FAIL CPU did not pause during trace");
        end
        $display("PASS trace mode pauses CPU during UART reporting");
        $finish;
    end

    initial begin
        #5000000;
        $fatal(1, "FAIL board mode timeout, lines=%0d", lines);
    end
endmodule
