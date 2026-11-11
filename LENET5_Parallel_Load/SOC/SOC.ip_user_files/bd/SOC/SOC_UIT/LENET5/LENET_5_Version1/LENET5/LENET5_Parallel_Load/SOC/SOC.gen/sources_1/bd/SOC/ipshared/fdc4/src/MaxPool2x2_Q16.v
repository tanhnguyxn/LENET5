`timescale 1ns/1ps

module MaxPool2x2_Q16 #(
    parameter DATA_WIDTH = 16
) (
    input wire signed [DATA_WIDTH-1:0]               data00_i,
    input wire signed [DATA_WIDTH-1:0]               data01_i,
    input wire signed [DATA_WIDTH-1:0]               data10_i,
    input wire signed [DATA_WIDTH-1:0]               data11_i,
    output wire signed [DATA_WIDTH-1:0]              data_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire signed [DATA_WIDTH-1:0] max0_w, max1_w;

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    assign max0_w = (data00_i>data01_i)?data00_i:data01_i;
    assign max1_w = (data10_i>data11_i)?data10_i:data11_i;
    assign data_o = (max0_w>max1_w)?max0_w:max1_w;
endmodule
