`timescale 1ns/1ps
// Four synchronous reads followed by one signed 2x2 maximum and one write.

module Pool_Controller #(
    parameter DATA_WIDTH = 16
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire                                       start_i,
    input wire [5:0]                                 width_i,
    input wire [5:0]                                 height_i,
    input wire [15:0]                                channels_i,
    output reg                                       busy_o,
    output reg                                       done_o,
    output wire                                      rd_en_o,
    output wire [15:0]                               rd_addr_o,
    input wire signed [DATA_WIDTH-1:0]               rd_data_i,
    input wire                                       rd_valid_i,
    output wire                                      wr_en_o,
    output wire [15:0]                               wr_addr_o,
    output wire signed [DATA_WIDTH-1:0]              wr_data_o
);

    //-------------------------------------//
    //     Local Parameter Declarations    //
    //-------------------------------------//
    localparam [2:0] IDLE = 0, REQ = 1, WAIT = 2, WRITE = 3, FINISH = 4;

    //-------------------------------------//
    //        Register Declarations        //
    //-------------------------------------//
    reg [2:0] state_r;
    reg [1:0] tap_r;
    reg [5:0] width_r, height_r, row_r, col_r;
    reg [15:0] channels_r, ch_r;
    reg [4*DATA_WIDTH-1:0] pixels_r;

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire [5:0] out_width_w, out_height_w;

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    assign out_width_w = width_r>>1;
    assign out_height_w = height_r>>1;
    assign rd_en_o = (state_r == REQ);
    assign rd_addr_o = ch_r*width_r*height_r+(row_r*2+tap_r[1])*width_r+col_r*2+tap_r[0];
    assign wr_en_o = (state_r == WRITE);
    assign wr_addr_o = ch_r*out_width_w*out_height_w+row_r*out_width_w+col_r;

    //-------------------------------------//
    //       MaxPool2x2 Q16 Instance       //
    //-------------------------------------//
    MaxPool2x2_Q16 #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pool (
        .data00_i               (pixels_r[0*DATA_WIDTH +: DATA_WIDTH]),
        .data01_i               (pixels_r[1*DATA_WIDTH +: DATA_WIDTH]),
        .data10_i               (pixels_r[2*DATA_WIDTH +: DATA_WIDTH]),
        .data11_i               (pixels_r[3*DATA_WIDTH +: DATA_WIDTH]),
        .data_o                 (wr_data_o)
    );

    //-------------------------------------//
    //           Main Control FSM          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_r <= IDLE;
            tap_r <= 0;
            width_r <= 0;
            height_r <= 0;
            row_r <= 0;
            col_r <= 0;
            channels_r <= 0;
            ch_r <= 0;
            pixels_r <= 0;
            busy_o <= 0;
            done_o <= 0;
        end
        else begin
            done_o <= 0;
            case (state_r)
                // Wait for a new layer request and latch its dimensions.
                IDLE: if (start_i) begin
                    width_r <= width_i;
                    height_r <= height_i;
                    channels_r <= channels_i;
                    row_r <= 0;
                    col_r <= 0;
                    ch_r <= 0;
                    tap_r <= 0;
                    busy_o <= 1;
                    state_r <= REQ;
                end
                // Request one pixel of the current 2x2 window.
                REQ: state_r <= WAIT;
                // Capture the returned pixel; repeat until all four are available.
                WAIT: if (rd_valid_i) begin
                    pixels_r[tap_r*DATA_WIDTH +: DATA_WIDTH] <= rd_data_i;
                    if (tap_r == 3) begin
                        tap_r <= 0;
                        state_r <= WRITE;
                    end
                    else begin
                        tap_r <= tap_r+1'b1;
                        state_r <= REQ;
                    end
                end
                // Write the signed maximum of the four pixels; advance the output position.
                WRITE: begin
                    state_r <= REQ;
                    if (col_r == out_width_w-1'b1) begin
                        col_r <= 0;
                        if (row_r == out_height_w-1'b1) begin
                            row_r <= 0;
                            if (ch_r == channels_r-1'b1) state_r <= FINISH;
                            else ch_r <= ch_r+1'b1;
                        end
                        else row_r <= row_r+1'b1;
                    end
                    else col_r <= col_r+1'b1;
                end
                // Pulse completion and release the layer controller.
                FINISH: begin
                    busy_o <= 0;
                    done_o <= 1;
                    state_r <= IDLE;
                end
                default: begin
                    busy_o <= 0;
                    state_r <= IDLE;
                end
            endcase
        end
    end
endmodule
