`timescale 1ns/1ps
// One synchronous read port and one synchronous write port.
// No array reset. Same-address read/write returns the previous value in RTL.
// Hardware RAM mapping must be checked in the target synthesis report.
module Sync_RAM_1R1W #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16,
    parameter DEPTH = 1024
) (
    input wire clk_i,
    input wire rd_en_i,
    input wire [ADDR_WIDTH-1:0] rd_addr_i,
    output reg [DATA_WIDTH-1:0] rd_data_o,
    input wire wr_en_i,
    input wire [ADDR_WIDTH-1:0] wr_addr_i,
    input wire [DATA_WIDTH-1:0] wr_data_i
);
    //-------------------------------------//
    // Memory Array
    //-------------------------------------//
    reg [DATA_WIDTH-1:0] mem_r [0:DEPTH-1];

    //-------------------------------------//
    // Synchronous Memory Ports
    //-------------------------------------//
    always @(posedge clk_i) begin
        if (wr_en_i && wr_addr_i < DEPTH)
            mem_r[wr_addr_i] <= wr_data_i;
        if (rd_en_i) begin
            if (rd_addr_i < DEPTH)
                rd_data_o <= mem_r[rd_addr_i];
            else
                rd_data_o <= 0;
        end
    end
endmodule
