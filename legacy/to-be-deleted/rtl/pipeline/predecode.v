module predecode (
    input wire [31:0] instruction,
    input wire idex_valid,idex_is_load,input wire [4:0] idex_rd,
    output reg [1:0] pd_class,output reg pd_is_load,output wire pd_load_use
);
    always @* begin
        pd_class=0; pd_is_load=0;
        case (instruction[6:0])
            7'b0000011: begin pd_class=1; pd_is_load=1; end
            7'b0100011: pd_class=1;
            7'b1100011,7'b1100111,7'b1101111: pd_class=2;
            7'b0110011: if (instruction[31:25]==1) pd_class=3;
            default: ;
        endcase
    end
    // NOTE: pd_load_use is pending correction before use; it currently tests
    // whether the incoming instruction is a load, not whether it consumes rd.
    assign pd_load_use=1'b0;
endmodule
