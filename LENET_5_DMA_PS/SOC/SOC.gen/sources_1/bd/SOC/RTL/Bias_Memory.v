`timescale 1ns/1ps
// Five layer memories with a shared one-word-per-clock read interface.
// Layer IDs: 0=Conv1, 1=Conv2, 2=FC1, 3=FC2, 4=FC3.
module Bias_Memory #(
    parameter DATA_WIDTH=16,
    parameter CONV1_CH=6,
    parameter CONV2_CH=16,
    parameter FC1_NEURONS=120,
    parameter FC2_NEURONS=84
) (
    input wire clk_i,
    input wire rst_n_i,
    input wire cfg_we_i,
    input wire [2:0] cfg_layer_i,
    input wire [12:0] cfg_row_i,
    input wire [127:0] cfg_data_i,
    input wire [15:0] cfg_strb_i,
    input wire rd_en_i,
    input wire [2:0] rd_layer_i,
    input wire [15:0] rd_addr_i,
    output reg [DATA_WIDTH-1:0] rd_data_o,
    output reg rd_valid_o
);

    //-------------------------------------//
    // Register and Wire Declarations
    //-------------------------------------//
    reg [2:0] layer_r;
    wire [DATA_WIDTH-1:0] data_0_w;
    wire [DATA_WIDTH-1:0] data_1_w;
    wire [DATA_WIDTH-1:0] data_2_w;
    wire [DATA_WIDTH-1:0] data_3_w;
    wire [DATA_WIDTH-1:0] data_4_w;

    //-------------------------------------//
    // Explicit Layer Memory Instances
    //-------------------------------------//
    Banked_RAM_128_16 #(
        .DEPTH(CONV1_CH)
    ) u_layer_0 (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i && rd_layer_i==3'd0),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(data_0_w),
        .host_we_i(rst_n_i && cfg_we_i && cfg_layer_i==3'd0),
        .host_row_i(cfg_row_i),
        .host_data_i(cfg_data_i),
        .host_strb_i(cfg_strb_i),
        .wr_en_i(1'b0), .wr_addr_i(16'd0), .wr_data_i(16'd0)
    );
    Banked_RAM_128_16 #(
        .DEPTH(CONV2_CH)
    ) u_layer_1 (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i && rd_layer_i==3'd1),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(data_1_w),
        .host_we_i(rst_n_i && cfg_we_i && cfg_layer_i==3'd1),
        .host_row_i(cfg_row_i),
        .host_data_i(cfg_data_i),
        .host_strb_i(cfg_strb_i),
        .wr_en_i(1'b0), .wr_addr_i(16'd0), .wr_data_i(16'd0)
    );
    Banked_RAM_128_16 #(
        .DEPTH(FC1_NEURONS)
    ) u_layer_2 (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i && rd_layer_i==3'd2),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(data_2_w),
        .host_we_i(rst_n_i && cfg_we_i && cfg_layer_i==3'd2),
        .host_row_i(cfg_row_i),
        .host_data_i(cfg_data_i),
        .host_strb_i(cfg_strb_i),
        .wr_en_i(1'b0), .wr_addr_i(16'd0), .wr_data_i(16'd0)
    );
    Banked_RAM_128_16 #(
        .DEPTH(FC2_NEURONS)
    ) u_layer_3 (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i && rd_layer_i==3'd3),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(data_3_w),
        .host_we_i(rst_n_i && cfg_we_i && cfg_layer_i==3'd3),
        .host_row_i(cfg_row_i),
        .host_data_i(cfg_data_i),
        .host_strb_i(cfg_strb_i),
        .wr_en_i(1'b0), .wr_addr_i(16'd0), .wr_data_i(16'd0)
    );
    Banked_RAM_128_16 #(
        .DEPTH(10)
    ) u_layer_4 (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i && rd_layer_i==3'd4),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(data_4_w),
        .host_we_i(rst_n_i && cfg_we_i && cfg_layer_i==3'd4),
        .host_row_i(cfg_row_i),
        .host_data_i(cfg_data_i),
        .host_strb_i(cfg_strb_i),
        .wr_en_i(1'b0), .wr_addr_i(16'd0), .wr_data_i(16'd0)
    );

    //-------------------------------------//
    // Registered Read Selection
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            layer_r <= 0;
            rd_valid_o <= 0;
        end else begin
            rd_valid_o <= rd_en_i;
            if (rd_en_i) layer_r <= rd_layer_i;
        end
    end
    always @(*) begin
        case (layer_r)
            3'd0: rd_data_o = data_0_w;
            3'd1: rd_data_o = data_1_w;
            3'd2: rd_data_o = data_2_w;
            3'd3: rd_data_o = data_3_w;
            3'd4: rd_data_o = data_4_w;
            default: rd_data_o = 0;
        endcase
    end
endmodule
