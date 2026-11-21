module branch_unit (
    input wire [31:0] pc, imm, rs1_value, rs2_value,
    input wire branch_en, input wire [2:0] branch_type,
    input wire jump_en, jalr_en,
    output reg taken, output reg [31:0] target,
    output wire [31:0] link_value
);
    always @* begin
        taken=0;
        if (branch_en) case (branch_type)
            0: taken=(rs1_value==rs2_value); 1: taken=(rs1_value!=rs2_value);
            4: taken=($signed(rs1_value)<$signed(rs2_value));
            5: taken=($signed(rs1_value)>=$signed(rs2_value));
            6: taken=(rs1_value<rs2_value); 7: taken=(rs1_value>=rs2_value);
            default: taken=0;
        endcase
        else if (jump_en) taken=1;
        target=jalr_en ? ((rs1_value+imm)&32'hffff_fffe) : (pc+imm);
    end
    assign link_value=pc+4;
endmodule
