`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Manikanta Gonugondla
// 
// Create Date: 12/28/2024
// Design Name: MAK-8 CPU
// Module Name: instruction_decoder
// Project Name: MAK-8
// Target Devices: Nexys A7 100T
// Tool Versions: Vivado 2024.2
// Description: Instruction Decoder for MAK-8 CPU
//              Decodes 16-bit instructions into control signals
//              Supports R-type, I-type, B-type, and M-type instructions
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// - Generates all control signals for CPU datapath
// - Handles immediate value sign extension
// - Supports all instruction formats defined in ISA
// 
//////////////////////////////////////////////////////////////////////////////////

module instruction_decoder (
    input  logic [15:0] instruction,      // 16-bit instruction from ROM
    
    // Decoded fields
    output logic [3:0]  opcode,           // Main operation code
    output logic [2:0]  func,             // Function code for R-type
    output logic [2:0]  rd_addr,          // Destination register
    output logic [2:0]  rs1_addr,         // Source register 1
    output logic [2:0]  rs2_addr,         // Source register 2
    output logic [5:0]  imm,              // 6-bit immediate (I-type, M-type)
    output logic [15:0] imm_ext,          // Sign-extended immediate
    output logic [2:0]  branch_cond,      // Branch condition (B-type)
    
    // Control signals
    output logic        reg_write,        // Enable register write
    output logic        alu_src,          // ALU source: 0=register, 1=immediate
    output logic [2:0]  alu_op,           // ALU operation
    output logic        mem_read,         // Memory read enable
    output logic        mem_write,        // Memory write enable
    output logic        mem_to_reg,       // Write memory data to register
    output logic        branch,           // Branch instruction
    output logic        jump,             // Jump instruction
    output logic        halt              // Halt CPU
);

    // Extract instruction fields
    always_comb begin
        // Common field extraction
        opcode = instruction[15:12];
        rd_addr = instruction[11:9];
        rs1_addr = instruction[8:6];
        
        // Format-specific field extraction
        case (opcode)
            // R-type instructions (arithmetic/logic with registers)
            4'b0000: begin
                rs2_addr = instruction[5:3];
                func = instruction[2:0];
                imm = 6'b0;
                branch_cond = 3'b0;
            end
            
            // I-type instructions (immediate operations)
            4'b0001, 4'b0010, 4'b0011, 4'b0100, 4'b0101, 4'b0110: begin
                rs2_addr = 3'b0;
                func = 3'b0;
                imm = instruction[5:0];
                branch_cond = 3'b0;
            end
            
            // M-type instructions (memory operations)
            4'b0111, 4'b1000: begin
                // For LDB: rd is destination, rs1 is base address
                // For STB: rd field contains source data register, rs1 is base address
                rs2_addr = (opcode == 4'b1000) ? rd_addr : 3'b0;  // STB uses rd field as source
                func = 3'b0;
                imm = instruction[5:0];
                branch_cond = 3'b0;
            end
            
            // B-type instructions (branches and jumps)
            4'b1001: begin
                rs2_addr = 3'b0;
                func = 3'b0;
                imm = instruction[5:0];
                branch_cond = instruction[11:9];  // Condition is in rd field position
            end
            
            // Special instructions
            default: begin
                rs2_addr = 3'b0;
                func = 3'b0;
                imm = 6'b0;
                branch_cond = 3'b0;
            end
        endcase
    end
    
    // Sign extension for immediate values
    assign imm_ext = {{10{imm[5]}}, imm};  // Sign extend to 16 bits
    
    // Control signal generation
    always_comb begin
        // Default control signals (NOP behavior)
        reg_write = 1'b0;
        alu_src = 1'b0;
        alu_op = 3'b000;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        halt = 1'b0;
        
        case (opcode)
            // R-type: Register-register ALU operations
            4'b0000: begin
                reg_write = 1'b1;
                alu_src = 1'b0;     // Use register rs2
                alu_op = func;      // ALU operation from func field
                mem_read = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 1'b0;  // ALU result to register
            end
            
            // ADDI: Add immediate
            4'b0001: begin
                reg_write = 1'b1;
                alu_src = 1'b1;     // Use immediate
                alu_op = 3'b000;    // ADD operation
                mem_to_reg = 1'b0;
            end
            
            // SUBI: Subtract immediate
            4'b0010: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 3'b001;    // SUB operation
                mem_to_reg = 1'b0;
            end
            
            // ANDI: AND immediate
            4'b0011: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 3'b010;    // AND operation
                mem_to_reg = 1'b0;
            end
            
            // ORI: OR immediate
            4'b0100: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 3'b011;    // OR operation
                mem_to_reg = 1'b0;
            end
            
            // XORI: XOR immediate
            4'b0101: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 3'b100;    // XOR operation
                mem_to_reg = 1'b0;
            end
            
            // LUI: Load upper immediate
            4'b0110: begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 3'b110;    // SHL operation (shift left by 2)
                mem_to_reg = 1'b0;
            end
            
            // LDB: Load byte
            4'b0111: begin
                reg_write = 1'b1;
                alu_src = 1'b1;     // Use immediate for address calculation
                alu_op = 3'b000;    // ADD for address calculation
                mem_read = 1'b1;
                mem_to_reg = 1'b1;  // Memory data to register
            end
            
            // STB: Store byte
            4'b1000: begin
                reg_write = 1'b0;   // No register write
                alu_src = 1'b1;     // Use immediate for address calculation
                alu_op = 3'b000;    // ADD for address calculation
                mem_write = 1'b1;
                mem_to_reg = 1'b0;
            end
            
            // Branch and jump instructions
            4'b1001: begin
                reg_write = (branch_cond == 3'b101) ? 1'b1 : 1'b0;  // JAL writes to register
                alu_src = 1'b0;
                alu_op = 3'b000;
                branch = (branch_cond < 3'b100) ? 1'b1 : 1'b0;      // Conditional branches
                jump = (branch_cond >= 3'b100) ? 1'b1 : 1'b0;       // JMP and JAL
            end
            
            // HLT: Halt instruction
            4'b1110: begin
                halt = 1'b1;
                // All other signals remain default (0)
            end
            
            // NOP and undefined instructions
            default: begin
                // All signals remain at default (NOP behavior)
            end
        endcase
    end

endmodule
