`timescale 1ns/1ps

module performance_summary_tb;
    localparam integer BAUD_DIV = 8;
    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    wire uart_tx, busy;
    reg [7:0] byte_value;
    integer bit_index;
    string line = "";

    always #5 clk = ~clk;
    performance_summary_uart #(.BAUD_DIV(BAUD_DIV)) dut (
        .clk(clk), .rst(rst), .start(start), .result_status(2'd2),
        .cycles(64'hffffffffffffffff), .retired(64'd10), .loads(64'd0),
        .stores(64'd9999999999), .waits(64'd1234567890123456789),
        .uart_tx(uart_tx), .busy(busy)
    );

    initial begin
        repeat (2) @(negedge clk);
        rst = 0;
        start = 1;
        @(negedge clk);
        start = 0;
    end

    initial begin
        forever begin
            @(negedge uart_tx);
            #(BAUD_DIV * 15);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                byte_value[bit_index] = uart_tx;
                #(BAUD_DIV * 10);
            end
            if (uart_tx !== 1'b1) $fatal(1, "FAIL UART stop bit");
            line = $sformatf("%s%c", line, byte_value);
            if (byte_value == 8'h0a) begin
                if (line != $sformatf("RESULT=FAIL,CYCLES=18446744073709551615,RETIRED=10,LOADS=0,STORES=9999999999,WAITS=1234567890123456789%c%c", 13, 10))
                    $fatal(1, "FAIL decimal UART summary: %s", line);
                $display("PASS decimal summary: %s", line);
                $finish;
            end
        end
    end

    initial begin
        #5000000;
        $fatal(1, "FAIL decimal reporter timeout");
    end
endmodule
