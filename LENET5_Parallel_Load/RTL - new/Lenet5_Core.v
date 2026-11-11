`timescale 1ns/1ps

module Lenet5_Core #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 8,
    parameter ACC_WIDTH = 48,
    parameter CONV1_CH = 6,
    parameter CONV2_CH = 16,
    parameter FC1_NEURONS = 120,
    parameter FC2_NEURONS = 84,
    parameter HOST_DATA_WIDTH = 64
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire [19:0]                                host_wr_addr_i,
    input wire [HOST_DATA_WIDTH-1:0]                 host_wr_data_i,
    input wire                                       host_wr_valid_i,
    input wire [19:0]                                host_rd_addr_i,
    input wire                                       host_rd_valid_i,
    output wire [HOST_DATA_WIDTH-1:0]                host_rd_data_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire busy_w, done_w, start_w, ifmap_wr_en_w, cfg_we_w, cfg_is_bias_w;
    wire [9:0] ifmap_wr_addr_w;
    wire [15:0] cfg_addr_w;
    wire [2:0] cfg_layer_w;
    wire signed [DATA_WIDTH-1:0] ifmap_wr_data_w, cfg_data_w, pred_score_w;
    wire [10*DATA_WIDTH-1:0] logits_w;
    wire [3:0] pred_class_w;

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    Arbiter #(
        .DATA_WIDTH             (DATA_WIDTH),
        .HOST_DATA_WIDTH        (HOST_DATA_WIDTH)
    ) u_arbiter (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .host_wr_addr_i         (host_wr_addr_i),
        .host_wr_data_i         (host_wr_data_i),
        .host_wr_valid_i        (host_wr_valid_i),
        .host_rd_addr_i         (host_rd_addr_i),
        .host_rd_valid_i        (host_rd_valid_i),
        .host_rd_data_o         (host_rd_data_o),
        .core_busy_i            (busy_w),
        .core_done_i            (done_w),
        .core_logits_i          (logits_w),
        .core_pred_class_i      (pred_class_w),
        .core_pred_score_i      (pred_score_w),
        .core_start_o           (start_w),
        .core_ifmap_wr_en_o     (ifmap_wr_en_w),
        .core_ifmap_wr_addr_o   (ifmap_wr_addr_w),
        .core_ifmap_wr_data_o   (ifmap_wr_data_w),
        .core_cfg_we_o          (cfg_we_w),
        .core_cfg_layer_o       (cfg_layer_w),
        .core_cfg_is_bias_o     (cfg_is_bias_w),
        .core_cfg_addr_o        (cfg_addr_w),
        .core_cfg_data_o        (cfg_data_w)
    );

    //-------------------------------------//
    //        Lenet5 Engine Instance       //
    //-------------------------------------//
    Lenet5_Engine #(
        .DATA_WIDTH             (DATA_WIDTH),
        .FRAC_BITS              (FRAC_BITS),
        .ACC_WIDTH              (ACC_WIDTH),
        .CONV1_CH               (CONV1_CH),
        .CONV2_CH               (CONV2_CH),
        .FC1_NEURONS            (FC1_NEURONS),
        .FC2_NEURONS            (FC2_NEURONS)
    ) u_engine (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .start_i                (start_w),
        .busy_o                 (busy_w),
        .done_o                 (done_w),
        .ifmap_wr_en_i          (ifmap_wr_en_w),
        .ifmap_wr_addr_i        (ifmap_wr_addr_w),
        .ifmap_wr_data_i        (ifmap_wr_data_w),
        .cfg_we_i               (cfg_we_w),
        .cfg_layer_i            (cfg_layer_w),
        .cfg_is_bias_i          (cfg_is_bias_w),
        .cfg_addr_i             (cfg_addr_w),
        .cfg_data_i             (cfg_data_w),
        .logits_o               (logits_w),
        .pred_class_o           (pred_class_w),
        .pred_score_o           (pred_score_w)
    );
endmodule
