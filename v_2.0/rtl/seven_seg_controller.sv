`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Seven-segment display controller for Nexys A7 (Fixed)
//////////////////////////////////////////////////////////////////////////////////

module seven_seg_controller (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] data,      // 32-bit data to display
    output logic [7:0]  anode,     // Anode control (active low)
    output logic [6:0]  cathode,   // Cathode control (active low)
    output logic        dp_out     // Decimal point
);

    // Clock divider for display refresh
    logic [19:0] refresh_counter;
    logic [2:0]  digit_select;
    logic [3:0]  current_digit;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            refresh_counter <= 20'h0;
        else
            refresh_counter <= refresh_counter + 1;
    end
    
    assign digit_select = refresh_counter[19:17];
    
    // Digit multiplexing
    always_comb begin
        case (digit_select)
            3'b000: begin
                anode = 8'b11111110;
                current_digit = data[3:0];
            end
            3'b001: begin
                anode = 8'b11111101;
                current_digit = data[7:4];
            end
            3'b010: begin
                anode = 8'b11111011;
                current_digit = data[11:8];
            end
            3'b011: begin
                anode = 8'b11110111;
                current_digit = data[15:12];
            end
            3'b100: begin
                anode = 8'b11101111;
                current_digit = data[19:16];
            end
            3'b101: begin
                anode = 8'b11011111;
                current_digit = data[23:20];
            end
            3'b110: begin
                anode = 8'b10111111;
                current_digit = data[27:24];
            end
            3'b111: begin
                anode = 8'b01111111;
                current_digit = data[31:28];
            end
        endcase
    end
    
    // Seven-segment decoder (FIXED - proper patterns)
    always_comb begin
        case (current_digit)
            4'h0: cathode = 7'b1000000;  // 0
            4'h1: cathode = 7'b1111001;  // 1
            4'h2: cathode = 7'b0100100;  // 2
            4'h3: cathode = 7'b0110000;  // 3
            4'h4: cathode = 7'b0011001;  // 4
            4'h5: cathode = 7'b0010010;  // 5
            4'h6: cathode = 7'b0000010;  // 6
            4'h7: cathode = 7'b1111000;  // 7
            4'h8: cathode = 7'b0000000;  // 8
            4'h9: cathode = 7'b0010000;  // 9
            4'hA: cathode = 7'b0001000;  // A
            4'hB: cathode = 7'b0000011;  // b
            4'hC: cathode = 7'b1000110;  // C
            4'hD: cathode = 7'b0100001;  // d
            4'hE: cathode = 7'b0000110;  // E
            4'hF: cathode = 7'b0001110;  // F
        endcase
    end
    
    assign dp_out = 1'b1;  // Decimal point off
    
endmodule
