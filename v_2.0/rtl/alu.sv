`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Manikanta Gonugondla
// 
// Create Date: 12/28/2024
// Design Name: MAK-8 CPU
// Module Name: alu
// Project Name: MAK-8
// Target Devices: Nexys A7 100T
// Tool Versions: Vivado 2024.2
// Description: Arithmetic Logic Unit (ALU) for MAK-8 CPU
//              Performs arithmetic and logical operations on 8-bit operands
//              Supports: ADD, SUB, AND, OR, XOR, NOT, SHL, SHR
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// - Generates Zero, Carry, and Negative flags
// - NOT operation uses only operand A
// - Shift operations use lower 3 bits of B for shift amount
// 
//////////////////////////////////////////////////////////////////////////////////

module alu (
    input  logic [7:0]  a,          // First operand
    input  logic [7:0]  b,          // Second operand
    input  logic [2:0]  op,         // Operation selector
    output logic [7:0]  result,     // Operation result
    output logic        zero,       // Zero flag (result == 0)
    output logic        carry,      // Carry/borrow flag
    output logic        negative    // Negative flag (MSB of result)
);

    // ALU operation codes matching our ISA
    localparam [2:0] ALU_ADD = 3'b000;  // Addition
    localparam [2:0] ALU_SUB = 3'b001;  // Subtraction
    localparam [2:0] ALU_AND = 3'b010;  // Bitwise AND
    localparam [2:0] ALU_OR  = 3'b011;  // Bitwise OR
    localparam [2:0] ALU_XOR = 3'b100;  // Bitwise XOR
    localparam [2:0] ALU_NOT = 3'b101;  // Bitwise NOT (uses only 'a')
    localparam [2:0] ALU_SHL = 3'b110;  // Shift left (a << b[2:0])
    localparam [2:0] ALU_SHR = 3'b111;  // Shift right (a >> b[2:0])
    
    // Internal signals for arithmetic operations
    logic [8:0] add_result;  // 9-bit to capture carry
    logic [8:0] sub_result;  // 9-bit to capture borrow
    
    // Perform all operations in parallel
    assign add_result = {1'b0, a} + {1'b0, b};
    assign sub_result = {1'b0, a} - {1'b0, b};
    
    // ALU operation selection
    always_comb begin
        // Default values
        result = 8'h00;
        carry = 1'b0;
        
        case (op)
            ALU_ADD: begin
                result = add_result[7:0];
                carry = add_result[8];  // Carry out
            end
            
            ALU_SUB: begin
                result = sub_result[7:0];
                carry = sub_result[8];  // Borrow (inverted)
            end
            
            ALU_AND: begin
                result = a & b;
                carry = 1'b0;  // No carry for logical ops
            end
            
            ALU_OR: begin
                result = a | b;
                carry = 1'b0;
            end
            
            ALU_XOR: begin
                result = a ^ b;
                carry = 1'b0;
            end
            
            ALU_NOT: begin
                result = ~a;  // Only uses 'a' input
                carry = 1'b0;
            end
            
            ALU_SHL: begin
                // Shift left by b[2:0] positions (0-7)
                result = a << b[2:0];
                // Carry gets the last bit shifted out
                carry = (b[2:0] == 0) ? 1'b0 : a[8 - b[2:0]];
            end
            
            ALU_SHR: begin
                // Shift right by b[2:0] positions (0-7)
                result = a >> b[2:0];
                // Carry gets the last bit shifted out
                carry = (b[2:0] == 0) ? 1'b0 : a[b[2:0] - 1];
            end
            
            default: begin
                result = 8'h00;
                carry = 1'b0;
            end
        endcase
    end
    
    // Status flags
    assign zero = (result == 8'h00);      // Zero flag
    assign negative = result[7];           // Sign bit (MSB)

endmodule
