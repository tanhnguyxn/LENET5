`timescale 1ns/1ps
// One weight-stationary lane. Product and valid have one-cycle latency.

module PE_5x5 #(
    parameter DATA_WIDTH = 16
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire                                       weight_load_i,
    input wire signed [DATA_WIDTH-1:0]               weight_i,
    input wire signed [DATA_WIDTH-1:0]               ifmap_i,
    input wire                                       valid_i,
    output reg signed [2*DATA_WIDTH-1:0]             product_o,
    output reg                                       valid_o
);

    //-------------------------------------//
    //        Register Declarations        //
    //-------------------------------------//
    reg signed [DATA_WIDTH-1:0] weight_r;

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            weight_r <= 0;
            product_o <= 0;
            valid_o <= 0;
        end
        else begin
            if (weight_load_i) weight_r <= weight_i;
            valid_o <= valid_i;
            if (valid_i) product_o <= ifmap_i*weight_r;
        end
    end
endmodule
