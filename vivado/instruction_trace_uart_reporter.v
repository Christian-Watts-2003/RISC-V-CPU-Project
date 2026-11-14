// Instruction-by-instruction UART trace reporter.
// One report is emitted for each CPU step, then the CPU remains paused until
// the complete selected-field report has been transmitted.
module instruction_trace_uart_reporter #(
    parameter integer BAUD_DIV = 868
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [8:0] field_enable,
    input  wire [1:0] result_status,
    input  wire [31:0] pc,
    input  wire [31:0] instruction,
    input  wire [31:0] data_addr,
    input  wire [31:0] store_data,
    input  wire [31:0] cycles,
    input  wire [31:0] instruction_count,
    input  wire [31:0] store_count,
    input  wire [31:0] load_data,
    output wire        uart_tx,
    output wire        busy
);
    localparam [3:0] FIELD_PC     = 4'd0;
    localparam [3:0] FIELD_INSTR  = 4'd1;
    localparam [3:0] FIELD_DADDR  = 4'd2;
    localparam [3:0] FIELD_SWDATA = 4'd3;
    localparam [3:0] FIELD_CYCLES = 4'd4;
    localparam [3:0] FIELD_ICOUNT = 4'd5;
    localparam [3:0] FIELD_STORES = 4'd6;
    localparam [3:0] FIELD_LDATA  = 4'd7;
    localparam [3:0] FIELD_RESULT = 4'd8;
    localparam [3:0] FIELD_END    = 4'd9;

    reg        active;
    reg [8:0]  remaining_fields;
    reg [3:0]  field_index;
    reg [4:0]  char_index;
    reg [31:0] report_pc;
    reg [31:0] report_instruction;
    reg [31:0] report_data_addr;
    reg [31:0] report_store_data;
    reg [31:0] report_cycles;
    reg [31:0] report_instruction_count;
    reg [31:0] report_store_count;
    reg [31:0] report_load_data;
    reg [1:0]  report_result_status;
    reg [7:0]  tx_data;
    wire       tx_busy;
    wire       tx_start;

    function [3:0] first_field;
        input [8:0] mask;
        begin
            if (mask[0]) first_field = FIELD_PC;
            else if (mask[1]) first_field = FIELD_INSTR;
            else if (mask[2]) first_field = FIELD_DADDR;
            else if (mask[3]) first_field = FIELD_SWDATA;
            else if (mask[4]) first_field = FIELD_CYCLES;
            else if (mask[5]) first_field = FIELD_ICOUNT;
            else if (mask[6]) first_field = FIELD_STORES;
            else if (mask[7]) first_field = FIELD_LDATA;
            else if (mask[8]) first_field = FIELD_RESULT;
            else first_field = FIELD_END;
        end
    endfunction

    function [7:0] hex_ascii;
        input [3:0] value;
        begin
            if (value < 4'd10)
                hex_ascii = "0" + value;
            else
                hex_ascii = "A" + (value - 4'd10);
        end
    endfunction

    function [3:0] hex_nibble;
        input [31:0] value;
        input [2:0] digit;
        begin
            case (digit)
                3'd0: hex_nibble = value[31:28];
                3'd1: hex_nibble = value[27:24];
                3'd2: hex_nibble = value[23:20];
                3'd3: hex_nibble = value[19:16];
                3'd4: hex_nibble = value[15:12];
                3'd5: hex_nibble = value[11:8];
                3'd6: hex_nibble = value[7:4];
                default: hex_nibble = value[3:0];
            endcase
        end
    endfunction

    function [4:0] field_length;
        input [3:0] field;
        begin
            case (field)
                FIELD_PC:     field_length = 5'd12; // PC= + 8 hex digits + space
                FIELD_INSTR:  field_length = 5'd15;
                FIELD_DADDR:  field_length = 5'd15;
                FIELD_SWDATA: field_length = 5'd16;
                FIELD_CYCLES:  field_length = 5'd16;
                FIELD_ICOUNT:  field_length = 5'd15;
                FIELD_STORES:  field_length = 5'd16;
                FIELD_LDATA:   field_length = 5'd15;
                FIELD_RESULT:  field_length = 5'd12;
                default:      field_length = 5'd2;  // CR/LF
            endcase
        end
    endfunction

    function [7:0] field_char;
        input [3:0]  field;
        input [4:0]  position;
        input [31:0] value_pc;
        input [31:0] value_instruction;
        input [31:0] value_data_addr;
        input [31:0] value_store_data;
        input [31:0] value_cycles;
        input [31:0] value_instruction_count;
        input [31:0] value_store_count;
        input [31:0] value_load_data;
        input [1:0]  value_result_status;
        begin
            field_char = 8'h20;
            if (field == FIELD_END) begin
                field_char = (position == 0) ? 8'h0d : 8'h0a;
            end else begin
                case (field)
                    FIELD_PC: begin
                        case (position)
                            0: field_char = "P";
                            1: field_char = "C";
                            2: field_char = "=";
                            5'd11: field_char = 8'h20;
                            default: field_char = hex_ascii(hex_nibble(value_pc, position - 3));
                        endcase
                    end
                    FIELD_INSTR: begin
                        case (position)
                            0: field_char = "I";
                            1: field_char = "N";
                            2: field_char = "S";
                            3: field_char = "T";
                            4: field_char = "R";
                            5: field_char = "=";
                            5'd14: field_char = 8'h20;
                            default: field_char = hex_ascii(hex_nibble(value_instruction, position - 6));
                        endcase
                    end
                    FIELD_DADDR: begin
                        case (position)
                            0: field_char = "D";
                            1: field_char = "A";
                            2: field_char = "D";
                            3: field_char = "D";
                            4: field_char = "R";
                            5: field_char = "=";
                            5'd14: field_char = 8'h20;
                            default: field_char = hex_ascii(hex_nibble(value_data_addr, position - 6));
                        endcase
                    end
                    FIELD_SWDATA: begin
                        case (position)
                            0: field_char = "S";
                            1: field_char = "W";
                            2: field_char = "D";
                            3: field_char = "A";
                            4: field_char = "T";
                            5: field_char = "A";
                            6: field_char = "=";
                            5'd15: field_char = 8'h20;
                            default: field_char = hex_ascii(hex_nibble(value_store_data, position - 7));
                        endcase
                    end
                    FIELD_CYCLES: begin
                        case (position)
                            0: field_char = "C";
                            1: field_char = "Y";
                            2: field_char = "C";
                            3: field_char = "L";
                            4: field_char = "E";
                            5: field_char = "S";
                            6: field_char = "=";
                            5'd15: field_char = 8'h20;
                            default: field_char = hex_ascii(hex_nibble(value_cycles, position - 7));
                        endcase
                    end
                    FIELD_ICOUNT: begin
                        case (position)
                            0: field_char = "I";
                            1: field_char = "C";
                            2: field_char = "O";
                            3: field_char = "U";
                            4: field_char = "N";
                            5: field_char = "T";
                            6: field_char = "=";
                            5'd14: field_char = 8'h20;
                            default: field_char = hex_ascii(hex_nibble(value_instruction_count, position - 7));
                        endcase
                    end
                    FIELD_STORES: begin
                        case (position)
                            0: field_char = "S";
                            1: field_char = "T";
                            2: field_char = "O";
                            3: field_char = "R";
                            4: field_char = "E";
                            5: field_char = "S";
                            6: field_char = "=";
                            5'd15: field_char = 8'h20;
                            default: field_char = hex_ascii(hex_nibble(value_store_count, position - 7));
                        endcase
                    end
                    FIELD_LDATA: begin
                        case (position)
                            0: field_char = "L";
                            1: field_char = "D";
                            2: field_char = "A";
                            3: field_char = "T";
                            4: field_char = "A";
                            5: field_char = "=";
                            5'd14: field_char = 8'h20;
                            default: field_char = hex_ascii(hex_nibble(value_load_data, position - 6));
                        endcase
                    end
                    FIELD_RESULT: begin
                        case (position)
                            0: field_char = "R";
                            1: field_char = "E";
                            2: field_char = "S";
                            3: field_char = "U";
                            4: field_char = "L";
                            5: field_char = "T";
                            6: field_char = "=";
                            7: field_char = (value_result_status == 2'd1) ? "P" :
                                                (value_result_status == 2'd2) ? "F" : "-";
                            8: field_char = (value_result_status == 2'd1) ? "A" :
                                                (value_result_status == 2'd2) ? "A" : "-";
                            9: field_char = (value_result_status == 2'd1) ? "S" :
                                                (value_result_status == 2'd2) ? "I" : "-";
                            10: field_char = (value_result_status == 2'd2) ? "L" :
                                                 (value_result_status == 2'd0) ? "-" : " ";
                            5'd11: field_char = 8'h20;
                            default: field_char = 8'h20;
                        endcase
                    end
                    default: field_char = 8'h20;
                endcase
            end
        end
    endfunction

    always @* begin
        tx_data = field_char(
            field_index,
            char_index,
            report_pc,
            report_instruction,
            report_data_addr,
            report_store_data,
            report_cycles,
            report_instruction_count,
            report_store_count,
            report_load_data,
            report_result_status
        );
    end

    assign busy = active;
    assign tx_start = active && !tx_busy;

    always @(posedge clk) begin
        if (rst) begin
            active <= 1'b0;
            remaining_fields <= 9'b0;
            field_index <= FIELD_END;
            char_index <= 5'b0;
            report_pc <= 32'b0;
            report_instruction <= 32'b0;
            report_data_addr <= 32'b0;
            report_store_data <= 32'b0;
            report_cycles <= 32'b0;
            report_instruction_count <= 32'b0;
            report_store_count <= 32'b0;
            report_load_data <= 32'b0;
            report_result_status <= 2'b0;
        end else if (!active && start) begin
            active <= 1'b1;
            remaining_fields <= field_enable;
            field_index <= first_field(field_enable);
            char_index <= 5'b0;
            report_pc <= pc;
            report_instruction <= instruction;
            report_data_addr <= data_addr;
            report_store_data <= store_data;
            report_cycles <= cycles;
            report_instruction_count <= instruction_count;
            report_store_count <= store_count;
            report_load_data <= load_data;
            report_result_status <= result_status;
        end else if (tx_start) begin
            if (field_index == FIELD_END) begin
                if (char_index == 5'd1)
                    active <= 1'b0;
                else
                    char_index <= 5'd1;
            end else if (char_index + 5'd1 >= field_length(field_index)) begin
                remaining_fields <= remaining_fields & ~(9'b0000_0000_1 << field_index);
                field_index <= first_field(remaining_fields & ~(9'b0000_0000_1 << field_index));
                char_index <= 5'b0;
            end else begin
                char_index <= char_index + 1'b1;
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
