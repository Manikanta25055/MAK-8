`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/29/2025 03:05:26 PM
// Design Name: 
// Module Name: temp_sensor_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////




module temp_sensor_controller (
    input  logic        clk,
    input  logic        rst_n,
    inout  logic        sda,
    logic [7:0] temp_msb,
    logic [7:0] temp_lsb,
    logic [12:0] temp_valid,
    output logic        scl,
    output logic [11:0] temperature,
    output logic        valid
);

    // I2C timing parameters for 100MHz clock
    localparam CLOCK_DIV = 250;  // 100MHz / 250 = 400kHz I2C
    
    // State machine
    typedef enum logic [3:0] {
        IDLE,
        START,
        SEND_ADDR_W,
        SEND_REG,
        REPEATED_START,
        SEND_ADDR_R,
        READ_MSB,
        READ_LSB,
        STOP,
        WAIT
    } state_t;
    
    state_t state, next_state;
    
    // I2C signals
    logic sda_out, sda_oe;
    logic scl_out;
    logic [7:0] i2c_counter;
    logic [7:0] bit_counter;
    logic [7:0] data_out, data_in;
    logic [7:0] temp_msb, temp_lsb;
    
    // Clock divider
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            i2c_counter <= 8'h0;
        else if (i2c_counter == CLOCK_DIV - 1)
            i2c_counter <= 8'h0;
        else
            i2c_counter <= i2c_counter + 1;
    end
    
    logic i2c_clk;
    assign i2c_clk = (i2c_counter < CLOCK_DIV/2);
    
    // Bidirectional SDA
    assign sda = sda_oe ? sda_out : 1'bz;
    assign scl = scl_out;
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            scl_out <= 1'b1;
            sda_out <= 1'b1;
            sda_oe <= 1'b0;
            bit_counter <= 8'h0;
            temp_msb <= 8'h0;
            temp_lsb <= 8'h0;
            valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (i2c_counter == 0) begin
                        state <= START;
                        sda_oe <= 1'b1;
                        sda_out <= 1'b0;  // START condition
                    end
                end
                
                START: begin
                    if (i2c_counter == CLOCK_DIV/2) begin
                        scl_out <= 1'b0;
                        state <= SEND_ADDR_W;
                        data_out <= 8'h96;  // ADT7420 address + write
                        bit_counter <= 8'h08;
                    end
                end
                
                SEND_ADDR_W: begin
                    if (i2c_counter == 0) begin
                        sda_out <= data_out[7];
                        data_out <= {data_out[6:0], 1'b0};
                    end
                    if (i2c_counter == CLOCK_DIV/4) scl_out <= 1'b1;
                    if (i2c_counter == 3*CLOCK_DIV/4) scl_out <= 1'b0;
                    if (i2c_counter == CLOCK_DIV - 1) begin
                        bit_counter <= bit_counter - 1;
                        if (bit_counter == 1) begin
                            state <= SEND_REG;
                            data_out <= 8'h00;  // Temperature register
                            bit_counter <= 8'h08;
                        end
                    end
                end
                
                SEND_REG: begin
                    if (i2c_counter == 0) begin
                        sda_out <= data_out[7];
                        data_out <= {data_out[6:0], 1'b0};
                    end
                    if (i2c_counter == CLOCK_DIV/4) scl_out <= 1'b1;
                    if (i2c_counter == 3*CLOCK_DIV/4) scl_out <= 1'b0;
                    if (i2c_counter == CLOCK_DIV - 1) begin
                        bit_counter <= bit_counter - 1;
                        if (bit_counter == 1) begin
                            state <= REPEATED_START;
                        end
                    end
                end
                
                REPEATED_START: begin
                    if (i2c_counter == 0) sda_out <= 1'b1;
                   if (i2c_counter == CLOCK_DIV/4) scl_out <= 1'b1;
                   if (i2c_counter == CLOCK_DIV/2) sda_out <= 1'b0;  // Repeated START
                   if (i2c_counter == 3*CLOCK_DIV/4) scl_out <= 1'b0;
                   if (i2c_counter == CLOCK_DIV - 1) begin
                       state <= SEND_ADDR_R;
                       data_out <= 8'h97;  // ADT7420 address + read
                       bit_counter <= 8'h08;
                   end
               end
               
               SEND_ADDR_R: begin
                   if (i2c_counter == 0) begin
                       sda_out <= data_out[7];
                       data_out <= {data_out[6:0], 1'b0};
                   end
                   if (i2c_counter == CLOCK_DIV/4) scl_out <= 1'b1;
                   if (i2c_counter == 3*CLOCK_DIV/4) scl_out <= 1'b0;
                   if (i2c_counter == CLOCK_DIV - 1) begin
                       bit_counter <= bit_counter - 1;
                       if (bit_counter == 1) begin
                           state <= READ_MSB;
                           sda_oe <= 1'b0;  // Release SDA for reading
                           bit_counter <= 8'h08;
                       end
                   end
               end
               
               READ_MSB: begin
                   if (i2c_counter == CLOCK_DIV/4) scl_out <= 1'b1;
                   if (i2c_counter == CLOCK_DIV/2) data_in <= {data_in[6:0], sda};
                   if (i2c_counter == 3*CLOCK_DIV/4) scl_out <= 1'b0;
                   if (i2c_counter == CLOCK_DIV - 1) begin
                       bit_counter <= bit_counter - 1;
                       if (bit_counter == 1) begin
                           temp_msb <= data_in;
                           state <= READ_LSB;
                           bit_counter <= 8'h08;
                           sda_oe <= 1'b1;
                           sda_out <= 1'b0;  // ACK
                       end
                   end
               end
               
               READ_LSB: begin
                   if (bit_counter == 8'h08 && i2c_counter == 0) begin
                       sda_oe <= 1'b0;  // Release SDA after ACK
                   end
                   if (i2c_counter == CLOCK_DIV/4) scl_out <= 1'b1;
                   if (i2c_counter == CLOCK_DIV/2) data_in <= {data_in[6:0], sda};
                   if (i2c_counter == 3*CLOCK_DIV/4) scl_out <= 1'b0;
                   if (i2c_counter == CLOCK_DIV - 1) begin
                       bit_counter <= bit_counter - 1;
                       if (bit_counter == 1) begin
                           temp_lsb <= data_in;
                           state <= STOP;
                           sda_oe <= 1'b1;
                           sda_out <= 1'b1;  // NACK
                       end
                   end
               end
               
               STOP: begin
                   if (i2c_counter == 0) sda_out <= 1'b0;
                   if (i2c_counter == CLOCK_DIV/4) scl_out <= 1'b1;
                   if (i2c_counter == CLOCK_DIV/2) sda_out <= 1'b1;  // STOP condition
                   if (i2c_counter == CLOCK_DIV - 1) begin
                       state <= WAIT;
                       valid <= 1'b1;
                   end
               end
               
               WAIT: begin
                   valid <= 1'b0;
                   if (i2c_counter == 0) begin
                       state <= IDLE;  // Read temperature every cycle
                   end
               end
           endcase
       end
   end
   
   // Temperature output (12-bit from 16-bit register)
    assign temperature = temp_valid ? {temp_msb[6:0], temp_lsb[7:3]} : 12'h190; // Default 25°C
   
endmodule
