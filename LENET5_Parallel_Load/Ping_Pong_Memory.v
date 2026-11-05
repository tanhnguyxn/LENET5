`timescale 1ns/1ps
// Activation buffers A and B. Read and compute-write use opposite banks.
// Host image loading is permitted only while the engine is idle.
module Ping_Pong_Memory #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 3456
) (
    input wire clk_i,
    input wire rst_n_i,
    input wire host_we_i,
    input wire [9:0] host_addr_i,
    input wire [DATA_WIDTH-1:0] host_data_i,
    input wire rd_en_i,
    input wire rd_bank_i,
    input wire [15:0] rd_addr_i,
    output wire [DATA_WIDTH-1:0] rd_data_o,
    output reg rd_valid_o,
    input wire wr_en_i,
    input wire wr_bank_i,
    input wire [15:0] wr_addr_i,
    input wire [DATA_WIDTH-1:0] wr_data_i
);
    //-------------------------------------//
    // Register and Wire Declarations
    //-------------------------------------//
    reg read_bank_r;
    wire [DATA_WIDTH-1:0] a_data_w, b_data_w;
    wire a_we_w;
    wire [15:0] a_addr_w;
    wire [DATA_WIDTH-1:0] a_data_in_w;
    assign a_we_w = rst_n_i && ((wr_en_i && !wr_bank_i) || host_we_i);
    assign a_addr_w = host_we_i ? {6'd0,host_addr_i} : wr_addr_i;
    assign a_data_in_w = host_we_i ? host_data_i : wr_data_i;
    assign rd_data_o = read_bank_r ? b_data_w : a_data_w;

    //-------------------------------------//
    // Explicit Ping and Pong Banks
    //-------------------------------------//
    Sync_RAM_1R1W #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) u_ping (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i && !rd_bank_i),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(a_data_w),
        .wr_en_i(a_we_w),
        .wr_addr_i(a_addr_w),
        .wr_data_i(a_data_in_w)
    );
    Sync_RAM_1R1W #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) u_pong (
        .clk_i(clk_i),
        .rd_en_i(rst_n_i && rd_en_i && rd_bank_i),
        .rd_addr_i(rd_addr_i),
        .rd_data_o(b_data_w),
        .wr_en_i(rst_n_i && wr_en_i && wr_bank_i),
        .wr_addr_i(wr_addr_i),
        .wr_data_i(wr_data_i)
    );

    //-------------------------------------//
    // Read Response Alignment
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            rd_valid_o <= 0;
            read_bank_r <= 0;
        end else begin
            rd_valid_o <= rd_en_i;
            if (rd_en_i) read_bank_r <= rd_bank_i;
        end
    end
endmodule
