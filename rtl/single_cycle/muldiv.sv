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
    wire signed [63:0] product_ss = $signed(a) * $signed(b);
    wire [63:0] product_uu = a * b;
    wire signed [32:0] a_ext = {a[31],a};
    wire signed [32:0] b_unsigned_ext = {1'b0,b};
    wire signed [65:0] product_su = a_ext * b_unsigned_ext;

    always @* begin
        case (muldiv_op)
            3'b000: result=product_ss[31:0];
            3'b001: result=product_ss[63:32];
            3'b010: result=product_su[63:32];
            3'b011: result=product_uu[63:32];
            3'b100: begin
                if (b==0) result=32'hffff_ffff;
                else if (a==32'h8000_0000 && b==32'hffff_ffff) result=32'h8000_0000;
                else result=$signed(a)/$signed(b);
            end
            3'b101: result=(b==0) ? 32'hffff_ffff : a/b;
            3'b110: begin
                if (b==0) result=a;
                else if (a==32'h8000_0000 && b==32'hffff_ffff) result=32'b0;
                else result=$signed(a)%$signed(b);
            end
            3'b111: result=(b==0) ? a : a%b;
            default: result=32'b0;
        endcase
    end
    assign valid=start;
endmodule
