`timescale 1ns/1ps
// Simple word-addressed host decoder, NOT an AXI4-Lite protocol endpoint.

module Arbiter #(
    parameter DATA_WIDTH = 16,
    parameter HOST_DATA_WIDTH = 64
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire [19:0]                                host_wr_addr_i,
    input wire [HOST_DATA_WIDTH-1:0]                 host_wr_data_i,
    input wire                                       host_wr_valid_i,
    input wire [19:0]                                host_rd_addr_i,
    input wire                                       host_rd_valid_i,
    output reg [HOST_DATA_WIDTH-1:0]                 host_rd_data_o,
    input wire                                       core_busy_i,
    input wire                                       core_done_i,
    input wire [10*DATA_WIDTH-1:0]                   core_logits_i,
    input wire [3:0]                                 core_pred_class_i,
    input wire signed [DATA_WIDTH-1:0]               core_pred_score_i,
    output reg                                       core_start_o,
    output reg                                       core_ifmap_wr_en_o,
    output wire [9:0]                                core_ifmap_wr_addr_o,
    output wire signed [DATA_WIDTH-1:0]              core_ifmap_wr_data_o,
    output reg                                       core_cfg_we_o,
    output reg [2:0]                                 core_cfg_layer_o,
    output reg                                       core_cfg_is_bias_o,
    output reg [15:0]                                core_cfg_addr_o,
    output wire signed [DATA_WIDTH-1:0]              core_cfg_data_o
);

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire signed [DATA_WIDTH-1:0] selected_logit_w;

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    assign selected_logit_w = core_logits_i[host_rd_addr_i[3:0]*DATA_WIDTH +: DATA_WIDTH];
    assign core_ifmap_wr_addr_o = host_wr_addr_i[9:0];
    assign core_ifmap_wr_data_o = host_wr_data_i[DATA_WIDTH-1:0];
    assign core_cfg_data_o = host_wr_data_i[DATA_WIDTH-1:0];

    //-------------------------------------//
    //         Combinational Logic         //
    //-------------------------------------//
    always @(*) begin
        core_start_o = 0;
        core_ifmap_wr_en_o = 0;
        core_cfg_we_o = 0;
        core_cfg_layer_o = 0;
        core_cfg_is_bias_o = 0;
        core_cfg_addr_o = host_wr_addr_i[15:0];
        if (rst_n_i && host_wr_valid_i && !core_busy_i) begin
            case (host_wr_addr_i[19:16])
                0: if (host_wr_addr_i[15:0] == 0) core_start_o = host_wr_data_i[0];
                1: if (host_wr_addr_i[15:0]<784) core_ifmap_wr_en_o = 1;
                2, 3, 4, 5, 6: begin
                    core_cfg_we_o = 1;
                    core_cfg_layer_o = host_wr_addr_i[18:16]-3'd2;
                end
                7: begin
                    core_cfg_we_o = 1;
                    core_cfg_layer_o = host_wr_addr_i[15:13];
                    core_cfg_is_bias_o = 1;
                    core_cfg_addr_o = {3'd0, host_wr_addr_i[12:0]};
                end
                default: begin
                end
            endcase
        end
    end

    //-------------------------------------//
    //           Sequential Logic          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) host_rd_data_o <= 0;
        else if (host_rd_valid_i) begin
            host_rd_data_o <= 0;
            case (host_rd_addr_i[19:16])
                0: if (host_rd_addr_i[15:0] == 0) host_rd_data_o <= {{(HOST_DATA_WIDTH-2){1'b0}}, core_done_i, core_busy_i};
                8: if (host_rd_addr_i[15:0] == 0)
                host_rd_data_o <= {{(HOST_DATA_WIDTH-DATA_WIDTH-4){1'b0}}, core_pred_class_i, core_pred_score_i};
                9: if (host_rd_addr_i[15:0]<10)
                host_rd_data_o <= {{(HOST_DATA_WIDTH-DATA_WIDTH){selected_logit_w[DATA_WIDTH-1]}}, selected_logit_w};
                default: host_rd_data_o <= 0;
            endcase
        end
    end
endmodule
