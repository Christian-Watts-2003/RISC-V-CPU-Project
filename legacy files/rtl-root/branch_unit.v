module branch_unit (
    input  wire [31:0] pc,
    input  wire [31:0] imm,
    input  wire [31:0] rs1_value,
    input  wire [31:0] rs2_value,
    input  wire        branch_en,
    input  wire [2:0]  branch_type,
    input  wire        jump_en,
    input  wire        jalr_en,
    output reg         taken,
    output reg  [31:0] target,
    output wire [31:0] link_value
);
    always @* begin
        taken = 1'b0;
        if (branch_en) begin
            case (branch_type)
                3'b000: taken = (rs1_value == rs2_value);                    // BEQ
                3'b001: taken = (rs1_value != rs2_value);                    // BNE
                3'b100: taken = ($signed(rs1_value) < $signed(rs2_value));   // BLT
                3'b101: taken = ($signed(rs1_value) >= $signed(rs2_value));  // BGE
                3'b110: taken = (rs1_value < rs2_value);                     // BLTU
                3'b111: taken = (rs1_value >= rs2_value);                    // BGEU
                default: taken = 1'b0;
            endcase
        end else if (jump_en) begin
            taken = 1'b1;
        end

        if (jalr_en)
            target = (rs1_value + imm) & 32'hffff_fffe;
        else
            target = pc + imm;
    end
    assign link_value = pc + 32'd4;
endmodule
