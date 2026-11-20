`timescale 1ns/1ps

module ReLU_Q16 #(
    parameter DATA_WIDTH = 16
) (
    input wire signed [DATA_WIDTH-1:0]               data_i,
    output wire signed [DATA_WIDTH-1:0]              data_o
);

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    assign data_o = data_i[DATA_WIDTH-1] ? {DATA_WIDTH{1'b0}} : data_i;
endmodule
