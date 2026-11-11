module alu (
    input wire [31:0] a,b,
    input wire [3:0] alu_op,
    output reg [31:0] result,
    output wire zero
);
    always @* begin
        case (alu_op)
            0: result=a+b; 1: result=a-b; 2: result=a&b; 3: result=a|b;
            4: result=a^b; 5: result=($signed(a)<$signed(b))?1:0;
            6: result=(a<b)?1:0; 7: result=a<<b[4:0]; 8: result=a>>b[4:0];
            9: result=$signed(a)>>>b[4:0]; default: result=0;
        endcase
    end
    assign zero=(result==0);
endmodule
