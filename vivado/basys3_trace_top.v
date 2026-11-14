// Basys3 instruction-trace wrapper.
//
// sw[15] enables execution. sw[8:0] select UART fields:
//   sw[0] PC, sw[1] instruction, sw[2] data address, sw[3] store data,
//   sw[4] cycle count, sw[5] instruction count, sw[6] store count,
//   sw[7] load data, sw[8] expected test result.
// The CPU advances once per selected UART report, so sw[15] also acts as a
// pause switch while a report is being transmitted.
module basys3_trace_top #(
    parameter integer IMEM_DEPTH = 1024,
    parameter integer DMEM_DEPTH = 256,
    parameter integer UART_BAUD_DIV = 868,
    parameter integer CPU_DIVIDER = 10000000,
    parameter IMEM_FILE = "C:/Users/watts/RISC-V-CPU-Project/sim/test_programs/basys3_rv32i_edgecase.hex"
) (
    input  wire        clk,
    input  wire        btnC,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire        uart_tx
);
    reg [31:0] imem [0:IMEM_DEPTH-1];
    reg [31:0] dmem [0:DMEM_DEPTH-1];
    integer i;

    reg [31:0] cycle_count;
    reg [31:0] instruction_count;
    reg [31:0] store_count;

    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire [3:0]  dmem_wstrb;
    wire        dmem_re;
    wire        dmem_we;
    wire        trace_busy;
    wire [10:0] trace_fields = {1'b1, 1'b1, sw[8:0]};
    reg [31:0]  cpu_divider_count;
    wire        divider_tick = (CPU_DIVIDER <= 1) ||
                                (cpu_divider_count >= CPU_DIVIDER - 1);
    wire        cpu_enable = sw[15] && (|trace_fields) && !trace_busy &&
                             divider_tick;
    wire [1:0]  result_status =
        (dmem_we && dmem_addr == 32'b0 && dmem_wdata == 32'h600D600D) ? 2'd1 :
        (dmem_we && dmem_addr == 32'b0 && dmem_wdata == 32'hDEADFA11) ? 2'd2 :
        2'd0;
    wire [1:0]  test_status =
        (dmem_we && dmem_addr == 32'h00000100) ? 2'd1 :
        (dmem_we && dmem_addr == 32'h00000104) ? 2'd2 :
        2'd0;

    initial begin
        for (i = 0; i < IMEM_DEPTH; i = i + 1)
            imem[i] = 32'b0;
        for (i = 0; i < DMEM_DEPTH; i = i + 1)
            dmem[i] = 32'b0;
        if (IMEM_FILE != "")
            $readmemh(IMEM_FILE, imem);
    end

    assign imem_rdata = (imem_addr[1:0] == 2'b00 &&
                         imem_addr[31:2] < IMEM_DEPTH) ?
                        imem[imem_addr[31:2]] : 32'b0;

    assign dmem_rdata = (dmem_re && dmem_addr[31:2] < DMEM_DEPTH) ?
                        dmem[dmem_addr[31:2]] : 32'b0;

    cpu u_cpu (
        .clk(clk),
        .reset(btnC),
        .enable(cpu_enable),
        .instruction(imem_rdata),
        .mem_read_data(dmem_rdata),
        .pc(imem_addr),
        .mem_addr(dmem_addr),
        .mem_write_data(dmem_wdata),
        .mem_write_strobe(dmem_wstrb),
        .mem_read(dmem_re),
        .mem_write(dmem_we)
    );

    instruction_trace_uart_reporter #(
        .BAUD_DIV(UART_BAUD_DIV)
    ) u_trace_reporter (
        .clk(clk),
        .rst(btnC),
        .start(cpu_enable),
        .field_enable(trace_fields),
        .result_status(result_status),
        .test_status(test_status),
        .test_id(dmem_wdata),
        .pc(imem_addr),
        .instruction(imem_rdata),
        .data_addr(dmem_addr),
        .store_data(dmem_wdata),
        .cycles(cycle_count + 32'd1),
        .instruction_count(instruction_count + 32'd1),
        .store_count(store_count + (dmem_we ? 32'd1 : 32'd0)),
        .load_data(dmem_rdata),
        .uart_tx(uart_tx),
        .busy(trace_busy)
    );

    assign led = imem_addr[15:0];

    always @(posedge clk) begin
        if (btnC) begin
            cpu_divider_count <= 32'b0;
            cycle_count <= 32'b0;
            instruction_count <= 32'b0;
            store_count <= 32'b0;
        end else begin
            if (!sw[15] || trace_busy || !(|trace_fields)) begin
                cpu_divider_count <= 32'b0;
            end else if (divider_tick) begin
                cpu_divider_count <= 32'b0;
            end else begin
                cpu_divider_count <= cpu_divider_count + 32'd1;
            end

            if (cpu_enable) begin
                cycle_count <= cycle_count + 32'd1;
                instruction_count <= instruction_count + 32'd1;
                if (dmem_we)
                    store_count <= store_count + 32'd1;
            end
        end
    end

    always @(posedge clk) begin
        if (dmem_we && dmem_addr[31:2] < DMEM_DEPTH) begin
            if (dmem_wstrb[0]) dmem[dmem_addr[31:2]][7:0] <= dmem_wdata[7:0];
            if (dmem_wstrb[1]) dmem[dmem_addr[31:2]][15:8] <= dmem_wdata[15:8];
            if (dmem_wstrb[2]) dmem[dmem_addr[31:2]][23:16] <= dmem_wdata[23:16];
            if (dmem_wstrb[3]) dmem[dmem_addr[31:2]][31:24] <= dmem_wdata[31:24];
        end
    end
endmodule
