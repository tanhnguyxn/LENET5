`timescale 1ns/1ps
// Four short line memories. Asynchronous taps preserve the original window timing.
// This module may map to distributed RAM or registers; it does not promise BRAM.
module Line_Buffer_Memory #(
    parameter DATA_WIDTH=16,
    parameter MAX_WIDTH=28
) (
    input wire clk_i,
    input wire rst_n_i,
    input wire enable_i,
    input wire [5:0] column_i,
    input wire [DATA_WIDTH-1:0] pixel_i,
    output wire [5*DATA_WIDTH-1:0] column_o
);
    //-------------------------------------//
    // Line Memory Declarations
    //-------------------------------------//
    reg signed [DATA_WIDTH-1:0] line0_r[0:MAX_WIDTH-1];
    reg signed [DATA_WIDTH-1:0] line1_r[0:MAX_WIDTH-1];
    reg signed [DATA_WIDTH-1:0] line2_r[0:MAX_WIDTH-1];
    reg signed [DATA_WIDTH-1:0] line3_r[0:MAX_WIDTH-1];
    //-------------------------------------//
    // Column Read and Row Updates
    //-------------------------------------//
    assign column_o = {pixel_i,line0_r[column_i],line1_r[column_i],
                      line2_r[column_i],line3_r[column_i]};
    always @(posedge clk_i) begin
        if (rst_n_i && enable_i) begin
            line0_r[column_i] <= pixel_i;
            line1_r[column_i] <= line0_r[column_i];
            line2_r[column_i] <= line1_r[column_i];
            line3_r[column_i] <= line2_r[column_i];
        end
    end

endmodule
