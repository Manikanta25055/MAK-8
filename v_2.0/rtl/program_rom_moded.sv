`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Program ROM with mode-based program selection
//////////////////////////////////////////////////////////////////////////////////

module program_rom_moded #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 16,
    parameter ROM_SIZE = 256
)(
    input  logic                  clk,
    input  logic [2:0]            mode,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] instruction
);

    // ROM storage arrays for different modes
    logic [DATA_WIDTH-1:0] rom_free [0:ROM_SIZE-1];
    logic [DATA_WIDTH-1:0] rom_counter [0:ROM_SIZE-1];
    logic [DATA_WIDTH-1:0] rom_temp [0:ROM_SIZE-1];
    
    // Initialize ROMs
    initial begin
        // Free mode program (default)
        for (int i = 0; i < ROM_SIZE; i++) begin
            rom_free[i] = 16'hF000;  // NOP
        end
        rom_free[0] = 16'h1100;  // ADDI R1, R0, 0
        rom_free[1] = 16'hE000;  // HLT
        
        // Counter mode program
        $readmemh("counter_program.mem", rom_counter);
        
        // Temperature mode program
        $readmemh("temperature_program.mem", rom_temp);
    end
    
    // Select ROM based on mode
    logic [DATA_WIDTH-1:0] selected_rom_data;
    
    always_comb begin
        case (mode)
            3'b001: selected_rom_data = rom_counter[addr[7:0]];
            3'b010: selected_rom_data = rom_temp[addr[7:0]];
            default: selected_rom_data = rom_free[addr[7:0]];
        endcase
    end
    
    // Synchronous read
    always_ff @(posedge clk) begin
        if (addr < ROM_SIZE) begin
            instruction <= selected_rom_data;
        end else begin
            instruction <= 16'hF000;  // NOP for out-of-range
        end
    end
    
endmodule
