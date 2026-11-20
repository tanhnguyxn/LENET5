`timescale 1ns/1ps
// Eight Q8.8 lanes. Host address is a local row index.
// Compute read latency is exactly one clock. No reset of RAM contents.
module Banked_RAM_128_16 #(parameter DEPTH=1024) (
    input wire clk_i,
    input wire host_we_i,
    input wire [12:0] host_row_i,
    input wire [127:0] host_data_i,
    input wire [15:0] host_strb_i,
    input wire wr_en_i,
    input wire [15:0] wr_addr_i,
    input wire [15:0] wr_data_i,
    input wire rd_en_i,
    input wire [15:0] rd_addr_i,
    output reg [15:0] rd_data_o
);
    //-------------------------------------//
    //          Memory Declarations        //
    //-------------------------------------//
    localparam ROWS=(DEPTH+7)/8;
    localparam RAM_STYLE=(DEPTH<512) ? "distributed" : "block";
    reg [2:0] lane_r;
    reg read_ok_r;
    (* ram_style = RAM_STYLE *) reg [15:0] mem_0_r [0:ROWS-1];
    reg [15:0] data_0_r;
    wire host_0_w = host_we_i && (host_row_i < ((DEPTH + 7) / 8));
    wire compute_0_w = wr_en_i && wr_addr_i<DEPTH && wr_addr_i[2:0]==3'd0;
    wire [12:0] addr_0_w = host_we_i ? host_row_i : wr_addr_i[15:3];
    wire [15:0] data_0_w = host_we_i ? host_data_i[0 +: 16] : wr_data_i;
    wire [1:0] be_0_w = host_we_i ? (host_0_w ? host_strb_i[0 +: 2] : 2'b00) : {2{compute_0_w}};
    always @(posedge clk_i) begin
        if (be_0_w[0]) mem_0_r[addr_0_w][7:0] <= data_0_w[7:0];
        if (be_0_w[1]) mem_0_r[addr_0_w][15:8] <= data_0_w[15:8];
        if (rd_en_i && rd_addr_i<DEPTH && rd_addr_i[2:0]==3'd0)
            data_0_r <= mem_0_r[rd_addr_i[15:3]];
    end
    (* ram_style = RAM_STYLE *) reg [15:0] mem_1_r [0:ROWS-1];
    reg [15:0] data_1_r;
    wire host_1_w = host_we_i && (host_row_i < ((DEPTH + 6) / 8));
    wire compute_1_w = wr_en_i && wr_addr_i<DEPTH && wr_addr_i[2:0]==3'd1;
    wire [12:0] addr_1_w = host_we_i ? host_row_i : wr_addr_i[15:3];
    wire [15:0] data_1_w = host_we_i ? host_data_i[16 +: 16] : wr_data_i;
    wire [1:0] be_1_w = host_we_i ? (host_1_w ? host_strb_i[2 +: 2] : 2'b00) : {2{compute_1_w}};
    always @(posedge clk_i) begin
        if (be_1_w[0]) mem_1_r[addr_1_w][7:0] <= data_1_w[7:0];
        if (be_1_w[1]) mem_1_r[addr_1_w][15:8] <= data_1_w[15:8];
        if (rd_en_i && rd_addr_i<DEPTH && rd_addr_i[2:0]==3'd1)
            data_1_r <= mem_1_r[rd_addr_i[15:3]];
    end
    (* ram_style = RAM_STYLE *) reg [15:0] mem_2_r [0:ROWS-1];
    reg [15:0] data_2_r;
    wire host_2_w = host_we_i && (host_row_i < ((DEPTH + 5) / 8));
    wire compute_2_w = wr_en_i && wr_addr_i<DEPTH && wr_addr_i[2:0]==3'd2;
    wire [12:0] addr_2_w = host_we_i ? host_row_i : wr_addr_i[15:3];
    wire [15:0] data_2_w = host_we_i ? host_data_i[32 +: 16] : wr_data_i;
    wire [1:0] be_2_w = host_we_i ? (host_2_w ? host_strb_i[4 +: 2] : 2'b00) : {2{compute_2_w}};
    always @(posedge clk_i) begin
        if (be_2_w[0]) mem_2_r[addr_2_w][7:0] <= data_2_w[7:0];
        if (be_2_w[1]) mem_2_r[addr_2_w][15:8] <= data_2_w[15:8];
        if (rd_en_i && rd_addr_i<DEPTH && rd_addr_i[2:0]==3'd2)
            data_2_r <= mem_2_r[rd_addr_i[15:3]];
    end
    (* ram_style = RAM_STYLE *) reg [15:0] mem_3_r [0:ROWS-1];
    reg [15:0] data_3_r;
    wire host_3_w = host_we_i && (host_row_i < ((DEPTH + 4) / 8));
    wire compute_3_w = wr_en_i && wr_addr_i<DEPTH && wr_addr_i[2:0]==3'd3;
    wire [12:0] addr_3_w = host_we_i ? host_row_i : wr_addr_i[15:3];
    wire [15:0] data_3_w = host_we_i ? host_data_i[48 +: 16] : wr_data_i;
    wire [1:0] be_3_w = host_we_i ? (host_3_w ? host_strb_i[6 +: 2] : 2'b00) : {2{compute_3_w}};
    always @(posedge clk_i) begin
        if (be_3_w[0]) mem_3_r[addr_3_w][7:0] <= data_3_w[7:0];
        if (be_3_w[1]) mem_3_r[addr_3_w][15:8] <= data_3_w[15:8];
        if (rd_en_i && rd_addr_i<DEPTH && rd_addr_i[2:0]==3'd3)
            data_3_r <= mem_3_r[rd_addr_i[15:3]];
    end
    (* ram_style = RAM_STYLE *) reg [15:0] mem_4_r [0:ROWS-1];
    reg [15:0] data_4_r;
    wire host_4_w = host_we_i && (host_row_i < ((DEPTH + 3) / 8));
    wire compute_4_w = wr_en_i && wr_addr_i<DEPTH && wr_addr_i[2:0]==3'd4;
    wire [12:0] addr_4_w = host_we_i ? host_row_i : wr_addr_i[15:3];
    wire [15:0] data_4_w = host_we_i ? host_data_i[64 +: 16] : wr_data_i;
    wire [1:0] be_4_w = host_we_i ? (host_4_w ? host_strb_i[8 +: 2] : 2'b00) : {2{compute_4_w}};
    always @(posedge clk_i) begin
        if (be_4_w[0]) mem_4_r[addr_4_w][7:0] <= data_4_w[7:0];
        if (be_4_w[1]) mem_4_r[addr_4_w][15:8] <= data_4_w[15:8];
        if (rd_en_i && rd_addr_i<DEPTH && rd_addr_i[2:0]==3'd4)
            data_4_r <= mem_4_r[rd_addr_i[15:3]];
    end
    (* ram_style = RAM_STYLE *) reg [15:0] mem_5_r [0:ROWS-1];
    reg [15:0] data_5_r;
    wire host_5_w = host_we_i && (host_row_i < ((DEPTH + 2) / 8));
    wire compute_5_w = wr_en_i && wr_addr_i<DEPTH && wr_addr_i[2:0]==3'd5;
    wire [12:0] addr_5_w = host_we_i ? host_row_i : wr_addr_i[15:3];
    wire [15:0] data_5_w = host_we_i ? host_data_i[80 +: 16] : wr_data_i;
    wire [1:0] be_5_w = host_we_i ? (host_5_w ? host_strb_i[10 +: 2] : 2'b00) : {2{compute_5_w}};
    always @(posedge clk_i) begin
        if (be_5_w[0]) mem_5_r[addr_5_w][7:0] <= data_5_w[7:0];
        if (be_5_w[1]) mem_5_r[addr_5_w][15:8] <= data_5_w[15:8];
        if (rd_en_i && rd_addr_i<DEPTH && rd_addr_i[2:0]==3'd5)
            data_5_r <= mem_5_r[rd_addr_i[15:3]];
    end
    (* ram_style = RAM_STYLE *) reg [15:0] mem_6_r [0:ROWS-1];
    reg [15:0] data_6_r;
    wire host_6_w = host_we_i && (host_row_i < ((DEPTH + 1) / 8));
    wire compute_6_w = wr_en_i && wr_addr_i<DEPTH && wr_addr_i[2:0]==3'd6;
    wire [12:0] addr_6_w = host_we_i ? host_row_i : wr_addr_i[15:3];
    wire [15:0] data_6_w = host_we_i ? host_data_i[96 +: 16] : wr_data_i;
    wire [1:0] be_6_w = host_we_i ? (host_6_w ? host_strb_i[12 +: 2] : 2'b00) : {2{compute_6_w}};
    always @(posedge clk_i) begin
        if (be_6_w[0]) mem_6_r[addr_6_w][7:0] <= data_6_w[7:0];
        if (be_6_w[1]) mem_6_r[addr_6_w][15:8] <= data_6_w[15:8];
        if (rd_en_i && rd_addr_i<DEPTH && rd_addr_i[2:0]==3'd6)
            data_6_r <= mem_6_r[rd_addr_i[15:3]];
    end
    (* ram_style = RAM_STYLE *) reg [15:0] mem_7_r [0:ROWS-1];
    reg [15:0] data_7_r;
    wire host_7_w = host_we_i && (host_row_i < ((DEPTH + 0) / 8));
    wire compute_7_w = wr_en_i && wr_addr_i<DEPTH && wr_addr_i[2:0]==3'd7;
    wire [12:0] addr_7_w = host_we_i ? host_row_i : wr_addr_i[15:3];
    wire [15:0] data_7_w = host_we_i ? host_data_i[112 +: 16] : wr_data_i;
    wire [1:0] be_7_w = host_we_i ? (host_7_w ? host_strb_i[14 +: 2] : 2'b00) : {2{compute_7_w}};
    always @(posedge clk_i) begin
        if (be_7_w[0]) mem_7_r[addr_7_w][7:0] <= data_7_w[7:0];
        if (be_7_w[1]) mem_7_r[addr_7_w][15:8] <= data_7_w[15:8];
        if (rd_en_i && rd_addr_i<DEPTH && rd_addr_i[2:0]==3'd7)
            data_7_r <= mem_7_r[rd_addr_i[15:3]];
    end
    always @(posedge clk_i) begin
        if (rd_en_i) begin
            lane_r <= rd_addr_i[2:0];
            read_ok_r <= rd_addr_i<DEPTH;
        end
    end
    always @(*) begin
        rd_data_o=0;
        if (read_ok_r) begin
            case (lane_r)
                3'd0: rd_data_o=data_0_r;
                3'd1: rd_data_o=data_1_r;
                3'd2: rd_data_o=data_2_r;
                3'd3: rd_data_o=data_3_r;
                3'd4: rd_data_o=data_4_r;
                3'd5: rd_data_o=data_5_r;
                3'd6: rd_data_o=data_6_r;
                3'd7: rd_data_o=data_7_r;
                default: rd_data_o=0;
            endcase
        end
    end
endmodule
