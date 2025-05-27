`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Manikanta Gonugondla
// 
// Create Date: 12/28/2024
// Design Name: MAK-8 CPU
// Module Name: register_file_tb
// Project Name: MAK-8
// Target Devices: Nexys A7 100T (Simulation)
// Tool Versions: Vivado 2024.2
// Description: Comprehensive testbench for Register File Module
//              Tests all aspects including edge cases and timing scenarios
// 
// Dependencies: register_file.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// - Tests reset behavior, dual-port reads, R0 hardwiring
// - Includes stress testing and pipeline access patterns
// - Self-checking with automatic error counting
// 
//////////////////////////////////////////////////////////////////////////////////

module register_file_tb;

    // Testbench signals
    logic        clk;
    logic        rst_n;
    logic        wr_en;
    logic [2:0]  wr_addr;
    logic [7:0]  wr_data;
    logic [2:0]  rd_addr1;
    logic [7:0]  rd_data1;
    logic [2:0]  rd_addr2;
    logic [7:0]  rd_data2;
    logic [7:0]  debug_r1;
    logic [7:0]  debug_r2;
    logic [7:0]  debug_r3;
    
    // Test tracking variables
    integer test_num = 0;
    integer errors = 0;
    string test_phase;
    
    // Instantiate DUT (Device Under Test)
    register_file dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_addr1(rd_addr1),
        .rd_data1(rd_data1),
        .rd_addr2(rd_addr2),
        .rd_data2(rd_data2),
        .debug_r1(debug_r1),
        .debug_r2(debug_r2),
        .debug_r3(debug_r3)
    );
    
    // Clock generation - 100MHz (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Task to write to a register
    task write_register(input [2:0] addr, input [7:0] data);
        begin
            @(posedge clk);
            wr_en = 1'b1;
            wr_addr = addr;
            wr_data = data;
            @(posedge clk);
            wr_en = 1'b0;
            // Wait for write to complete
            #1;
        end
    endtask
    
    // Task to perform immediate write (no wait)
    task immediate_write(input [2:0] addr, input [7:0] data);
        begin
            wr_en = 1'b1;
            wr_addr = addr;
            wr_data = data;
        end
    endtask
    
    // Task to check a single register
    task check_register(input [2:0] addr, input [7:0] expected);
        begin
            rd_addr1 = addr;
            #1; // Small delay for combinational propagation
            test_num++;
            if (rd_data1 !== expected) begin
                $display("[%s] ERROR Test %3d: R%0d expected %02h, got %02h", 
                         test_phase, test_num, addr, expected, rd_data1);
                errors++;
            end else begin
                $display("[%s] PASS Test %3d: R%0d = %02h", 
                         test_phase, test_num, addr, rd_data1);
            end
        end
    endtask
    
    // Task to check dual port reads
    task check_dual_read(
        input [2:0] addr1, input [7:0] expected1,
        input [2:0] addr2, input [7:0] expected2
    );
        begin
            rd_addr1 = addr1;
            rd_addr2 = addr2;
            #1; // Combinational delay
            test_num++;
            if (rd_data1 !== expected1 || rd_data2 !== expected2) begin
                $display("[%s] ERROR Test %3d: Dual read failed", test_phase, test_num);
                $display("  Port1: R%0d expected %02h, got %02h", addr1, expected1, rd_data1);
                $display("  Port2: R%0d expected %02h, got %02h", addr2, expected2, rd_data2);
                errors++;
            end else begin
                $display("[%s] PASS Test %3d: Dual read R%0d=%02h, R%0d=%02h", 
                         test_phase, test_num, addr1, rd_data1, addr2, rd_data2);
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize signals
        $display("\n=== MAK-8 Register File Testbench ===");
        $display("Testing comprehensive register file functionality\n");
        
        test_phase = "INIT";
        rst_n = 1'b0;
        wr_en = 1'b0;
        wr_addr = 3'b000;
        wr_data = 8'h00;
        rd_addr1 = 3'b000;
        rd_addr2 = 3'b000;
        
        // Test 1: Reset Behavior
        test_phase = "RESET";
        $display("=== Test Phase 1: Reset Behavior ===");
        #20 rst_n = 1'b1;
        #10;
        
        // Verify all registers are reset to 0
        for (int i = 0; i < 8; i++) begin
            check_register(i[2:0], 8'h00);
        end
        
        // Test 2: Basic Write and Read Operations
        test_phase = "BASIC_WR";
        $display("\n=== Test Phase 2: Basic Write/Read Operations ===");
        
        // Write unique values to each register
        write_register(3'd1, 8'hAA);
        write_register(3'd2, 8'h55);
        write_register(3'd3, 8'hF0);
        write_register(3'd4, 8'h0F);
        write_register(3'd5, 8'h12);
        write_register(3'd6, 8'h34);
        write_register(3'd7, 8'h56);
        
        // Verify all writes
        check_register(3'd1, 8'hAA);
        check_register(3'd2, 8'h55);
        check_register(3'd3, 8'hF0);
        check_register(3'd4, 8'h0F);
        check_register(3'd5, 8'h12);
        check_register(3'd6, 8'h34);
        check_register(3'd7, 8'h56);
        
        // Test 3: R0 Hardwired to Zero
        test_phase = "R0_TEST";
        $display("\n=== Test Phase 3: R0 Hardwired Behavior ===");
        
        // Multiple attempts to write to R0
        write_register(3'b000, 8'hFF);
        check_register(3'b000, 8'h00);
        
        immediate_write(3'b000, 8'h42);
        @(posedge clk);
        wr_en = 1'b0;
        check_register(3'b000, 8'h00);
        
        // Test 4: Dual Port Reading
        test_phase = "DUAL_READ";
        $display("\n=== Test Phase 4: Dual Port Read Operations ===");
        
        // Read different registers on both ports
        check_dual_read(3'd1, 8'hAA, 3'd2, 8'h55);
        check_dual_read(3'd3, 8'hF0, 3'd7, 8'h56);
        
        // Read same register on both ports
        check_dual_read(3'd4, 8'h0F, 3'd4, 8'h0F);
        
        // Read R0 on both ports
        check_dual_read(3'd0, 8'h00, 3'd0, 8'h00);
        
        // Test 5: Write-Through Behavior
        test_phase = "WRITE_THRU";
        $display("\n=== Test Phase 5: Write-Through Timing ===");
        
        // Setup read address before write
        rd_addr1 = 3'd5;
        rd_addr2 = 3'd6;
        #1;
        $display("Before write: R5=%02h, R6=%02h", rd_data1, rd_data2);
        
        // Write to R5 and check immediate propagation
        @(posedge clk);
        immediate_write(3'd5, 8'hBE);
        // The write happens on the next clock edge
        @(posedge clk);
        wr_en = 1'b0;
        #1;
        $display("After write: R5=%02h, R6=%02h", rd_data1, rd_data2);
        check_register(3'd5, 8'hBE);
        
        // Test 6: Back-to-Back Writes
        test_phase = "B2B_WRITE";
        $display("\n=== Test Phase 6: Back-to-Back Write Operations ===");
        
        // Rapid consecutive writes to same register
        @(posedge clk);
        immediate_write(3'd2, 8'h11);
        @(posedge clk);
        immediate_write(3'd2, 8'h22);
        @(posedge clk);
        immediate_write(3'd2, 8'h33);
        @(posedge clk);
        wr_en = 1'b0;
        check_register(3'd2, 8'h33); // Should have last value
        
        // Test 7: Debug Output Verification
        test_phase = "DEBUG";
        $display("\n=== Test Phase 7: Debug Output Verification ===");
        
        // Write specific values to R1, R2, R3
        write_register(3'd1, 8'h01);
        write_register(3'd2, 8'h02);
        write_register(3'd3, 8'h03);
        
        #1;
        test_num++;
        if (debug_r1 !== 8'h01 || debug_r2 !== 8'h02 || debug_r3 !== 8'h03) begin
            $display("[%s] ERROR Test %3d: Debug outputs incorrect", test_phase, test_num);
            errors++;
        end else begin
            $display("[%s] PASS Test %3d: Debug outputs correct: R1=%02h R2=%02h R3=%02h", 
                     test_phase, test_num, debug_r1, debug_r2, debug_r3);
        end
        
        // Test 8: Stress Test - Random Operations
        test_phase = "STRESS";
        $display("\n=== Test Phase 8: Random Stress Test ===");
        
        for (int i = 0; i < 20; i++) begin
            logic [2:0] rand_addr = $random() & 3'b111;
            logic [7:0] rand_data = $random();
            
            if (rand_addr != 0) begin  // Don't try to verify R0 writes
                write_register(rand_addr, rand_data);
                check_register(rand_addr, rand_data);
            end
        end
        
        // Test 9: Pipeline-like Access Pattern
        test_phase = "PIPELINE";
        $display("\n=== Test Phase 9: Pipeline Access Pattern ===");
        
        // Simulate how a CPU pipeline might access registers
        @(posedge clk);
        rd_addr1 = 3'd1;  // Read operands
        rd_addr2 = 3'd2;
        #1;
        
        // Compute something (simulated)
        logic [7:0] computed_result = rd_data1 + rd_data2;
        
        @(posedge clk);
        immediate_write(3'd3, computed_result);  // Write result
        rd_addr1 = 3'd3;  // Immediately read it back
        @(posedge clk);
        wr_en = 1'b0;
        #1;
        
        test_num++;
        if (rd_data1 !== computed_result) begin
            $display("[%s] ERROR Test %3d: Pipeline pattern failed", test_phase, test_num);
            errors++;
        end else begin
            $display("[%s] PASS Test %3d: Pipeline pattern: R3 = R1 + R2 = %02h", 
                     test_phase, test_num, rd_data1);
        end
        
        // Final Summary
        #20;
        $display("\n=== Test Summary ===");
        $display("Total Tests Run: %0d", test_num);
        $display("Tests Passed: %0d", test_num - errors);
        $display("Tests Failed: %0d", errors);
        $display("Overall Result: %s", (errors == 0) ? "ALL TESTS PASSED!" : "SOME TESTS FAILED!");
        
        if (errors == 0) begin
            $display("\nRegister File is fully functional and ready for CPU integration!");
        end else begin
            $display("\nRegister File has issues that need to be fixed.");
        end
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #10000;  // 10 microseconds timeout
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule
