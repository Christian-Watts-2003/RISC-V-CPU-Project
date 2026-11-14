// Unified single-cycle RV32I/RV32M CPU source for Innovus RTL compilation.
// Top module: single_cycle_Innovus
// Instruction and data memories are external to this design.
// No testbench, behavioral memory, initial block, or include directive is used.

// RV32I/RV32M combinational arithmetic and logic unit.
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] result,
    output wire        zero,
    output reg         illegal_op
);
    always @* begin
        result = 32'b0;
        illegal_op = 1'b0;
        case (alu_op)
            4'd0: result = a + b;                                      // ADD
            4'd1: result = a - b;                                      // SUB
            4'd2: result = a & b;                                      // AND
            4'd3: result = a | b;                                      // OR
            4'd4: result = a ^ b;                                      // XOR
            4'd5: result = {31'b0, ($signed(a) < $signed(b))};          // SLT
            4'd6: result = {31'b0, (a < b)};                           // SLTU
            4'd7: result = a << b[4:0];                                // SLL
            4'd8: result = a >> b[4:0];                                // SRL
            4'd9: result = $signed(a) >>> b[4:0];                      // SRA
            default: illegal_op = 1'b1;
        endcase
    end
    assign zero = (result == 32'b0);
endmodule

// Branch predicates, control-flow target and sequential link value.
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
        taken=0;
        if (branch_en) begin
            case (branch_type)
                3'b000: taken=(rs1_value==rs2_value);
                3'b001: taken=(rs1_value!=rs2_value);
                3'b100: taken=($signed(rs1_value)<$signed(rs2_value));
                3'b101: taken=($signed(rs1_value)>=$signed(rs2_value));
                3'b110: taken=(rs1_value<rs2_value);
                3'b111: taken=(rs1_value>=rs2_value);
                default: taken=0;
            endcase
        end else if (jump_en) taken=1;
        target=jalr_en ? ((rs1_value+imm)&32'hffff_fffe) : (pc+imm);
    end
    assign link_value=pc+32'd4;
endmodule

// Flat decoder for the documented single-cycle RV32IM instruction subset.
// Unsupported and illegal encodings are NOPs: legal=0 and no side effects.
module controller (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        legal,
    output reg [3:0]  alu_op,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg [2:0]  imm_src,
    output reg [1:0]  operand_a_sel, // 0=rs1, 1=PC, 2=zero
    output reg        alu_src,       // 1=immediate, 0=rs2
    output reg        branch,
    output reg [2:0]  branch_type,
    output reg        jump,
    output reg        jalr,
    output reg [1:0]  mem_size,      // 0=byte, 1=halfword, 2=word
    output reg        load_unsigned,
    output reg        is_muldiv,
    output reg [2:0]  muldiv_op
);
    localparam [3:0] ADD=0, SUB=1, AND_OP=2, OR_OP=3, XOR_OP=4,
                     SLT=5, SLTU=6, SLL=7, SRL=8, SRA=9;

    always @* begin
        legal=0; alu_op=ADD; reg_write=0; mem_read=0; mem_write=0;
        imm_src=0; operand_a_sel=0; alu_src=0; branch=0;
        branch_type=0; jump=0; jalr=0; mem_size=2; load_unsigned=0;
        is_muldiv=0; muldiv_op=0;

        case (opcode)
            7'b0110111: begin // LUI
                legal=1; reg_write=1; operand_a_sel=2; alu_src=1; imm_src=3;
            end
            7'b0010111: begin // AUIPC
                legal=1; reg_write=1; operand_a_sel=1; alu_src=1; imm_src=3;
            end
            7'b1101111: begin // JAL
                legal=1; reg_write=1; jump=1; imm_src=4;
            end
            7'b1100111: if (funct3==3'b000) begin // JALR
                legal=1; reg_write=1; jump=1; jalr=1; alu_src=1; imm_src=0;
            end
            7'b1100011: begin // Conditional branches
                case (funct3)
                    3'b000,3'b001,3'b100,3'b101,3'b110,3'b111: begin
                        legal=1; branch=1; branch_type=funct3; imm_src=2;
                    end
                    default: ;
                endcase
            end
            7'b0000011: begin // LB/LH/LW/LBU/LHU
                case (funct3)
                    3'b000: begin legal=1; mem_size=0; end
                    3'b001: begin legal=1; mem_size=1; end
                    3'b010: begin legal=1; mem_size=2; end
                    3'b100: begin legal=1; mem_size=0; load_unsigned=1; end
                    3'b101: begin legal=1; mem_size=1; load_unsigned=1; end
                    default: ;
                endcase
                if (legal) begin
                    reg_write=1; mem_read=1; alu_src=1; imm_src=0;
                end
            end
            7'b0100011: begin // SB/SH/SW
                case (funct3)
                    3'b000: begin legal=1; mem_size=0; end
                    3'b001: begin legal=1; mem_size=1; end
                    3'b010: begin legal=1; mem_size=2; end
                    default: ;
                endcase
                if (legal) begin mem_write=1; alu_src=1; imm_src=1; end
            end
            7'b0010011: begin // OP-IMM
                case (funct3)
                    3'b000: begin legal=1; alu_op=ADD; end // ADDI
                    3'b010: begin legal=1; alu_op=SLT; end // SLTI
                    3'b011: begin legal=1; alu_op=SLTU; end // SLTIU
                    3'b100: begin legal=1; alu_op=XOR_OP; end
                    3'b110: begin legal=1; alu_op=OR_OP; end
                    3'b111: begin legal=1; alu_op=AND_OP; end
                    3'b001: if (funct7==7'b0000000) begin legal=1; alu_op=SLL; end
                    3'b101: begin
                        if (funct7==7'b0000000) begin legal=1; alu_op=SRL; end
                        else if (funct7==7'b0100000) begin legal=1; alu_op=SRA; end
                    end
                    default: ;
                endcase
                if (legal) begin reg_write=1; alu_src=1; imm_src=0; end
            end
            7'b0110011: begin // OP and RV32M
                if (funct7==7'b0000001) begin
                    legal=1; reg_write=1; is_muldiv=1; muldiv_op=funct3;
                end else begin
                    case (funct3)
                        3'b000: begin
                            if (funct7==7'b0000000) begin legal=1; alu_op=ADD; end
                            else if (funct7==7'b0100000) begin legal=1; alu_op=SUB; end
                        end
                        3'b001: if (funct7==7'b0000000) begin legal=1; alu_op=SLL; end
                        3'b010: if (funct7==7'b0000000) begin legal=1; alu_op=SLT; end
                        3'b011: if (funct7==7'b0000000) begin legal=1; alu_op=SLTU; end
                        3'b100: if (funct7==7'b0000000) begin legal=1; alu_op=XOR_OP; end
                        3'b101: begin
                            if (funct7==7'b0000000) begin legal=1; alu_op=SRL; end
                            else if (funct7==7'b0100000) begin legal=1; alu_op=SRA; end
                        end
                        3'b110: if (funct7==7'b0000000) begin legal=1; alu_op=OR_OP; end
                        3'b111: if (funct7==7'b0000000) begin legal=1; alu_op=AND_OP; end
                        default: ;
                    endcase
                    if (legal) reg_write=1;
                end
            end
            // FENCE, SYSTEM, and all other unsupported encodings are NOPs.
            default: ;
        endcase
    end
endmodule

// Immediate generator for RV32I I/S/B/U/J formats.
module imm_gen (
    input  wire [31:0] instruction,
    input  wire [2:0]  imm_src,
    output reg  [31:0] imm_value
);
    always @* begin
        case (imm_src)
            3'b000: imm_value={{20{instruction[31]}},instruction[31:20]};
            3'b001: imm_value={{20{instruction[31]}},instruction[31:25],instruction[11:7]};
            3'b010: imm_value={{19{instruction[31]}},instruction[31],instruction[7],instruction[30:25],instruction[11:8],1'b0};
            3'b011: imm_value={instruction[31:12],12'b0};
            3'b100: imm_value={{11{instruction[31]}},instruction[31],instruction[19:12],instruction[20],instruction[30:21],1'b0};
            default: imm_value=32'b0;
        endcase
    end
endmodule

// Byte/halfword/word lane selection for the single-cycle memory interface.
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
    wire [4:0] shift_amount={address[1:0],3'b000};
    wire [31:0] selected_word=read_word >> shift_amount;
    assign dmem_addr={address[31:2],2'b00};
    always @* begin
        dmem_wdata=store_data << shift_amount;
        case (size)
            2'd0: dmem_wstrb=4'b0001 << address[1:0];
            2'd1: dmem_wstrb=address[1] ? 4'b1100 : 4'b0011;
            2'd2: dmem_wstrb=4'b1111;
            default: dmem_wstrb=4'b0000;
        endcase
        case (size)
            2'd0: load_data=load_unsigned ? {24'b0,selected_word[7:0]} : {{24{selected_word[7]}},selected_word[7:0]};
            2'd1: load_data=load_unsigned ? {16'b0,selected_word[15:0]} : {{16{selected_word[15]}},selected_word[15:0]};
            2'd2: load_data=read_word;
            default: load_data=32'b0;
        endcase
    end
endmodule

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

// 32 x 32-bit register file, asynchronous reads and synchronous write.
module regfile (
    input  wire        clk,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    input  wire        reg_write,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);
    reg [31:0] registers [0:31];
    assign read_data1=(rs1==0) ? 32'b0 :
        ((reg_write && rd!=0 && rs1==rd) ? write_data : registers[rs1]);
    assign read_data2=(rs2==0) ? 32'b0 :
        ((reg_write && rd!=0 && rs2==rd) ? write_data : registers[rs2]);
    always @(posedge clk)
        if (reg_write && rd!=0) registers[rd] <= write_data;
