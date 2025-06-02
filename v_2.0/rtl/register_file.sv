`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Manikanta Gonugondla
// 
// Create Date: 05/28/2025 12:01:51 AM
// Design Name: 
// Module Name: register_file
// Project Name: MAK-8
// Target Devices: Nexys A7 100T
// Tool Versions: 
// Description: Register File Module for MAK-8 CPU
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:8 general-purpose 8-bit registers (R0-R7)
// R0 is hardwired to 0 (cannot be written)
// Dual read ports, single write port
// 
//////////////////////////////////////////////////////////////////////////////////


module register_file (
    input  logic        clk,         // System clock
    input  logic        rst_n,       // Active-low reset
    
    // Write port
    input  logic        wr_en,       // Write enable
    input  logic [2:0]  wr_addr,     // Write register address (0-7)
    input  logic [7:0]  wr_data,     // Write data
    
    // Read port 1
    input  logic [2:0]  rd_addr1,    // Read address 1
    output logic [7:0]  rd_data1,    // Read data 1
    
    // Read port 2
    input  logic [2:0]  rd_addr2,    // Read address 2
    output logic [7:0]  rd_data2,    // Read data 2
    
    // Debug outputs for FPGA implementation
    output logic [7:0]  debug_r1,    // R1 value for LED display
    output logic [7:0]  debug_r2,    // R2 value for LED display
    output logic [7:0]  debug_r3     // R3 value for LED display
);

    // Register array - 8 registers of 8 bits each
    // R0 is not physically implemented since it's always 0
    logic [7:0] registers [1:7];  // Only R1 through R7
    
    // Write logic - synchronous write on clock edge
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers to 0
            // This helps with predictable behavior during testing
            for (int i = 1; i < 8; i++) begin
                registers[i] <= 8'h00;
            end
        end else if (wr_en && (wr_addr != 3'b000)) begin
            // Write to register if enabled and not R0
            // R0 write attempts are silently ignored
            registers[wr_addr] <= wr_data;
            
            // synthesis translate_off
            // Debug message for simulation
            $display("Time %0t: Register R%0d written with value %02h", 
                     $time, wr_addr, wr_data);
            // synthesis translate_on
        end
    end
    
    // Read logic - asynchronous/combinational read
    // This enables reading the newly written value in the same cycle
    // which is important for back-to-back instruction execution
    always_comb begin
        // Read port 1
        if (rd_addr1 == 3'b000) begin
            rd_data1 = 8'h00;  // R0 always reads as 0
        end else begin
            rd_data1 = registers[rd_addr1];
        end
        
        // Read port 2
        if (rd_addr2 == 3'b000) begin
            rd_data2 = 8'h00;  // R0 always reads as 0
        end else begin
            rd_data2 = registers[rd_addr2];
        end
    end
    
    // Debug outputs - useful for FPGA testing with LEDs
    // These show the current values of R1, R2, and R3
    always_comb begin
        debug_r1 = registers[1];
        debug_r2 = registers[2];
        debug_r3 = registers[3];
    end
    
    // synthesis translate_off
    // Simulation-only monitoring for debugging
    always @(posedge clk) begin
        if (wr_en) begin
            $display("RegFile Write: R%0d <= %02h", wr_addr, wr_data);
        end
    end
    
    // Display all register contents when they change
    always @(*) begin
        $display("RegFile State: R0=00 R1=%02h R2=%02h R3=%02h R4=%02h R5=%02h R6=%02h R7=%02h",
                 registers[1], registers[2], registers[3],
                 registers[4], registers[5], registers[6], registers[7]);
    end
    // synthesis translate_on

endmodule
