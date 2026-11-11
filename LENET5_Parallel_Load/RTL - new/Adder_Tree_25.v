`timescale 1ns/1ps
// Five registered adder levels. Shift each signed product before summing.
// Full-width partial sum: no bias, saturation or ReLU at this level.

module Adder_Tree_25 #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 8,
    parameter ACC_WIDTH = 48
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire [25*2*DATA_WIDTH-1:0]                 product_i,
    input wire                                       valid_i,
    output wire signed [ACC_WIDTH-1:0]               sum_o,
    output wire                                      valid_o
);

    //-------------------------------------//
    //        Register Declarations        //
    //-------------------------------------//
    reg signed [ACC_WIDTH-1:0] level0_r [0:12];
    reg signed [ACC_WIDTH-1:0] level1_r [0:6];
    reg signed [ACC_WIDTH-1:0] level2_r [0:3];
    reg signed [ACC_WIDTH-1:0] level3_r [0:1];
    reg signed [ACC_WIDTH-1:0] level4_r;
    reg [4:0] valid_r;

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire signed [2*DATA_WIDTH-1:0] raw_w [0:24];
    wire signed [ACC_WIDTH-1:0] term_w [0:24];

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    assign raw_w[0] = product_i[0*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[0] = $signed(raw_w[0]) >>> FRAC_BITS;
    assign raw_w[1] = product_i[1*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[1] = $signed(raw_w[1]) >>> FRAC_BITS;
    assign raw_w[2] = product_i[2*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[2] = $signed(raw_w[2]) >>> FRAC_BITS;
    assign raw_w[3] = product_i[3*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[3] = $signed(raw_w[3]) >>> FRAC_BITS;
    assign raw_w[4] = product_i[4*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[4] = $signed(raw_w[4]) >>> FRAC_BITS;
    assign raw_w[5] = product_i[5*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[5] = $signed(raw_w[5]) >>> FRAC_BITS;
    assign raw_w[6] = product_i[6*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[6] = $signed(raw_w[6]) >>> FRAC_BITS;
    assign raw_w[7] = product_i[7*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[7] = $signed(raw_w[7]) >>> FRAC_BITS;
    assign raw_w[8] = product_i[8*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[8] = $signed(raw_w[8]) >>> FRAC_BITS;
    assign raw_w[9] = product_i[9*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[9] = $signed(raw_w[9]) >>> FRAC_BITS;
    assign raw_w[10] = product_i[10*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[10] = $signed(raw_w[10]) >>> FRAC_BITS;
    assign raw_w[11] = product_i[11*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[11] = $signed(raw_w[11]) >>> FRAC_BITS;
    assign raw_w[12] = product_i[12*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[12] = $signed(raw_w[12]) >>> FRAC_BITS;
    assign raw_w[13] = product_i[13*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[13] = $signed(raw_w[13]) >>> FRAC_BITS;
    assign raw_w[14] = product_i[14*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[14] = $signed(raw_w[14]) >>> FRAC_BITS;
    assign raw_w[15] = product_i[15*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[15] = $signed(raw_w[15]) >>> FRAC_BITS;
    assign raw_w[16] = product_i[16*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[16] = $signed(raw_w[16]) >>> FRAC_BITS;
    assign raw_w[17] = product_i[17*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[17] = $signed(raw_w[17]) >>> FRAC_BITS;
    assign raw_w[18] = product_i[18*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[18] = $signed(raw_w[18]) >>> FRAC_BITS;
    assign raw_w[19] = product_i[19*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[19] = $signed(raw_w[19]) >>> FRAC_BITS;
    assign raw_w[20] = product_i[20*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[20] = $signed(raw_w[20]) >>> FRAC_BITS;
    assign raw_w[21] = product_i[21*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[21] = $signed(raw_w[21]) >>> FRAC_BITS;
    assign raw_w[22] = product_i[22*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[22] = $signed(raw_w[22]) >>> FRAC_BITS;
    assign raw_w[23] = product_i[23*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[23] = $signed(raw_w[23]) >>> FRAC_BITS;
    assign raw_w[24] = product_i[24*2*DATA_WIDTH +: 2*DATA_WIDTH];
    assign term_w[24] = $signed(raw_w[24]) >>> FRAC_BITS;

    //-------------------------------------//
    //        Adder Pipeline Level 0       //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            level0_r[0] <= 0;
            level0_r[1] <= 0;
            level0_r[2] <= 0;
            level0_r[3] <= 0;
            level0_r[4] <= 0;
            level0_r[5] <= 0;
            level0_r[6] <= 0;
            level0_r[7] <= 0;
            level0_r[8] <= 0;
            level0_r[9] <= 0;
            level0_r[10] <= 0;
            level0_r[11] <= 0;
            level0_r[12] <= 0;
        end
        else if (valid_i) begin
            level0_r[0] <= term_w[0] + term_w[1];
            level0_r[1] <= term_w[2] + term_w[3];
            level0_r[2] <= term_w[4] + term_w[5];
            level0_r[3] <= term_w[6] + term_w[7];
            level0_r[4] <= term_w[8] + term_w[9];
            level0_r[5] <= term_w[10] + term_w[11];
            level0_r[6] <= term_w[12] + term_w[13];
            level0_r[7] <= term_w[14] + term_w[15];
            level0_r[8] <= term_w[16] + term_w[17];
            level0_r[9] <= term_w[18] + term_w[19];
            level0_r[10] <= term_w[20] + term_w[21];
            level0_r[11] <= term_w[22] + term_w[23];
            level0_r[12] <= term_w[24];
        end
    end

    //-------------------------------------//
    //        Adder Pipeline Level 1       //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            level1_r[0] <= 0;
            level1_r[1] <= 0;
            level1_r[2] <= 0;
            level1_r[3] <= 0;
            level1_r[4] <= 0;
            level1_r[5] <= 0;
            level1_r[6] <= 0;
        end
        else if (valid_r[0]) begin
            level1_r[0] <= level0_r[0] + level0_r[1];
            level1_r[1] <= level0_r[2] + level0_r[3];
            level1_r[2] <= level0_r[4] + level0_r[5];
            level1_r[3] <= level0_r[6] + level0_r[7];
            level1_r[4] <= level0_r[8] + level0_r[9];
            level1_r[5] <= level0_r[10] + level0_r[11];
            level1_r[6] <= level0_r[12];
        end
    end

    //-------------------------------------//
    //        Adder Pipeline Level 2       //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            level2_r[0] <= 0;
            level2_r[1] <= 0;
            level2_r[2] <= 0;
            level2_r[3] <= 0;
        end
        else if (valid_r[1]) begin
            level2_r[0] <= level1_r[0] + level1_r[1];
            level2_r[1] <= level1_r[2] + level1_r[3];
            level2_r[2] <= level1_r[4] + level1_r[5];
            level2_r[3] <= level1_r[6];
        end
    end

    //-------------------------------------//
    //        Adder Pipeline Level 3       //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            level3_r[0] <= 0;
            level3_r[1] <= 0;
        end
        else if (valid_r[2]) begin
            level3_r[0] <= level2_r[0] + level2_r[1];
            level3_r[1] <= level2_r[2] + level2_r[3];
        end
    end

    //-------------------------------------//
    //     Final Sum and Valid Pipeline    //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            valid_r <= 0;
            level4_r <= 0;
        end
        else begin
            valid_r <= {valid_r[3:0], valid_i};
            if (valid_r[3]) level4_r <= level3_r[0]+level3_r[1];
        end
    end
    assign sum_o = level4_r;
    assign valid_o = valid_r[4];
endmodule