endmodule

// Single-cycle RV32I/RV32M datapath. Memory reads are combinational;
// stores are committed synchronously by the external memory on the clock edge.
module datapath (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] instruction,
    input  wire [31:0] mem_read_data,
    input  wire [3:0]  alu_op,
    input  wire        legal,
    input  wire        reg_write,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [2:0]  imm_src,
    input  wire [1:0]  operand_a_sel,
    input  wire        alu_src,
    input  wire        branch,
    input  wire [2:0]  branch_type,
    input  wire        jump,
    input  wire        jalr,
    input  wire [1:0]  mem_size,
    input  wire        load_unsigned,
    input  wire        is_muldiv,
    input  wire [2:0]  muldiv_op,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_write_data,
    output wire [3:0]  mem_write_strobe,
    output wire [31:0] pc
);
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    wire [4:0] rd  = instruction[11:7];
    wire [31:0] rs1_data, rs2_data, imm, alu_a, alu_b, alu_result;
    wire [31:0] muldiv_result, load_value, link_value, branch_target;
    wire [31:0] pc_next, writeback_data;
    wire [3:0] lsu_wstrb;
    wire branch_taken, alu_zero, alu_illegal;

    regfile u_regfile (
        .clk(clk), .rs1(rs1), .rs2(rs2), .rd(rd),
        .write_data(writeback_data), .reg_write(legal && reg_write),
        .read_data1(rs1_data), .read_data2(rs2_data)
    );
    imm_gen u_imm_gen (.instruction(instruction), .imm_src(imm_src), .imm_value(imm));

    assign alu_a = (operand_a_sel == 2'd1) ? pc :
                   (operand_a_sel == 2'd2) ? 32'b0 : rs1_data;
    assign alu_b = alu_src ? imm : rs2_data;
    alu u_alu (.a(alu_a), .b(alu_b), .alu_op(alu_op),
               .result(alu_result), .zero(alu_zero), .illegal_op(alu_illegal));

    muldiv u_muldiv (.clk(clk), .reset(reset), .start(legal && is_muldiv),
                     .muldiv_op(muldiv_op), .a(rs1_data), .b(rs2_data),
                     .result(muldiv_result), .valid());

    branch_unit u_branch (
        .pc(pc), .imm(imm), .rs1_value(rs1_data), .rs2_value(rs2_data),
        .branch_en(legal && branch), .branch_type(branch_type),
        .jump_en(legal && jump), .jalr_en(legal && jalr),
        .taken(branch_taken), .target(branch_target), .link_value(link_value)
    );

    lsu u_lsu (
        .address(alu_result), .store_data(rs2_data), .size(mem_size),
        .load_unsigned(load_unsigned), .read_word(mem_read_data),
        .dmem_addr(mem_addr), .dmem_wdata(mem_write_data),
        .dmem_wstrb(lsu_wstrb), .load_data(load_value)
    );

    // Gate both memory side effects with a legal decoded instruction.
    assign mem_write_strobe = (legal && mem_write) ? lsu_wstrb : 4'b0000;

    assign writeback_data = (legal && jump) ? link_value :
                            (legal && mem_read) ? load_value :
                            (legal && is_muldiv) ? muldiv_result : alu_result;

    assign pc_next = (legal && branch && branch_taken) ? branch_target :
                     (legal && jump) ? branch_target : pc + 32'd4;
    reg [31:0] pc_reg;
    assign pc = pc_reg;
    always @(posedge clk) begin
        if (reset) pc_reg <= 32'b0;
        else       pc_reg <= pc_next;
    end
endmodule

// Single-cycle processor interface with external combinational instruction/load data.
module cpu (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] instruction,
    input  wire [31:0] mem_read_data,
    output wire [31:0] pc,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_write_data,
    output wire [3:0]  mem_write_strobe,
    output wire        mem_read,
    output wire        mem_write
);
    wire legal;
    wire [3:0] alu_op;
    wire ctrl_reg_write, ctrl_mem_read, ctrl_mem_write;
    wire branch, jump, alu_src, is_muldiv, jalr;
    wire [2:0] imm_src, branch_type, muldiv_op;
    wire [1:0] operand_a_sel, mem_size;
    wire load_unsigned;

    controller u_controller (
        .opcode(instruction[6:0]), .funct3(instruction[14:12]), .funct7(instruction[31:25]),
        .legal(legal), .alu_op(alu_op), .reg_write(ctrl_reg_write),
        .mem_read(ctrl_mem_read), .mem_write(ctrl_mem_write), .imm_src(imm_src),
        .operand_a_sel(operand_a_sel), .alu_src(alu_src), .branch(branch),
        .branch_type(branch_type), .jump(jump), .jalr(jalr), .mem_size(mem_size),
        .load_unsigned(load_unsigned), .is_muldiv(is_muldiv), .muldiv_op(muldiv_op)
    );

    datapath u_datapath (
        .clk(clk), .reset(reset), .instruction(instruction), .mem_read_data(mem_read_data),
        .alu_op(alu_op), .legal(legal), .reg_write(ctrl_reg_write),
        .mem_read(ctrl_mem_read), .mem_write(ctrl_mem_write), .imm_src(imm_src),
        .operand_a_sel(operand_a_sel), .alu_src(alu_src), .branch(branch),
        .branch_type(branch_type), .jump(jump), .jalr(jalr), .mem_size(mem_size),
        .load_unsigned(load_unsigned), .is_muldiv(is_muldiv), .muldiv_op(muldiv_op),
        .mem_addr(mem_addr), .mem_write_data(mem_write_data),
        .mem_write_strobe(mem_write_strobe), .pc(pc)
    );

    assign mem_read  = legal && ctrl_mem_read;
    assign mem_write = legal && ctrl_mem_write;
endmodule

// Innovus top-level wrapper. The top-level name matches the source filename.
module single_cycle_Innovus (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] imem_rdata,
    output wire [31:0] imem_addr,
    input  wire [31:0] dmem_rdata,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    output wire        dmem_re,
    output wire        dmem_we
);
    cpu u_cpu (
        .clk(clk),
        .reset(rst),
        .instruction(imem_rdata),
        .mem_read_data(dmem_rdata),
        .pc(imem_addr),
        .mem_addr(dmem_addr),
        .mem_write_data(dmem_wdata),
        .mem_write_strobe(dmem_wstrb),
        .mem_read(dmem_re),
        .mem_write(dmem_we)
    );
endmodule
