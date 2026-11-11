`timescale 1ns/1ps
// Bias is applied exactly once, after the full reduction dimension.

module Postprocess_Q16 #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH = 48
) (
    input wire signed [ACC_WIDTH-1:0]                psum_i,
    input wire signed [DATA_WIDTH-1:0]               bias_i,
    input wire                                       relu_enable_i,
    output wire signed [DATA_WIDTH-1:0]              data_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire signed [ACC_WIDTH-1:0] bias_ext_w, total_w, max_w, min_w;
    wire signed [DATA_WIDTH-1:0] saturated_w, relu_w;

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    assign bias_ext_w = {{(ACC_WIDTH-DATA_WIDTH){bias_i[DATA_WIDTH-1]}}, bias_i};
    assign total_w = psum_i+bias_ext_w;
    assign max_w = $signed({1'b0, {(DATA_WIDTH-1){1'b1}}});
    assign min_w = $signed({1'b1, {(DATA_WIDTH-1){1'b0}}});
    assign saturated_w = (total_w>max_w)?{1'b0, {(DATA_WIDTH-1){1'b1}}}:
    (total_w<min_w)?{1'b1, {(DATA_WIDTH-1){1'b0}}}:total_w[DATA_WIDTH-1:0];

    //-------------------------------------//
    //          ReLU Q16 Instance          //
    //-------------------------------------//
    ReLU_Q16 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_relu (
        .data_i                 (saturated_w),
        .data_o                 (relu_w)
    );
    assign data_o = relu_enable_i?relu_w:saturated_w;
endmodule
