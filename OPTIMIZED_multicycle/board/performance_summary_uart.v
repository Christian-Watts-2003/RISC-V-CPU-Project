// One decimal summary after the measured program has stopped.
module performance_summary_uart #(
    parameter integer BAUD_DIV = 868
) (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [1:0] result_status,
    input wire [63:0] cycles,
    input wire [63:0] retired,
    input wire [63:0] loads,
    input wire [63:0] stores,
    input wire [63:0] waits,
    output wire uart_tx,
    output wire busy
);
    localparam [3:0] IDLE=0, LABEL=1, PREPARE=2, CONVERT=3, TRIM=4,
                     DIGITS=5, SEPARATOR=6, CR=7, LF=8, DRAIN=9;
    reg [3:0] state;
    reg [2:0] field;
    reg [3:0] char_index;
    reg [4:0] digit_index;
    reg [6:0] bit_count;
    reg [63:0] binary;
    reg [79:0] bcd;
    reg [79:0] adjusted;
    reg [1:0] saved_status;
    reg [63:0] saved_cycles, saved_retired, saved_loads, saved_stores, saved_waits;
    reg [7:0] tx_data;
    wire tx_busy;
    wire tx_start = !tx_busy && (state == LABEL || state == DIGITS ||
                                 state == SEPARATOR || state == CR || state == LF);
    integer n;

    function [3:0] label_length;
        input [2:0] f;
        begin
            case (f)
                0: label_length = 12;
                1: label_length = 7;
                2: label_length = 8;
                3: label_length = 6;
                4: label_length = 7;
                default: label_length = 6;
            endcase
        end
    endfunction

    function [7:0] label_char;
        input [2:0] f;
        input [3:0] p;
        input [1:0] status;
        reg [95:0] text;
        begin
            case (f)
                0: text = (status == 1) ? "RESULT=PASS," : "RESULT=FAIL,";
                1: text = "CYCLES=     ";
                2: text = "RETIRED=    ";
                3: text = "LOADS=      ";
                4: text = "STORES=     ";
                default: text = "WAITS=      ";
            endcase
            label_char = text[95 - 8*p -: 8];
        end
    endfunction

    always @* begin
        adjusted = bcd;
        for (n = 0; n < 20; n = n + 1)
            if (bcd[n*4 +: 4] > 4)
                adjusted[n*4 +: 4] = bcd[n*4 +: 4] + 4'd3;
        tx_data = 8'h20;
        case (state)
            LABEL: tx_data = label_char(field, char_index, saved_status);
            DIGITS: tx_data = "0" + bcd[79 - 4*digit_index -: 4];
            SEPARATOR: tx_data = ",";
            CR: tx_data = 8'h0d;
            LF: tx_data = 8'h0a;
            default: ;
        endcase
    end

    assign busy = state != IDLE;
    uart_tx #(.BAUD_DIV(BAUD_DIV)) u_uart_tx (
        .clk(clk), .rst(rst), .start(tx_start), .data(tx_data),
        .busy(tx_busy), .tx(uart_tx)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            field <= 0;
            char_index <= 0;
            digit_index <= 0;
            bit_count <= 0;
            binary <= 0;
            bcd <= 0;
            saved_status <= 0;
            saved_cycles <= 0;
            saved_retired <= 0;
            saved_loads <= 0;
            saved_stores <= 0;
            saved_waits <= 0;
        end else begin
            case (state)
                IDLE: if (start) begin
                    saved_status <= result_status;
                    saved_cycles <= cycles;
                    saved_retired <= retired;
                    saved_loads <= loads;
                    saved_stores <= stores;
                    saved_waits <= waits;
                    field <= 0;
                    char_index <= 0;
                    state <= LABEL;
                end
                LABEL: if (tx_start) begin
                    if (char_index + 1'b1 == label_length(field)) begin
                        char_index <= 0;
                        if (field == 0) begin
                            field <= 1;
                            state <= LABEL;
                        end else state <= PREPARE;
                    end else char_index <= char_index + 1'b1;
                end
                PREPARE: begin
                    case (field)
                        1: binary <= saved_cycles;
                        2: binary <= saved_retired;
                        3: binary <= saved_loads;
                        4: binary <= saved_stores;
                        default: binary <= saved_waits;
                    endcase
                    bcd <= 0;
                    bit_count <= 0;
                    state <= CONVERT;
                end
                CONVERT: begin
                    bcd <= {adjusted[75:0], binary[63]};
                    binary <= {binary[62:0], 1'b0};
                    if (bit_count == 63) begin
                        digit_index <= 0;
                        state <= TRIM;
                    end else bit_count <= bit_count + 1'b1;
                end
                TRIM: begin
                    if (digit_index == 19 || bcd[79 - 4*digit_index -: 4] != 0)
                        state <= DIGITS;
                    else digit_index <= digit_index + 1'b1;
                end
                DIGITS: if (tx_start) begin
                    if (digit_index == 19)
                        state <= (field == 5) ? CR : SEPARATOR;
                    else digit_index <= digit_index + 1'b1;
                end
                SEPARATOR: if (tx_start) begin
                    field <= field + 1'b1;
                    state <= LABEL;
                end
                CR: if (tx_start) state <= LF;
                LF: if (tx_start) state <= DRAIN;
                DRAIN: if (!tx_busy) state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
