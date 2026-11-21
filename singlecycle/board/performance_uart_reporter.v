// Fixed-format performance summary generator for the UART transmitter.
module performance_uart_reporter #(
    parameter integer BAUD_DIV = 868
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        start_report,
    input  wire [31:0] cycles,
    input  wire [31:0] pc,
    input  wire [31:0] stores,
    output wire        uart_tx
);
    localparam integer LAST_INDEX = 44;

    reg        active;
    reg [5:0]  char_index;
    reg [31:0] report_cycles;
    reg [31:0] report_pc;
    reg [31:0] report_stores;
    wire       tx_busy;
    wire       tx_start;
    reg [7:0]  tx_data;

    function [7:0] hex_ascii;
        input [3:0] value;
        begin
            if (value < 4'd10)
                hex_ascii = "0" + value;
            else
                hex_ascii = "A" + (value - 4'd10);
        end
    endfunction

    always @* begin
        tx_data = 8'h20;
        case (char_index)
            6'd0:  tx_data = "C";
            6'd1:  tx_data = "Y";
            6'd2:  tx_data = "C";
            6'd3:  tx_data = "L";
            6'd4:  tx_data = "E";
            6'd5:  tx_data = "S";
            6'd6:  tx_data = "=";
            6'd7:  tx_data = hex_ascii(report_cycles[31:28]);
            6'd8:  tx_data = hex_ascii(report_cycles[27:24]);
            6'd9:  tx_data = hex_ascii(report_cycles[23:20]);
            6'd10: tx_data = hex_ascii(report_cycles[19:16]);
            6'd11: tx_data = hex_ascii(report_cycles[15:12]);
            6'd12: tx_data = hex_ascii(report_cycles[11:8]);
            6'd13: tx_data = hex_ascii(report_cycles[7:4]);
            6'd14: tx_data = hex_ascii(report_cycles[3:0]);
            6'd15: tx_data = " ";
            6'd16: tx_data = "P";
            6'd17: tx_data = "C";
            6'd18: tx_data = "=";
            6'd19: tx_data = hex_ascii(report_pc[31:28]);
            6'd20: tx_data = hex_ascii(report_pc[27:24]);
            6'd21: tx_data = hex_ascii(report_pc[23:20]);
            6'd22: tx_data = hex_ascii(report_pc[19:16]);
            6'd23: tx_data = hex_ascii(report_pc[15:12]);
            6'd24: tx_data = hex_ascii(report_pc[11:8]);
            6'd25: tx_data = hex_ascii(report_pc[7:4]);
            6'd26: tx_data = hex_ascii(report_pc[3:0]);
            6'd27: tx_data = " ";
            6'd28: tx_data = "S";
            6'd29: tx_data = "T";
            6'd30: tx_data = "O";
            6'd31: tx_data = "R";
            6'd32: tx_data = "E";
            6'd33: tx_data = "S";
            6'd34: tx_data = "=";
            6'd35: tx_data = hex_ascii(report_stores[31:28]);
            6'd36: tx_data = hex_ascii(report_stores[27:24]);
            6'd37: tx_data = hex_ascii(report_stores[23:20]);
            6'd38: tx_data = hex_ascii(report_stores[19:16]);
            6'd39: tx_data = hex_ascii(report_stores[15:12]);
            6'd40: tx_data = hex_ascii(report_stores[11:8]);
            6'd41: tx_data = hex_ascii(report_stores[7:4]);
            6'd42: tx_data = hex_ascii(report_stores[3:0]);
            6'd43: tx_data = 8'h0d;
            6'd44: tx_data = 8'h0a;
            default: tx_data = 8'h20;
        endcase
    end

    assign tx_start = active && !tx_busy;

    always @(posedge clk) begin
        if (rst) begin
            active <= 1'b0;
            char_index <= 6'b0;
            report_cycles <= 32'b0;
            report_pc <= 32'b0;
            report_stores <= 32'b0;
        end else begin
            if (start_report && !active) begin
                active <= 1'b1;
                char_index <= 6'b0;
                report_cycles <= cycles;
                report_pc <= pc;
                report_stores <= stores;
            end else if (tx_start) begin
                if (char_index == LAST_INDEX) begin
                    active <= 1'b0;
                end else begin
                    char_index <= char_index + 1'b1;
                end
            end
        end
    end

    uart_tx #(
        .BAUD_DIV(BAUD_DIV)
    ) u_uart_tx (
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .data(tx_data),
        .busy(tx_busy),
        .tx(uart_tx)
    );
endmodule
