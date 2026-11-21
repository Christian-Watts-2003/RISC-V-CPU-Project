// Basys3 wrapper for the modified multi-cycle RV32I core.
//
// The existing basys3_trace.xdc can be reused because this wrapper preserves
// the same top-level ports: clk, btnC, sw, led, and uart_tx.
module basys3_modified_top #(
    parameter integer IMEM_DEPTH = 1024,
    parameter integer DMEM_DEPTH = 256,
    parameter integer UART_BAUD_DIV = 868,
    parameter integer CPU_DIVIDER = 1,
    parameter IMEM_FILE = "sim/test_programs/basys3_rv32i_edgecase.hex"
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
    reg [31:0] divider_count;
    reg [31:0] trace_data_addr;
    reg [31:0] trace_store_data;
    reg [31:0] trace_load_data;
    reg [1:0]  trace_result_status;
    reg [1:0]  trace_test_status;
    reg [31:0] trace_test_id;

    wire [10:0] trace_fields = {1'b1, 1'b1, sw[8:0]};
    wire trace_busy;
    wire divider_tick = (CPU_DIVIDER <= 1) ||
                        (divider_count >= CPU_DIVIDER - 1);
    wire core_enable = sw[15] && !trace_busy && divider_tick;

    wire [31:0] mem_addr;
    wire [31:0] mem_write_data;
    wire [3:0]  mem_write_strobe;
    wire        mem_valid;
    wire        mem_read;
    wire        mem_write;
    wire        retire_valid;
    wire [31:0] retire_pc;
    wire [31:0] retire_instruction;
    wire dmem_in_range = (DMEM_DEPTH == 256) ?
        (mem_addr[31:10] == 22'b0) :
        (mem_addr[31:2] < DMEM_DEPTH);
    wire [31:0] mem_read_data =
        (mem_read && dmem_in_range) ?
        dmem[mem_addr[31:2]] : 32'b0;

    initial begin
        for (i = 0; i < IMEM_DEPTH; i = i + 1)
            imem[i] = 32'b0;
        for (i = 0; i < DMEM_DEPTH; i = i + 1)
            dmem[i] = 32'b0;
        if (IMEM_FILE != "")
            $readmemh(IMEM_FILE, imem);
    end

    wire [31:0] core_pc;
    wire imem_in_range = (IMEM_DEPTH == 1024) ?
                         (core_pc[31:12] == 20'b0) :
                         (core_pc[31:2] < IMEM_DEPTH);
    wire [31:0] instruction =
        (core_pc[1:0] == 2'b00 && imem_in_range) ?
        imem[core_pc[31:2]] : 32'b0;

    rv32i_multicycle u_cpu (
        .clk(clk),
        .reset(btnC),
        .enable(core_enable),
        .instruction(instruction),
        .mem_read_data(mem_read_data),
        .mem_ready(1'b1),
        .pc(core_pc),
        .mem_addr(mem_addr),
        .mem_write_data(mem_write_data),
        .mem_write_strobe(mem_write_strobe),
        .mem_valid(mem_valid),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .retire_valid(retire_valid),
        .retire_pc(retire_pc),
        .retire_instruction(retire_instruction)
    );

    instruction_trace_uart_reporter #(
        .BAUD_DIV(UART_BAUD_DIV)
    ) u_trace_reporter (
        .clk(clk),
        .rst(btnC),
        .start(retire_valid && sw[15]),
        .field_enable(trace_fields),
        .result_status(trace_result_status),
        .test_status(trace_test_status),
        .test_id(trace_test_id),
        .pc(retire_pc),
        .instruction(retire_instruction),
        .data_addr(trace_data_addr),
        .store_data(trace_store_data),
        .cycles(cycle_count),
        .instruction_count(instruction_count + 32'd1),
        .store_count(store_count),
        .load_data(trace_load_data),
        .uart_tx(uart_tx),
        .busy(trace_busy)
    );

    assign led = core_pc[15:0];

    always @(posedge clk) begin
        if (btnC) begin
            cycle_count <= 32'b0;
            instruction_count <= 32'b0;
            store_count <= 32'b0;
            divider_count <= 32'b0;
            trace_data_addr <= 32'b0;
            trace_store_data <= 32'b0;
            trace_load_data <= 32'b0;
            trace_result_status <= 2'b0;
            trace_test_status <= 2'b0;
            trace_test_id <= 32'b0;
        end else begin
            if (!sw[15] || trace_busy) begin
                divider_count <= 32'b0;
            end else if (divider_tick) begin
                divider_count <= 32'b0;
            end else begin
                divider_count <= divider_count + 32'd1;
            end

            if (core_enable)
                cycle_count <= cycle_count + 32'd1;
            if (retire_valid && sw[15])
                instruction_count <= instruction_count + 32'd1;

            if (mem_valid && mem_write) begin
                trace_data_addr <= mem_addr;
                trace_store_data <= mem_write_data;
                store_count <= store_count + 32'd1;
                trace_result_status <=
                    (mem_addr == 32'b0 && mem_write_data == 32'h600D600D) ? 2'd1 :
                    (mem_addr == 32'b0 && mem_write_data == 32'hDEADFA11) ? 2'd2 :
                    2'd0;
                trace_test_status <=
                    (mem_addr == 32'h00000100) ? 2'd1 :
                    (mem_addr == 32'h00000104) ? 2'd2 :
                    2'd0;
                trace_test_id <= mem_write_data;
            end
            if (mem_valid && mem_read) begin
                trace_data_addr <= mem_addr;
                trace_load_data <= mem_read_data;
            end
            if (retire_valid && !mem_valid) begin
                trace_result_status <= 2'b0;
                trace_test_status <= 2'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (mem_valid && mem_write && dmem_in_range) begin
            if (mem_write_strobe[0])
                dmem[mem_addr[31:2]][7:0] <= mem_write_data[7:0];
            if (mem_write_strobe[1])
                dmem[mem_addr[31:2]][15:8] <= mem_write_data[15:8];
            if (mem_write_strobe[2])
                dmem[mem_addr[31:2]][23:16] <= mem_write_data[23:16];
            if (mem_write_strobe[3])
                dmem[mem_addr[31:2]][31:24] <= mem_write_data[31:24];
        end
    end
endmodule
