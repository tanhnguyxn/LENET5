`timescale 1ns/1ps
// Three independent, ordered, fixed-one-cycle RAM read paths.
// Issue metadata is delayed with each response; inactive slots become zero.
module Parallel_Data_Loader #(parameter DATA_WIDTH=16) (
    input wire clk_i, rst_n_i, start_i,
    input wire input_enable_i, bias_enable_i,
    input wire [15:0] group_i, outputs_i, weight_mem_base_i, weight_mem_stride_i, input_base_i, // group_i nhan tu conv_ctrl, chi chay 0, 4, 8, 12, .... dang am chi cai base ma cua filter(output channel) dang duoc thuc thi 
    input wire [4:0] taps_i,
    input wire [DATA_WIDTH-1:0] input_rd_data_i,
    input wire input_rd_valid_i,
    input wire [DATA_WIDTH-1:0] weight_mem_rd_data_i,
    input wire weight_mem_rd_valid_i,
    input wire [DATA_WIDTH-1:0] bias_mem_rd_data_i,
    input wire bias_mem_rd_valid_i,
    output reg [100*DATA_WIDTH-1:0] weights_o, // co 4 kernel moi kernel 25 weight
    output reg [25*DATA_WIDTH-1:0] inputs_o, //1 lan stream can 25 input( chi co FC moi load input chung vs weight va bias)
    output reg [4*DATA_WIDTH-1:0] biases_o, // 4 bias cho 4 neuron ra
	output wire weight_mem_rd_en_o,
    output wire [15:0] weight_mem_rd_addr_o,
	output wire bias_mem_rd_en_o,
    output wire [15:0] bias_mem_rd_addr_o,
	output reg done_o,
    output wire input_rd_en_o,
    output wire [15:0] input_rd_addr_o
);
    //-------------------------------------//
    //        Register Declarations        //
    //-------------------------------------//
    reg active_r;
    reg [6:0] w_issue_r, w_done_r, w_tag_r;
    reg [4:0] w_tap_r, x_issue_r, x_done_r, x_tag_r;
    reg [1:0] w_bank_r;
    reg [2:0] b_issue_r, b_done_r, b_tag_r;
    reg w_slot_r, x_slot_r, b_slot_r;
    reg w_data_r, x_data_r, b_data_r;
    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire w_slot_w, x_slot_w, b_slot_w;
    assign w_slot_w = active_r && w_issue_r<100;
    assign x_slot_w = active_r && x_issue_r<25;
    assign b_slot_w = active_r && b_issue_r<4;
    assign weight_mem_rd_en_o = w_slot_w && group_i+w_bank_r<outputs_i && w_tap_r<taps_i;
    assign weight_mem_rd_addr_o = weight_mem_base_i+w_bank_r*weight_mem_stride_i+w_tap_r; // dia chi nen + offset
    assign input_rd_en_o = x_slot_w && input_enable_i && x_issue_r<taps_i;
    assign input_rd_addr_o = input_base_i+x_issue_r;
    assign bias_mem_rd_en_o = b_slot_w && bias_enable_i && group_i+b_issue_r<outputs_i;
    assign bias_mem_rd_addr_o = group_i+b_issue_r;
    //-------------------------------------//
    //           Sequential Logic          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            active_r<=0;
            done_o<=0;
            w_issue_r<=0;
            w_done_r<=0;
            w_tag_r<=0;
            w_tap_r<=0;
            w_bank_r<=0;
            x_issue_r<=0;
            x_done_r<=0;
            x_tag_r<=0;
            b_issue_r<=0;
            b_done_r<=0;
            b_tag_r<=0;
            w_slot_r<=0;
            x_slot_r<=0;
            b_slot_r<=0;
            w_data_r<=0;
            x_data_r<=0;
            b_data_r<=0;
            weights_o<=0;
            inputs_o<=0;
            biases_o<=0;
        end else if (start_i) begin
            active_r<=1;
            done_o<=0;
            w_issue_r<=0;
            w_done_r<=0;
            w_tap_r<=0;
            w_bank_r<=0;
            x_issue_r<=0;
            x_done_r<=0;
            b_issue_r<=0;
            b_done_r<=0;
            w_slot_r<=0;
            x_slot_r<=0;
            b_slot_r<=0;
        end else if (active_r) begin
            w_slot_r<=w_slot_w;
            x_slot_r<=x_slot_w;
            b_slot_r<=b_slot_w;
            w_data_r<=weight_mem_rd_en_o; //w_data_r là chân enable nhưng mà delay 1 chu kì
            x_data_r<=input_rd_en_o;
            b_data_r<=bias_mem_rd_en_o;
            if (w_slot_w) begin
                w_tag_r<=w_issue_r;
                w_issue_r<=w_issue_r+1'b1;
                if (w_tap_r==24) begin
                    w_tap_r<=0;
                w_bank_r<=w_bank_r+1'b1;
                end
                else w_tap_r<=w_tap_r+1'b1;
            end
            if (x_slot_w) begin
                x_tag_r<=x_issue_r; // ram mode write first
				x_issue_r<=x_issue_r+1'b1;
            end
            if (b_slot_w) begin
                b_tag_r<=b_issue_r;
				b_issue_r<=b_issue_r+1'b1;
            end
            if (w_slot_r && (!w_data_r || weight_mem_rd_valid_i)) begin // phai co !w_data_r de tao nhung weight full 0 tu do moi thuc hien dung chuc nang cua mach
                weights_o[w_tag_r*DATA_WIDTH +: DATA_WIDTH]<=w_data_r ? weight_mem_rd_data_i : {DATA_WIDTH{1'b0}};
                w_done_r<=w_done_r+1'b1;
            end
            if (x_slot_r && (!x_data_r || input_rd_valid_i)) begin
                inputs_o[x_tag_r*DATA_WIDTH +: DATA_WIDTH]<=x_data_r ? input_rd_data_i : {DATA_WIDTH{1'b0}};
                x_done_r<=x_done_r+1'b1;
            end
            if (b_slot_r && (!b_data_r || bias_mem_rd_valid_i)) begin
                if (bias_enable_i)
                    biases_o[b_tag_r*DATA_WIDTH +: DATA_WIDTH]<=b_data_r ? bias_mem_rd_data_i : {DATA_WIDTH{1'b0}};
                b_done_r<=b_done_r+1'b1;
            end
            if (w_done_r==100 && x_done_r==25 && b_done_r==4) begin
                active_r<=0;
                done_o<=1;
                w_slot_r<=0;
                x_slot_r<=0;
                b_slot_r<=0;
            end
        end
    end
endmodule
