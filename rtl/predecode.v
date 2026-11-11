module predecode (
    input  wire [31:0] instruction,
    input  wire        idex_valid,
    input  wire        idex_is_load,
    input  wire [4:0]  idex_rd,
    output reg  [1:0]  pd_class,
    output reg         pd_is_load,
    output wire        pd_load_use
);
    // Class encoding: 00=ALU, 01=load/store, 10=branch/jump, 11=mul/div.
    always @* begin
        pd_class = 2'b00;
        pd_is_load = 1'b0;
        case (instruction[6:0])
            7'b0000011: begin pd_class=2'b01; pd_is_load=1'b1; end
            7'b0100011: pd_class=2'b01;
            7'b1100011, 7'b1100111, 7'b1101111: pd_class=2'b10;
            7'b0110011: if (instruction[31:25] == 7'b0000001) pd_class=2'b11;
            default: pd_class=2'b00;
        endcase
    end
    assign pd_load_use = pd_is_load && idex_valid && idex_is_load &&
                         (idex_rd != 5'd0) &&
                         ((idex_rd == instruction[19:15]) ||
                          (idex_rd == instruction[24:20]));
endmodule
