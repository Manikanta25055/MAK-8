`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Manikanta Gonugondla
// 
// Create Date: 12/28/2024
// Design Name: MAK-8 CPU Pipelined
// Module Name: mak8_cpu_top_pipelined
// Project Name: MAK-8
// Target Devices: Nexys A7 100T
// Tool Versions: Vivado 2024.2
// Description: Pipelined version of MAK-8 8-bit RISC CPU
//              3-stage pipeline: Fetch, Decode, Execute
// 
// Dependencies: program_counter.sv, register_file.sv, alu.sv, 
//               instruction_decoder.sv, control_unit.sv, 
//               program_rom.sv, data_memory.sv
// 
// Revision:
// Revision 0.02 - Added 3-stage pipeline
// Additional Comments:
// - Maintains compatibility with original ISA
// - Adds hazard detection and forwarding
// 
//////////////////////////////////////////////////////////////////////////////////

module mak8_cpu_top_pipelined (
    input  logic        clk,            // System clock
    input  logic        rst_n,          // Active-low reset
    
    // External I/O connections
    input  logic [15:0] switches,       // Physical switches
    output logic [7:0]  leds,           // Physical LEDs (separate from debug)
    
    // Debug outputs for FPGA board
    output logic [7:0]  debug_r1,       // Register R1 value
    output logic [7:0]  debug_r2,       // Register R2 value
    output logic [7:0]  debug_r3,       // Register R3 value
    output logic        debug_halt,     // CPU halted indicator
    output logic [15:0] debug_pc,       // Current PC value
    
    // Status output for seven-segment
    output logic [2:0]  cpu_status,     // CPU status (FREE, RUN, BUSY, STALL)
    
    // Mode control
    input  logic        run_enable,     // CPU run/halt control
    input  logic [2:0]  mode            // Operating mode selection
);

    // ==================== PIPELINE REGISTERS ====================
    // Fetch/Decode Stage
    logic [15:0] fd_pc;
    logic [15:0] fd_instruction;
    logic        fd_valid;
    
    // Decode/Execute Stage
    logic [15:0] de_pc;
    logic [15:0] de_instruction;
    logic [3:0]  de_opcode;
    logic [2:0]  de_func;
    logic [2:0]  de_rd_addr;
    logic [2:0]  de_rs1_addr;
    logic [2:0]  de_rs2_addr;
    logic [5:0]  de_imm;
    logic [15:0] de_imm_ext;
    logic [2:0]  de_branch_cond;
    logic        de_reg_write;
    logic        de_alu_src;
    logic [2:0]  de_alu_op;
    logic        de_mem_read;
    logic        de_mem_write;
    logic        de_mem_to_reg;
    logic        de_branch;
    logic        de_jump;
    logic        de_halt;
    logic [7:0]  de_rs1_data;
    logic [7:0]  de_rs2_data;
    logic        de_valid;
    
    // Execute/Writeback signals
    logic [7:0]  ex_alu_result;
    logic [7:0]  ex_mem_data;
    logic [7:0]  ex_write_data;
    logic [2:0]  ex_rd_addr;
    logic        ex_reg_write;
    logic        ex_valid;
    
    // ==================== HAZARD DETECTION ====================
    logic stall_fetch;
    logic stall_decode;
    logic flush_pipeline;
    
    // Load-use hazard detection
    assign stall_decode = de_valid && de_mem_read && 
                         ((de_rd_addr == fd_rs1_addr) || (de_rd_addr == fd_rs2_addr)) && 
                         (de_rd_addr != 0);
    assign stall_fetch = stall_decode;
    
    // ==================== CPU STATUS ====================
    localparam STATUS_FREE = 3'b000;
    localparam STATUS_RUNNING = 3'b001;
    localparam STATUS_BUSY = 3'b010;
    localparam STATUS_STALLED = 3'b011;
    
    always_comb begin
        if (!run_enable || cpu_halt)
            cpu_status = STATUS_FREE;
        else if (stall_fetch || stall_decode)
            cpu_status = STATUS_STALLED;
        else if (de_valid || ex_valid)
            cpu_status = STATUS_BUSY;
        else
            cpu_status = STATUS_RUNNING;
    end
    
    // ==================== FETCH STAGE ====================
    // Program Counter signals
    logic        pc_load;
    logic [15:0] pc_offset;
    logic [15:0] pc_current;
    logic [15:0] pc_next;
    
    // Calculate next PC value
    assign pc_next = pc_current + pc_offset;
    
    // Modified Program Counter with stall support
    program_counter_pipeline pc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc_load(pc_load),
        .pc_new(pc_next),
        .stall(stall_fetch),
        .pc_out(pc_current)
    );
    
    // Instruction from ROM
    logic [15:0] instruction;
    
    // Modified Program ROM to support mode-based programs
    program_rom_moded #(
        .ADDR_WIDTH(16),
        .DATA_WIDTH(16),
        .ROM_SIZE(256)
    ) rom_inst (
        .clk(clk),
        .mode(mode),
        .addr(pc_current),
        .instruction(instruction)
    );
    
    // Fetch stage pipeline register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fd_valid <= 1'b0;
            fd_pc <= 16'h0000;
            fd_instruction <= 16'hF000;  // NOP
        end
        else if (flush_pipeline) begin
            fd_valid <= 1'b0;
            fd_instruction <= 16'hF000;  // Insert NOP on flush
        end
        else if (!stall_fetch && run_enable && !cpu_halt) begin
            fd_valid <= 1'b1;
            fd_pc <= pc_current;
            fd_instruction <= instruction;
        end
    end
    
    // ==================== DECODE STAGE ====================
    // Decoded instruction fields (from fetch stage)
    logic [3:0]  fd_opcode;
    logic [2:0]  fd_func;
    logic [2:0]  fd_rd_addr;
    logic [2:0]  fd_rs1_addr;
    logic [2:0]  fd_rs2_addr;
    logic [5:0]  fd_imm;
    logic [15:0] fd_imm_ext;
    logic [2:0]  fd_branch_cond;
    
    // Control signals from decoder
    logic        fd_reg_write;
    logic        fd_alu_src;
    logic [2:0]  fd_alu_op;
    logic        fd_mem_read;
    logic        fd_mem_write;
    logic        fd_mem_to_reg;
    logic        fd_branch;
    logic        fd_jump;
    logic        fd_halt;
    
    // Instantiate Instruction Decoder
    instruction_decoder decoder_inst (
        .instruction(fd_instruction),
        .opcode(fd_opcode),
        .func(fd_func),
        .rd_addr(fd_rd_addr),
        .rs1_addr(fd_rs1_addr),
        .rs2_addr(fd_rs2_addr),
        .imm(fd_imm),
        .imm_ext(fd_imm_ext),
        .branch_cond(fd_branch_cond),
        .reg_write(fd_reg_write),
        .alu_src(fd_alu_src),
        .alu_op(fd_alu_op),
        .mem_read(fd_mem_read),
        .mem_write(fd_mem_write),
        .mem_to_reg(fd_mem_to_reg),
        .branch(fd_branch),
        .jump(fd_jump),
        .halt(fd_halt)
    );
    
    // Register file signals
    logic [7:0]  rs1_data_raw;
    logic [7:0]  rs2_data_raw;
    logic [7:0]  rs1_data_forwarded;
    logic [7:0]  rs2_data_forwarded;
    
    // Instantiate Register File
    register_file regfile_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(ex_reg_write & ex_valid & !cpu_halt),
        .wr_addr(ex_rd_addr),
        .wr_data(ex_write_data),
        .rd_addr1(fd_rs1_addr),
        .rd_data1(rs1_data_raw),
        .rd_addr2(fd_rs2_addr),
        .rd_data2(rs2_data_raw),
        .debug_r1(debug_r1),
        .debug_r2(debug_r2),
        .debug_r3(debug_r3)
    );
    
    // Data forwarding logic
    always_comb begin
        // Forward from Execute stage if needed
        if (ex_valid && ex_reg_write && (ex_rd_addr == fd_rs1_addr) && (ex_rd_addr != 0))
            rs1_data_forwarded = ex_write_data;
        else
            rs1_data_forwarded = rs1_data_raw;
            
        if (ex_valid && ex_reg_write && (ex_rd_addr == fd_rs2_addr) && (ex_rd_addr != 0))
            rs2_data_forwarded = ex_write_data;
        else
            rs2_data_forwarded = rs2_data_raw;
    end
    
    // Decode stage pipeline register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            de_valid <= 1'b0;
            de_halt <= 1'b0;
        end
        else if (flush_pipeline) begin
            de_valid <= 1'b0;
            de_halt <= 1'b0;
        end
        else if (!stall_decode && fd_valid && run_enable) begin
            de_valid <= 1'b1;
            de_pc <= fd_pc;
            de_instruction <= fd_instruction;
            de_opcode <= fd_opcode;
            de_func <= fd_func;
            de_rd_addr <= fd_rd_addr;
            de_rs1_addr <= fd_rs1_addr;
            de_rs2_addr <= fd_rs2_addr;
            de_imm <= fd_imm;
            de_imm_ext <= fd_imm_ext;
            de_branch_cond <= fd_branch_cond;
            de_reg_write <= fd_reg_write;
            de_alu_src <= fd_alu_src;
            de_alu_op <= fd_alu_op;
            de_mem_read <= fd_mem_read;
            de_mem_write <= fd_mem_write;
            de_mem_to_reg <= fd_mem_to_reg;
            de_branch <= fd_branch;
            de_jump <= fd_jump;
            de_halt <= fd_halt;
            de_rs1_data <= rs1_data_forwarded;
            de_rs2_data <= rs2_data_forwarded;
        end
    end
    
    // ==================== EXECUTE STAGE ====================
    // ALU signals
    logic [7:0]  alu_input_b;
    logic [7:0]  alu_result;
    logic        alu_zero;
    logic        alu_carry;
    logic        alu_negative;
    
    // ALU input mux (register or immediate)
    assign alu_input_b = de_alu_src ? de_imm_ext[7:0] : de_rs2_data;
    
    // Special handling for LUI instruction (shift immediate left by 2)
    logic [7:0] alu_input_b_final;
    assign alu_input_b_final = (de_opcode == 4'b0110) ? {de_imm[5:0], 2'b00} : alu_input_b;
    
    // Instantiate ALU
    alu alu_inst (
        .a(de_rs1_data),
        .b(alu_input_b_final),
        .op(de_alu_op),
        .result(alu_result),
        .zero(alu_zero),
        .carry(alu_carry),
        .negative(alu_negative)
    );
    
    // Memory signals
    logic [7:0]  mem_address;
    logic [7:0]  mem_read_data;
    logic [7:0]  mem_write_data;
    logic [7:0]  dmem_read_data;
    logic [7:0]  io_read_data;
    logic        mem_is_io;
    
    // Memory address calculation
    assign mem_address = alu_result[7:0];
    assign mem_is_io = (mem_address >= 8'hF0);
    
    // For STB instruction, data comes from the register specified in rd field
    assign mem_write_data = (de_opcode == 4'b1000) ? de_rs1_data : de_rs2_data;
    
    // Control unit signals
    logic        cpu_halt;
    logic        mem_enable;
    logic        reg_enable;
    
    // Modified Control Unit for pipeline
    control_unit_pipeline ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .branch(de_branch),
        .jump(de_jump),
        .halt(de_halt),
        .branch_cond(de_branch_cond),
        .imm_ext(de_imm_ext),
        .alu_zero(alu_zero),
        .alu_negative(alu_negative),
        .rs1_data(de_rs1_data),
        .valid(de_valid),
        .pc_load(pc_load),
        .pc_offset(pc_offset),
        .cpu_halt(cpu_halt),
        .mem_enable(mem_enable),
        .reg_enable(reg_enable),
        .flush_pipeline(flush_pipeline)
    );
    
    // Instantiate Data Memory
    data_memory #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(8),
        .MEM_SIZE(256)
    ) dmem_inst (
        .clk(clk),
        .mem_read(de_mem_read & mem_enable & de_valid & !cpu_halt & !mem_is_io),
        .mem_write(de_mem_write & mem_enable & de_valid & !cpu_halt & !mem_is_io),
        .address(mem_address),
        .write_data(mem_write_data),
        .read_data(dmem_read_data)
    );
    
    // Extended I/O Module with temperature support
    io_module_extended io_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mem_read(de_mem_read & mem_enable & de_valid & !cpu_halt & mem_is_io),
        .mem_write(de_mem_write & mem_enable & de_valid & !cpu_halt & mem_is_io),
        .address(mem_address),
        .write_data(mem_write_data),
        .read_data(io_read_data),
        .switches(switches),
        .led_out(leds),
        .temp_data(8'h00)  // Will be connected from top level
    );
    
    // Memory read data mux
    assign mem_read_data = mem_is_io ? io_read_data : dmem_read_data;
    
    // Execute stage results
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_valid <= 1'b0;
            ex_reg_write <= 1'b0;
        end
        else if (de_valid && run_enable) begin
            ex_valid <= 1'b1;
            ex_alu_result <= alu_result;
            ex_mem_data <= mem_read_data;
            ex_write_data <= de_mem_to_reg ? mem_read_data : alu_result;
            ex_rd_addr <= de_rd_addr;
            ex_reg_write <= de_reg_write;
        end
        else begin
            ex_valid <= 1'b0;
            ex_reg_write <= 1'b0;
        end
    end
    
    // Debug outputs
    assign debug_halt = cpu_halt;
    assign debug_pc = pc_current;

endmodule
