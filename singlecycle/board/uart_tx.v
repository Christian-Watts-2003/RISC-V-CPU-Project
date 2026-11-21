// Simple 8-N-1 UART transmitter.
module uart_tx #(
    parameter integer BAUD_DIV = 868
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data,
    output reg        busy,
    output reg        tx
);
    reg [31:0] baud_count;
    reg [7:0] shift_reg;
    reg [3:0] bit_index;

    always @(posedge clk) begin
        if (rst) begin
            baud_count <= 32'b0;
            shift_reg <= 8'b0;
            bit_index <= 4'd0;
            busy <= 1'b0;
            tx <= 1'b1;
        end else if (!busy) begin
            if (start) begin
                baud_count <= 32'b0;
                shift_reg <= data;
                bit_index <= 4'd0;
                busy <= 1'b1;
                tx <= 1'b0;
            end
        end else if (baud_count == BAUD_DIV - 1) begin
            baud_count <= 32'b0;
            if (bit_index < 4'd8) begin
                tx <= shift_reg[0];
                shift_reg <= {1'b0, shift_reg[7:1]};
                bit_index <= bit_index + 1'b1;
            end else if (bit_index == 4'd8) begin
                tx <= 1'b1;
                bit_index <= 4'd9;
            end else begin
                busy <= 1'b0;
                tx <= 1'b1;
            end
        end else begin
            baud_count <= baud_count + 1'b1;
        end
    end
endmodule
