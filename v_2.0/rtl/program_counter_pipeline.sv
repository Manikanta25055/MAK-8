`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Modified program counter with stall support for pipeline
//////////////////////////////////////////////////////////////////////////////////

module program_counter_pipeline (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        pc_load,    // Load new PC value
    input  logic [15:0] pc_new,     // New PC value to load
    input  logic        stall,      // Stall signal from hazard detection
    output logic [15:0] pc_out      // Current PC value
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= 16'h0000;
        end else if (pc_load) begin
            pc_out <= pc_new;
        end else if (!stall) begin
            pc_out <= pc_out + 16'h0001;
        end
        // If stalled, PC remains unchanged
    end

endmodule
