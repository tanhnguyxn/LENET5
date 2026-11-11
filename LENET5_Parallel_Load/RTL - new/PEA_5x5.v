`timescale 1ns/1ps
// Four output channels/neuron lanes share one 25-element input vector.

module PEA_5x5 #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 8,
    parameter ACC_WIDTH = 48
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire                                       weight_load_i,
    input wire [4*25*DATA_WIDTH-1:0]                 weight_i,
    input wire [25*DATA_WIDTH-1:0]                   window_i,
    input wire                                       valid_i,
    output wire [4*ACC_WIDTH-1:0]                    psum_o,
    output wire                                      valid_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire [3:0] valid_w;

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    Conv_Bank_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH),
        .FRAC_BITS              (FRAC_BITS),
        .ACC_WIDTH              (ACC_WIDTH)
    ) u_bank_0 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[0*25*DATA_WIDTH +: 25*DATA_WIDTH]),
        .window_i               (window_i),
        .valid_i                (valid_i),
        .psum_o                 (psum_o[0*ACC_WIDTH +: ACC_WIDTH]),
        .valid_o                (valid_w[0])
    );

    //-------------------------------------//
    //                Bank 1               //
    //-------------------------------------//
    Conv_Bank_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH),
        .FRAC_BITS              (FRAC_BITS),
        .ACC_WIDTH              (ACC_WIDTH)
    ) u_bank_1 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[1*25*DATA_WIDTH +: 25*DATA_WIDTH]),
        .window_i               (window_i),
        .valid_i                (valid_i),
        .psum_o                 (psum_o[1*ACC_WIDTH +: ACC_WIDTH]),
        .valid_o                (valid_w[1])
    );

    //-------------------------------------//
    //                Bank 2               //
    //-------------------------------------//
    Conv_Bank_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH),
        .FRAC_BITS              (FRAC_BITS),
        .ACC_WIDTH              (ACC_WIDTH)
    ) u_bank_2 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[2*25*DATA_WIDTH +: 25*DATA_WIDTH]),
        .window_i               (window_i),
        .valid_i                (valid_i),
        .psum_o                 (psum_o[2*ACC_WIDTH +: ACC_WIDTH]),
        .valid_o                (valid_w[2])
    );

    //-------------------------------------//
    //                Bank 3               //
    //-------------------------------------//
    Conv_Bank_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH),
        .FRAC_BITS              (FRAC_BITS),
        .ACC_WIDTH              (ACC_WIDTH)
    ) u_bank_3 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[3*25*DATA_WIDTH +: 25*DATA_WIDTH]),
        .window_i               (window_i),
        .valid_i                (valid_i),
        .psum_o                 (psum_o[3*ACC_WIDTH +: ACC_WIDTH]),
        .valid_o                (valid_w[3])
    );
    assign valid_o = valid_w[0];
endmodule
