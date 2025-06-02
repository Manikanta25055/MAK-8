`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Manikanta Gonugondla
// 
// Create Date: 12/28/2024
// Design Name: MAK-8 CPU
// Module Name: data_memory
// Project Name: MAK-8
// Target Devices: Nexys A7 100T
// Tool Versions: Vivado 2024.2
// Description: Data Memory (RAM) for MAK-8 CPU
//              8-bit wide, 256 locations for simplified testing
//              Single port with read/write capability
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// - Synchronous write, asynchronous read
// - Can be expanded to larger sizes
// - Includes initialization for testing
// 
//////////////////////////////////////////////////////////////////////////////////

module data_memory #(
    parameter ADDR_WIDTH = 8,   // 256 locations for now (can be expanded to 16)
    parameter DATA_WIDTH = 8,   // 8-bit data
    parameter MEM_SIZE = 256    // Number of memory locations
)(
    input  logic                    clk,
    input  logic                    mem_read,      // Memory read enable
    input  logic                    mem_write,     // Memory write enable
    input  logic [ADDR_WIDTH-1:0]   address,       // Memory address
    input  logic [DATA_WIDTH-1:0]   write_data,    // Data to write
    output logic [DATA_WIDTH-1:0]   read_data      // Data read from memory
);

    // Memory array
    logic [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];
    
    // Initialize memory for testing (optional)
    initial begin
        // Clear all memory locations
        for (int i = 0; i < MEM_SIZE; i++) begin
            memory[i] = 8'h00;
        end
        
        // Pre-load some test data at specific locations
        memory[8'h00] = 8'h42;  // Test value at address 0
        memory[8'h01] = 8'h55;  // Test value at address 1
        memory[8'h10] = 8'hAA;  // Test value at address 16
        memory[8'hFF] = 8'h99;  // Test value at last address
        
        // synthesis translate_off
        $display("Data Memory initialized with test values");
        $display("  Addr 0x00: %02h", memory[8'h00]);
        $display("  Addr 0x01: %02h", memory[8'h01]);
        $display("  Addr 0x10: %02h", memory[8'h10]);
        $display("  Addr 0xFF: %02h", memory[8'hFF]);
        // synthesis translate_on
    end
    
    // Write operation - synchronous
    always_ff @(posedge clk) begin
        if (mem_write && !mem_read) begin  // Write only when write is enabled and read is disabled
            memory[address] <= write_data;
            
            // synthesis translate_off
            $display("Memory Write: Addr[%02h] <= %02h", address, write_data);
            // synthesis translate_on
        end
    end
    
    // Read operation - asynchronous
    always_comb begin
        if (mem_read) begin  // Read whenever read is enabled
            read_data = memory[address];
        end else begin
            read_data = 8'h00;  // Default value when not reading
        end
    end
    
    // synthesis translate_off
    // Debug: Monitor memory accesses
    always @(posedge clk) begin
        if (mem_read && !mem_write) begin
            // Use the actual memory content, not the potentially stale read_data
            $display("Memory Read: Addr[%02h] => %02h", address, memory[address]);
        end
    end
    // synthesis translate_on

endmodule
