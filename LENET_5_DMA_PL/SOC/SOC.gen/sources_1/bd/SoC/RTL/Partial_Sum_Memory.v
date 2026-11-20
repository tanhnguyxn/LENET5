`timescale 1ns/1ps
module Partial_Sum_Memory #(
    parameter ACC_WIDTH=48,
    parameter DEPTH=576
) (
    input wire clk_i,
    input wire rst_n_i,
    input wire rd_en_i,
    input wire [15:0] rd_addr_i,
    output wire [4*ACC_WIDTH-1:0] rd_data_o,
    input wire wr_en_i,
    input wire [15:0] wr_addr_i,
    input wire [4*ACC_WIDTH-1:0] wr_data_i
);

    //-------------------------------------//
    // Four Independent Partial Sum Banks
    //-------------------------------------//
    Sync_RAM_1R1W #(
        .DATA_WIDTH(ACC_WIDTH),
        .DEPTH(DEPTH)
    ) u_bank_0 (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(rd_data_o[0*ACC_WIDTH +: ACC_WIDTH]),
        .wr_en_i(rst_n_i && wr_en_i),
        .wr_addr_i(wr_addr_i),
        .wr_data_i(wr_data_i[0*ACC_WIDTH +: ACC_WIDTH])
    );
    Sync_RAM_1R1W #(
        .DATA_WIDTH(ACC_WIDTH),
        .DEPTH(DEPTH)
    ) u_bank_1 (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(rd_data_o[1*ACC_WIDTH +: ACC_WIDTH]),
        .wr_en_i(rst_n_i && wr_en_i),
        .wr_addr_i(wr_addr_i),
        .wr_data_i(wr_data_i[1*ACC_WIDTH +: ACC_WIDTH])
    );
    Sync_RAM_1R1W #(
        .DATA_WIDTH(ACC_WIDTH),
        .DEPTH(DEPTH)
    ) u_bank_2 (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(rd_data_o[2*ACC_WIDTH +: ACC_WIDTH]),
        .wr_en_i(rst_n_i && wr_en_i),
        .wr_addr_i(wr_addr_i),
        .wr_data_i(wr_data_i[2*ACC_WIDTH +: ACC_WIDTH])
    );
    Sync_RAM_1R1W #(
        .DATA_WIDTH(ACC_WIDTH),
        .DEPTH(DEPTH)
    ) u_bank_3 (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(rd_data_o[3*ACC_WIDTH +: ACC_WIDTH]),
        .wr_en_i(rst_n_i && wr_en_i),
        .wr_addr_i(wr_addr_i),
        .wr_data_i(wr_data_i[3*ACC_WIDTH +: ACC_WIDTH])
    );
endmodule
