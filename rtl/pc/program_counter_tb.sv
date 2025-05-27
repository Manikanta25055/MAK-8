`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Manikanta Gonugondla
// 
// Create Date: 12/28/2024
// Design Name: MAK-8 CPU
// Module Name: program_counter_tb
// Project Name: MAK-8
// Target Devices: Nexys A7 100T (Simulation)
// Tool Versions: Vivado 2024.2
// Description: Testbench for Program Counter Module
//              Tests reset, normal increment, and branch functionality
// 
// Dependencies: program_counter.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// - Verifies PC reset to 0
// - Tests sequential increment operation
// - Validates branch/jump functionality
// 
//////////////////////////////////////////////////////////////////////////////////

module program_counter_tb;

    // Testbench signals
    logic        clk;
    logic        rst_n;
    logic        pc_load;
    logic [15:0] pc_new;
    logic [15:0] pc_out;
    
    // Instantiate DUT (Device Under Test)
    program_counter dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_load(pc_load),
        .pc_new(pc_new),
        .pc_out(pc_out)
    );
    
    // Clock generation - 100MHz (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 1'b0;
        pc_load = 1'b0;
        pc_new = 16'h0000;
        
        // Display header
        $display("=== Program Counter Testbench ===");
        $display("Time\tReset\tLoad\tNew_PC\tPC_Out");
        $monitor("%0t\t%b\t%b\t%04h\t%04h", $time, rst_n, pc_load, pc_new, pc_out);
        
        // Test 1: Reset behavior
        #20 rst_n = 1'b1;  // Release reset
        
        // Test 2: Normal increment operation
        // PC should increment: 0 -> 1 -> 2 -> 3...
        repeat(5) @(posedge clk);
        
        // Test 3: Branch/Jump operation
        @(posedge clk);
        pc_new = 16'h0100;  // Jump to address 0x100
        pc_load = 1'b1;
        @(posedge clk);
        pc_load = 1'b0;
        
        // Test 4: Continue normal operation after jump
        repeat(3) @(posedge clk);
        
        // Test 5: Another jump
        @(posedge clk);
        pc_new = 16'hFF00;  // Jump to high address
        pc_load = 1'b1;
        @(posedge clk);
        pc_load = 1'b0;
        
        // Let it run a bit more
        repeat(3) @(posedge clk);
        
        // Test 6: Reset during operation
        @(posedge clk);
        rst_n = 1'b0;
        repeat(2) @(posedge clk);
        rst_n = 1'b1;
        
        // Final check
        repeat(3) @(posedge clk);
        
        $display("\n=== Test Complete ===");
        $finish;
    end
    
    // Optional: Add assertions for self-checking
    property reset_check;
        @(posedge clk) !rst_n |-> pc_out == 16'h0000;
    endproperty
    
    property increment_check;
        @(posedge clk) (rst_n && !pc_load) |-> pc_out == $past(pc_out) + 1;
    endproperty
    
    property load_check;
        @(posedge clk) (rst_n && pc_load) |-> pc_out == pc_new;
    endproperty
    
    // Assert the properties
    assert property(reset_check) else $error("Reset failed!");
    assert property(increment_check) else $error("Increment failed!");
    assert property(load_check) else $error("Load failed!");

endmodule
