`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Manikanta Gonugondla
// 
// Create Date: 12/28/2024
// Design Name: MAK-8 CPU
// Module Name: program_counter
// Project Name: MAK-8
// Target Devices: Nexys A7 100T
// Tool Versions: Vivado 2024.2
// Description: Program Counter Module for MAK-8 CPU
//              Manages instruction address for fetching from ROM
//              16-bit counter with load capability for branches/jumps
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// - Resets to address 0x0000
// - Supports normal increment and branch/jump operations
// 
//////////////////////////////////////////////////////////////////////////////////

module program_counter (
    input  logic        clk,        // System clock
    input  logic        rst_n,      // Active-low reset
    input  logic        pc_load,    // Load new PC value (for branches/jumps)
    input  logic [15:0] pc_new,     // New PC value to load
    output logic [15:0] pc_out      // Current PC value
);

    // PC register - 16 bits to address up to 64K instructions
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset PC to 0 - execution starts from address 0
            pc_out <= 16'h0000;
        end else if (pc_load) begin
            // Load new PC value (used for branches and jumps)
            pc_out <= pc_new;
        end else begin
            // Normal operation: increment PC by 1
            // Note: This assumes word-addressed memory (each instruction is 1 word)
            pc_out <= pc_out + 16'h0001;
        end
    end

endmodule
