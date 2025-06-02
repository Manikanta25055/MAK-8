`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Extended I/O module with temperature data
//////////////////////////////////////////////////////////////////////////////////

module io_module_extended (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [7:0]  address,
    input  logic [7:0]  write_data,
    output logic [7:0]  read_data,
    
    // Physical I/O
    input  logic [15:0] switches,
    output logic [7:0]  led_out,
    input  logic [7:0]  temp_data
);

    // I/O registers
    logic [7:0] switch_reg;
    logic [7:0] led_reg;
    logic [7:0] temp_reg;
    
    // Capture inputs
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            switch_reg <= 8'h00;
            temp_reg <= 8'h00;
        end else begin
            switch_reg <= switches[7:0];
            temp_reg <= temp_data;
        end
    end
    
   
    // LED output register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_reg <= 8'h00;
        end else if (mem_write && address == 8'hF1) begin  // 0xF1 for LED register
            led_reg <= write_data;
        end
    end
    
    // Read logic
    always_comb begin
        read_data = 8'h00;
        if (mem_read) begin
            case (address)
                8'hF0: read_data = switch_reg;   // Read switches
                8'hF1: read_data = led_reg;       // Read LED state
                8'hF2: read_data = temp_reg;      // Read temperature
                default: read_data = 8'h00;
            endcase
        end
    end
    
    // Drive physical LEDs
    assign led_out = led_reg;
    
endmodule
