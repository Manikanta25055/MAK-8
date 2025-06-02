`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Manikanta Gonugondla
// 
// Create Date: 12/28/2024
// Design Name: MAK-8 CPU with Pipeline
// Module Name: mak8_nexys_wrapper
// Project Name: MAK-8
// Target Devices: Nexys A7 100T
// Tool Versions: Vivado 2024.2
// Description: Top-level wrapper for MAK-8 Pipelined CPU on Nexys A7 board
//              Maps CPU signals to board I/O with seven-segment display
//              and temperature sensor support
// 
// Dependencies: mak8_cpu_top_pipelined.sv, seven_seg_controller.sv, 
//               temp_sensor_controller.sv and all sub-modules
// 
// Revision:
// Revision 0.02 - Added pipeline, seven-segment display, temperature sensor
// Additional Comments:
// - SW0: Halt/Resume CPU
// - SW1: Reset CPU  
// - SW14: Temperature display mode
// - SW15: Counter mode
// - Otherwise: Status display mode
// 
//////////////////////////////////////////////////////////////////////////////////

module mak8_nexys_wrapper (
    // Clock and Reset
    input  logic CLK100MHZ,     // 100MHz board clock
    input  logic [15:0] SW,     // Switches
    input  logic BTNC,          // Center button for reset
    input  logic BTNU,          // Up button for single step (if enabled)
    
    // LED Outputs
    output logic [15:0] LED,    // LEDs for register display
    output logic LED16_B,       // RGB LED for halt indicator
    output logic LED16_G,
    output logic LED16_R,
    output logic LED17_B,       // RGB LED for clock indicator
    output logic LED17_G,
    output logic LED17_R,
    
    // Seven-segment display
    output logic [7:0] AN,      // Anodes (active low)
    output logic [6:0] SEG,     // Cathodes (segments, active low)
    output logic DP,            // Decimal point
    
    // Temperature sensor I2C
    inout  logic TMP_SDA,       // I2C data
    output logic TMP_SCL        // I2C clock
);

    // Internal signals
    logic clk_cpu;
    logic rst_n;
    logic cpu_reset;
    logic cpu_run;
    logic [2:0] cpu_mode;
    logic [2:0] cpu_status;
    logic cpu_halt_internal;
    
    // CPU interface signals
    logic [15:0] pc_current;
    logic [7:0] debug_r1, debug_r2, debug_r3;
    logic [7:0] cpu_leds;
    
    // Temperature sensor signals
    logic [11:0] temperature_raw;
    logic temp_valid;
    logic [7:0] temperature_celsius;
    
    // Seven-segment display data
    logic [31:0] display_data;
    
    // Clock management
    logic [25:0] clk_counter = 0;
    logic clk_1hz;
    logic clk_display;  // Faster clock for seven-segment refresh
    
    always_ff @(posedge CLK100MHZ) begin
        clk_counter <= clk_counter + 1;
    end
    
    // Generate different clock speeds
    assign clk_1hz = clk_counter[25];      // ~1.5 Hz for visible operation
    assign clk_display = clk_counter[16];  // ~1.5 kHz for display refresh
    
    // CPU clock selection
    // SW[0] controls halt/resume (when 1, CPU is halted)
    // When not in single-step mode, use 1Hz clock
    logic single_step_mode;
    logic single_step_pulse;
    logic btnu_prev;
    
    assign single_step_mode = SW[2];  // SW2 enables single-step mode
    
    // Edge detection for single step
    always_ff @(posedge CLK100MHZ) begin
        btnu_prev <= BTNU;
    end
    assign single_step_pulse = BTNU & ~btnu_prev & single_step_mode;
    
    // CPU clock selection
    assign clk_cpu = (single_step_mode ? single_step_pulse : clk_1hz) & cpu_run;
    
    // Reset and control logic
    assign rst_n = ~BTNC;           // Hardware reset from center button
    assign cpu_reset = SW[1];       // SW1 for CPU reset
    assign cpu_run = ~SW[0];        // SW0 for halt/resume
    
    // Mode selection based on switches
    always_comb begin
        if (SW[15])
            cpu_mode = 3'b001;      // Counter mode
        else if (SW[14])
            cpu_mode = 3'b010;      // Temperature mode
        else
            cpu_mode = 3'b000;      // Free/idle mode (shows status)
    end
    
    // Instantiate pipelined CPU
    mak8_cpu_top_pipelined cpu_inst (
        .clk(clk_cpu),
        .rst_n(rst_n & ~cpu_reset),
        .switches(SW),              // Pass all switches to CPU
        .leds(cpu_leds),           // Get LED output from CPU I/O
        .debug_r1(debug_r1),
        .debug_r2(debug_r2),
        .debug_r3(debug_r3),
        .debug_halt(cpu_halt_internal),
        .debug_pc(pc_current),
        .cpu_status(cpu_status),
        .run_enable(cpu_run),
        .mode(cpu_mode)
    );
    
    // Temperature sensor controller
    temp_sensor_controller temp_ctrl (
        .clk(CLK100MHZ),           // Use full speed clock for I2C
        .rst_n(rst_n),
        .sda(TMP_SDA),
        .scl(TMP_SCL),
        .temperature(temperature_raw),
        .valid(temp_valid)
    );
    
    // Convert temperature to Celsius
    // ADT7420 gives 13-bit signed value in 0.0625°C units
    // For display, we'll show integer degrees
    always_comb begin
        temperature_celsius = temperature_raw[11:4];  // Get integer part
    end
    
    // Display data selection based on mode
  // In mak8_nexys_wrapper, fix the display data selection:

    // Display data selection based on mode
    always_comb begin
        case (cpu_mode)
            3'b001: begin  // Counter mode - display counter value
                // Show counter in hexadecimal
                display_data = {24'h000000, debug_r1};  // R1 contains counter
            end
            3'b010: begin  // Temperature mode
                // Display "t" followed by temperature
                logic [7:0] tens, ones;
                tens = temperature_celsius / 10;
                ones = temperature_celsius % 10;
                display_data = {8'h00, 8'h00, 8'h00, 8'h00, 8'h7F, 4'h0, tens[3:0], 4'h0, ones[3:0]};
            end
            default: begin  // Status display
                case (cpu_status)
                    3'b000: begin // "FREE"
                        display_data[31:24] = 8'h0F;  // F
                        display_data[23:16] = 8'h0A;  // r (use A)
                        display_data[15:8]  = 8'h0E;  // E
                        display_data[7:0]   = 8'h0E;  // E
                    end
                    3'b001: begin // "run"
                        display_data[31:24] = 8'h00;  // blank
                        display_data[23:16] = 8'h0A;  // r (use A)
                        display_data[15:8]  = 8'h00;  // u (use 0)
                        display_data[7:0]   = 8'h0A;  // n (use A)
                    end
                    3'b010: begin // "bUSY"
                        display_data[31:24] = 8'h0B;  // b
                        display_data[23:16] = 8'h00;  // U (use 0)
                        display_data[15:8]  = 8'h05;  // S (use 5)
                        display_data[7:0]   = 8'h04;  // Y (use 4)
                    end
                    3'b011: begin // "StAL"
                        display_data[31:24] = 8'h05;  // S
                        display_data[23:16] = 8'h07;  // t (use 7)
                        display_data[15:8]  = 8'h0A;  // A
                        display_data[7:0]   = 8'h01;  // L (use 1)
                    end
                    default: display_data = 32'h00000000;
                endcase
            end
        endcase
    end
    
    // Seven-segment display controller
    seven_seg_controller seg_ctrl (
        .clk(clk_display),
        .rst_n(rst_n),
        .data(display_data),
        .anode(AN),
        .cathode(SEG),
        .dp_out(DP)
    );
    
    // LED assignments
    // Show different information based on SW[3]
    always_comb begin
        if (SW[3]) begin
            // Debug mode: show registers
            LED[7:0] = debug_r1;
            LED[15:8] = debug_r2;
        end else begin
            // Normal mode: show CPU LEDs and PC
            LED[7:0] = cpu_leds;
            LED[15:8] = pc_current[7:0];
        end
    end
    
    // RGB LED indicators
    // LED16 (RGB): Status indicator
    always_comb begin
        case (cpu_status)
            3'b000: begin  // FREE - Blue
                LED16_R = 1'b0;
                LED16_G = 1'b0;
                LED16_B = 1'b1;
            end
            3'b001: begin  // RUNNING - Green
                LED16_R = 1'b0;
                LED16_G = 1'b1;
                LED16_B = 1'b0;
            end
            3'b010: begin  // BUSY - Yellow
                LED16_R = 1'b1;
                LED16_G = 1'b1;
                LED16_B = 1'b0;
            end
            3'b011: begin  // STALLED - Red
                LED16_R = 1'b1;
                LED16_G = 1'b0;
                LED16_B = 1'b0;
            end
            default: begin
                LED16_R = 1'b0;
                LED16_G = 1'b0;
                LED16_B = 1'b0;
            end
        endcase
    end
    
    // LED17 (RGB): Mode indicator
    always_comb begin
        case (cpu_mode)
            3'b001: begin  // Counter mode - Blue
                LED17_R = 1'b0;
                LED17_G = 1'b0;
                LED17_B = clk_cpu & ~cpu_halt_internal;
            end
            3'b010: begin  // Temperature mode - Cyan
                LED17_R = 1'b0;
                LED17_G = temp_valid;
                LED17_B = temp_valid;
            end
            default: begin  // Free mode - White pulse
                LED17_R = clk_cpu & cpu_run;
                LED17_G = clk_cpu & cpu_run;
                LED17_B = clk_cpu & cpu_run;
            end
        endcase
    end

endmodule
