`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Manikanta Gonugondla
// 
// Create Date: 12/28/2024
// Design Name: MAK-8 CPU Pipelined
// Module Name: control_unit_pipeline
// Project Name: MAK-8
// Target Devices: Nexys A7 100T
// Tool Versions: Vivado 2024.2
// Description: Control Unit for Pipelined MAK-8 CPU
//              Manages pipeline control signals and hazard detection
// 
// Dependencies: None
// 
// Revision:
// Revision 0.02 - Modified for 3-stage pipeline
// Additional Comments:
// - Handles branch resolution in Execute stage
// - Manages pipeline flushes
// - No state machine needed for pipeline
// 
//////////////////////////////////////////////////////////////////////////////////

module control_unit_pipeline (
    input  logic        clk,
    input  logic        rst_n,
    
    // From instruction decoder (Execute stage)
    input  logic        branch,         // Branch instruction flag
    input  logic        jump,           // Jump instruction flag
    input  logic        halt,           // Halt instruction flag
    input  logic [2:0]  branch_cond,    // Branch condition
    input  logic [15:0] imm_ext,        // Sign-extended immediate (for branches)
    
    // From ALU (for branch decisions)
    input  logic        alu_zero,       // ALU zero flag
    input  logic        alu_negative,   // ALU negative flag
    
    // From register file (for branch comparisons)
    input  logic [7:0]  rs1_data,       // Register data for branch comparison
    
    // Pipeline control
    input  logic        valid,          // Execute stage valid
    
    // Control outputs
    output logic        pc_load,        // Load new PC value
    output logic [15:0] pc_offset,      // Offset for PC (branches/jumps)
    output logic        cpu_halt,       // CPU halt signal
    output logic        mem_enable,     // Enable memory operations
    output logic        reg_enable,     // Enable register writes
    output logic        flush_pipeline  // Flush pipeline on branch taken
);

    // CPU halt state (latched)
    logic halt_state;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            halt_state <= 1'b0;
        end else if (valid && halt) begin
            halt_state <= 1'b1;
        end
    end
    
    // Branch decision logic
    logic take_branch;
    always_comb begin
        take_branch = 1'b0;
        
        if (branch && valid) begin
            case (branch_cond)
                3'b000: take_branch = (rs1_data == 8'h00);        // BEQ
                3'b001: take_branch = (rs1_data != 8'h00);        // BNE
                3'b010: take_branch = rs1_data[7];                // BLT
                3'b011: take_branch = !rs1_data[7] || (rs1_data == 8'h00); // BGE
                default: take_branch = 1'b0;
            endcase
        end
    end
    
    // Control signal generation
    always_comb begin
        // Default values
        pc_load = 1'b0;
        pc_offset = 16'h0001;  // Default: PC + 1
        cpu_halt = halt_state;
        mem_enable = ~halt_state;     // Disable when halted
        reg_enable = ~halt_state;     // Disable when halted
        flush_pipeline = 1'b0;
        
        // Handle branches and jumps in Execute stage
        if (valid && !halt_state) begin
            if (jump || (branch && take_branch)) begin
                pc_load = 1'b1;
                pc_offset = imm_ext;
                flush_pipeline = 1'b1;  // Flush fetch and decode stages
            end
        end
    end
    
    // synthesis translate_off
    // Debug output
    always @(posedge clk) begin
        if (pc_load) begin
            $display("Pipeline Control: PC update with offset %04h, flush=%b", 
                     pc_offset, flush_pipeline);
        end
        
        if (branch && valid) begin
            $display("Pipeline Control: Branch condition %b, taken=%b", 
                     branch_cond, take_branch);
        end
        
        if (halt && valid) begin
            $display("Pipeline Control: CPU halting");
        end
    end
    // synthesis translate_on

endmodule
