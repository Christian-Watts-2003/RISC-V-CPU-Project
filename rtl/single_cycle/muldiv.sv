// RV32M arithmetic. This unit is combinational for the single-cycle CPU;
// division/remainder therefore contribute to the CPU's critical path.
module muldiv (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire [2:0]  muldiv_op,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result,
    output wire        valid
);
    reg signed [63:0] product_ss;
    reg        [63:0] product_uu;
    reg signed [65:0] product_su;

    always @* begin
        result = 32'b0;
        product_ss = 64'b0;
        product_uu = 64'b0;
        product_su = 66'b0;
        if (start) begin
            case (muldiv_op)
                3'b000, 3'b001: begin
                    product_ss = $signed(a) * $signed(b);
                    result = (muldiv_op == 3'b000) ?
                             product_ss[31:0] : product_ss[63:32];
                end
                3'b010: begin
                    product_su = $signed({a[31], a}) * $signed({1'b0, b});
                    result = product_su[63:32];
                end
                3'b011: begin
                    product_uu = a * b;
                    result = product_uu[63:32];
                end
                3'b100: begin
                    if (b == 0) result = 32'hffff_ffff;
                    else if (a == 32'h8000_0000 && b == 32'hffff_ffff)
                        result = 32'h8000_0000;
                    else result = $signed(a) / $signed(b);
                end
                3'b101: result = (b == 0) ? 32'hffff_ffff : a / b;
                3'b110: begin
                    if (b == 0) result = a;
                    else if (a == 32'h8000_0000 && b == 32'hffff_ffff)
                        result = 32'b0;
                    else result = $signed(a) % $signed(b);
                end
                3'b111: result = (b == 0) ? a : a % b;
                default: result = 32'b0;
            endcase
        end
    end
    assign valid=start;
endmodule
