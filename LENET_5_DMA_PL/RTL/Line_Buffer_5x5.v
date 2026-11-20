`timescale 1ns/1ps
// Raster input with stalls. Width is stable until clear_i; no padded pixels.
// clear_i starts each input-channel scan and suppresses old-frame windows.

module Line_Buffer_5x5 #(
    parameter DATA_WIDTH = 16,
    parameter MAX_WIDTH = 28
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire                                       clear_i,
    input wire [5:0]                                 width_i,
    input wire signed [DATA_WIDTH-1:0]               pixel_i,
    input wire                                       valid_i,
    output wire [25*DATA_WIDTH-1:0]                  window_o,
    output reg                                       valid_o
);

    //-------------------------------------//
    //        Register Declarations        //
    //-------------------------------------//
    reg [5:0] row_r, col_r;
    reg [5*DATA_WIDTH-1:0] shift_0_r;
    reg [5*DATA_WIDTH-1:0] shift_1_r;
    reg [5*DATA_WIDTH-1:0] shift_2_r;
    reg [5*DATA_WIDTH-1:0] shift_3_r;
    reg [5*DATA_WIDTH-1:0] shift_4_r;

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire [5*DATA_WIDTH-1:0] column_w;

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    //-------------------------------------//
    //           Sequential Logic          //
    //-------------------------------------//
    Line_Buffer_Memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    ) u_line_memory (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .enable_i(!clear_i && valid_i),
        .column_i(col_r),
        .pixel_i(pixel_i),
        .column_o(column_w)
    );

    //-------------------------------------//
    //           Sequential Logic          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            row_r <= 0;
            col_r <= 0;
            valid_o <= 0;
        end
        else if (clear_i) begin
            row_r <= 0;
            col_r <= 0;
            valid_o <= 0;
        end
        else begin
            valid_o <= 0;
            if (valid_i) begin
                valid_o <= (row_r >= 4 && col_r >= 4);
                if (col_r == width_i-1'b1) begin
                    col_r <= 0;
                    row_r <= row_r+1'b1;
                end
                else col_r <= col_r+1'b1;
            end
        end
    end

    //-------------------------------------//
    //             Window Row 0            //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) shift_0_r <= 0;
        else if (clear_i) shift_0_r <= 0;
        else if (valid_i)
            shift_0_r <= {column_w[0*DATA_WIDTH +: DATA_WIDTH], shift_0_r[5*DATA_WIDTH-1:DATA_WIDTH]};
    end
    assign window_o[0*5*DATA_WIDTH +: 5*DATA_WIDTH] = shift_0_r;

    //-------------------------------------//
    //             Window Row 1            //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) shift_1_r <= 0;
        else if (clear_i) shift_1_r <= 0;
        else if (valid_i)
            shift_1_r <= {column_w[1*DATA_WIDTH +: DATA_WIDTH], shift_1_r[5*DATA_WIDTH-1:DATA_WIDTH]};
    end
    assign window_o[1*5*DATA_WIDTH +: 5*DATA_WIDTH] = shift_1_r;

    //-------------------------------------//
    //             Window Row 2            //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) shift_2_r <= 0;
        else if (clear_i) shift_2_r <= 0;
        else if (valid_i)
            shift_2_r <= {column_w[2*DATA_WIDTH +: DATA_WIDTH], shift_2_r[5*DATA_WIDTH-1:DATA_WIDTH]};
    end
    assign window_o[2*5*DATA_WIDTH +: 5*DATA_WIDTH] = shift_2_r;

    //-------------------------------------//
    //             Window Row 3            //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) shift_3_r <= 0;
        else if (clear_i) shift_3_r <= 0;
        else if (valid_i)
            shift_3_r <= {column_w[3*DATA_WIDTH +: DATA_WIDTH], shift_3_r[5*DATA_WIDTH-1:DATA_WIDTH]};
    end
    assign window_o[3*5*DATA_WIDTH +: 5*DATA_WIDTH] = shift_3_r;

    //-------------------------------------//
    //             Window Row 4            //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) shift_4_r <= 0;
        else if (clear_i) shift_4_r <= 0;
        else if (valid_i)
            shift_4_r <= {column_w[4*DATA_WIDTH +: DATA_WIDTH], shift_4_r[5*DATA_WIDTH-1:DATA_WIDTH]};
    end
    assign window_o[4*5*DATA_WIDTH +: 5*DATA_WIDTH] = shift_4_r;
endmodule
