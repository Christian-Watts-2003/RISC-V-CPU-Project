module lsu (
    input  wire [31:0] address,
    input  wire [31:0] store_data,
    input  wire [1:0]  size,
    input  wire        load_unsigned,
    input  wire [31:0] read_word,
    output wire [31:0] dmem_addr,
    output reg  [31:0] dmem_wdata,
    output reg  [3:0]  dmem_wstrb,
    output reg  [31:0] load_data
);
    wire [4:0] byte_shift = {address[1:0], 3'b000};
    wire [31:0] shifted_read = read_word >> byte_shift;

    assign dmem_addr = {address[31:2], 2'b00};

    always @* begin
        dmem_wdata = store_data << byte_shift;
        dmem_wstrb = 4'b0000;
        case (size)
            2'd0: dmem_wstrb = 4'b0001 << address[1:0];
            2'd1: dmem_wstrb = address[1] ? 4'b1100 : 4'b0011;
            2'd2: dmem_wstrb = 4'b1111;
            default: dmem_wstrb = 4'b0000;
        endcase

        case (size)
            2'd0: begin
                if (load_unsigned) load_data = {24'b0, shifted_read[7:0]};
                else load_data = {{24{shifted_read[7]}}, shifted_read[7:0]};
            end
            2'd1: begin
                if (load_unsigned) load_data = {16'b0, shifted_read[15:0]};
                else load_data = {{16{shifted_read[15]}}, shifted_read[15:0]};
            end
            2'd2: load_data = read_word;
            default: load_data = 32'b0;
        endcase
    end
endmodule
