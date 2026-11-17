`timescale 1ns/1ps
// 25 simultaneous lanes and one pipelined reduction tree; six-cycle latency.

module Conv_Bank_5x5 #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 8,
    parameter ACC_WIDTH = 48
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire                                       weight_load_i,
    input wire [25*DATA_WIDTH-1:0]                   weight_i,
    input wire [25*DATA_WIDTH-1:0]                   window_i,
    input wire                                       valid_i,
    output wire signed [ACC_WIDTH-1:0]               psum_o,
    output wire                                      valid_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire [25*2*DATA_WIDTH-1:0] product_w;
    wire [24:0] product_valid_w;

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_0 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[0*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[0*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[0*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[0])
    );

    //-------------------------------------//
    //              PE Lane 1              //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_1 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[1*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[1*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[1*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[1])
    );

    //-------------------------------------//
    //              PE Lane 2              //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_2 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[2*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[2*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[2*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[2])
    );

    //-------------------------------------//
    //              PE Lane 3              //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_3 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[3*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[3*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[3*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[3])
    );

    //-------------------------------------//
    //              PE Lane 4              //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_4 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[4*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[4*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[4*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[4])
    );

    //-------------------------------------//
    //              PE Lane 5              //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_5 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[5*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[5*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[5*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[5])
    );

    //-------------------------------------//
    //              PE Lane 6              //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_6 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[6*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[6*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[6*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[6])
    );

    //-------------------------------------//
    //              PE Lane 7              //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_7 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[7*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[7*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[7*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[7])
    );

    //-------------------------------------//
    //              PE Lane 8              //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_8 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[8*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[8*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[8*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[8])
    );

    //-------------------------------------//
    //              PE Lane 9              //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_9 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[9*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[9*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[9*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[9])
    );

    //-------------------------------------//
    //              PE Lane 10             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_10 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[10*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[10*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[10*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[10])
    );

    //-------------------------------------//
    //              PE Lane 11             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_11 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[11*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[11*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[11*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[11])
    );

    //-------------------------------------//
    //              PE Lane 12             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_12 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[12*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[12*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[12*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[12])
    );

    //-------------------------------------//
    //              PE Lane 13             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_13 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[13*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[13*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[13*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[13])
    );

    //-------------------------------------//
    //              PE Lane 14             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_14 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[14*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[14*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[14*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[14])
    );

    //-------------------------------------//
    //              PE Lane 15             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_15 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[15*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[15*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[15*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[15])
    );

    //-------------------------------------//
    //              PE Lane 16             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_16 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[16*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[16*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[16*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[16])
    );

    //-------------------------------------//
    //              PE Lane 17             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_17 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[17*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[17*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[17*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[17])
    );

    //-------------------------------------//
    //              PE Lane 18             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_18 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[18*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[18*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[18*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[18])
    );

    //-------------------------------------//
    //              PE Lane 19             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_19 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[19*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[19*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[19*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[19])
    );

    //-------------------------------------//
    //              PE Lane 20             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_20 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[20*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[20*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[20*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[20])
    );

    //-------------------------------------//
    //              PE Lane 21             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_21 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[21*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[21*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[21*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[21])
    );

    //-------------------------------------//
    //              PE Lane 22             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_22 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[22*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[22*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[22*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[22])
    );

    //-------------------------------------//
    //              PE Lane 23             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_23 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[23*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[23*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[23*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[23])
    );

    //-------------------------------------//
    //              PE Lane 24             //
    //-------------------------------------//
    PE_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pe_24 (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (weight_load_i),
        .weight_i               (weight_i[24*DATA_WIDTH +: DATA_WIDTH]),
        .ifmap_i                (window_i[24*DATA_WIDTH +: DATA_WIDTH]),
        .valid_i                (valid_i),
        .product_o              (product_w[24*2*DATA_WIDTH +: 2*DATA_WIDTH]),
        .valid_o                (product_valid_w[24])
    );

    //-------------------------------------//
    //        Adder Tree 25 Instance       //
    //-------------------------------------//
    Adder_Tree_25 #(
        .DATA_WIDTH             (DATA_WIDTH),
        .FRAC_BITS              (FRAC_BITS),
        .ACC_WIDTH              (ACC_WIDTH)
    ) u_tree (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .product_i              (product_w),
        .valid_i                (product_valid_w[0]),
        .sum_o                  (psum_o),
        .valid_o                (valid_o)
    );
endmodule
