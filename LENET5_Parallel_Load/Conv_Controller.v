`timescale 1ns/1ps
// Four output-channel groups; one raster scan per input channel.
// Line buffer and weight-stationary PEA form the actual convolution datapath.

module Conv_Controller #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH = 48,
    parameter MAX_PIXELS = 576
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire                                       start_i,
    input wire [5:0]                                 width_i,
    input wire [5:0]                                 height_i,
    input wire [15:0]                                cin_i,
    input wire [15:0]                                cout_i,
    output reg                                       busy_o,
    output reg                                       done_o,
    output reg                                       rd_en_o,
    output wire weight_mem_rd_en_o,
    output wire [15:0] weight_mem_rd_addr_o,
    input wire [DATA_WIDTH-1:0] weight_mem_rd_data_i,
    input wire weight_mem_rd_valid_i,
    output wire bias_rd_en_o,
    output wire [15:0] bias_rd_addr_o,
    input wire [DATA_WIDTH-1:0] bias_rd_data_i,
    input wire bias_rd_valid_i,
    output reg [15:0]                                rd_addr_o,
    input wire signed [DATA_WIDTH-1:0]               rd_data_i,
    input wire                                       rd_valid_i,
    output wire                                      wr_en_o,
    output wire [15:0]                               wr_addr_o,
    output wire signed [DATA_WIDTH-1:0]              wr_data_o,
    output wire                                      pea_weight_load_o,
    output wire [100*DATA_WIDTH-1:0]                 pea_weight_o,
    output wire [25*DATA_WIDTH-1:0]                  pea_window_o,
    output wire                                      pea_valid_o,
    input wire [4*ACC_WIDTH-1:0]                     pea_psum_i,
    input wire                                       pea_valid_i
);
    //-------------------------------------//
    // State and Register Declarations
    //-------------------------------------//
    localparam [3:0] IDLE=0, LOAD_DATA=1, PREPARE=2, STREAM=3, DRAIN=4, OUT_REQ=5, OUT_WAIT=6, WRITE=7;
    reg [3:0] state_r;
    reg [1:0] bank_r;
    reg [5:0] width_r, height_r;
    reg [15:0] cin_r, cout_r, group_r, ic_r;
    reg [15:0] request_r, result_r, committed_r, spatial_r;
    wire [100*DATA_WIDTH-1:0] weights_w;
    wire [4*DATA_WIDTH-1:0] biases_w;
    reg accumulate_valid_r;
    reg [15:0] accumulate_addr_r;
    reg [4*ACC_WIDTH-1:0] dot_r;

    //-------------------------------------//
    // Wire Declarations
    //-------------------------------------//
    wire [15:0] input_pixels_w, output_pixels_w;
    wire scanning_w, window_valid_w, result_valid_w;
    wire [4*ACC_WIDTH-1:0] previous_w, updated_w;
    wire signed [ACC_WIDTH-1:0] selected_sum_w;
    wire signed [DATA_WIDTH-1:0] selected_bias_w;
    assign input_pixels_w = width_r * height_r;
    assign output_pixels_w = (width_r-6'd4) * (height_r-6'd4);
    assign scanning_w = state_r==STREAM || state_r==DRAIN;
    assign pea_weight_o = weights_w;
    assign pea_weight_load_o = state_r==PREPARE;
    assign pea_valid_o = scanning_w && window_valid_w;
    assign result_valid_w = scanning_w && pea_valid_i;
    assign wr_en_o = state_r==WRITE && group_r+bank_r<cout_r;
    assign wr_addr_o = (group_r+bank_r)*output_pixels_w + spatial_r;
    assign selected_sum_w = previous_w[bank_r*ACC_WIDTH +: ACC_WIDTH];
    assign selected_bias_w = biases_w[bank_r*DATA_WIDTH +: DATA_WIDTH];

    //-------------------------------------//
    // Streaming Window and Output Datapath
    //-------------------------------------//
    Line_Buffer_5x5 #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_WIDTH(28)
    ) u_line_buffer (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .clear_i(state_r==PREPARE),
        .width_i(width_r),
        .pixel_i(rd_data_i),
        .valid_i(scanning_w && rd_valid_i),
        .window_o(pea_window_o),
        .valid_o(window_valid_w)
    );
    Postprocess_Q16 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_post (
        .psum_i(selected_sum_w),
        .bias_i(selected_bias_w),
        .relu_enable_i(1'b1),
        .data_o(wr_data_o)
    );

    //-------------------------------------//
    // Independent Pipelined Result Sink
    //-------------------------------------//
    // Results are ordered. result_r is the spatial address of each returning dot.
    // At edge N: read the old sum and latch the dot/address.
    // At edge N+1: write the updated sum while reading the next address.
    // Each address is touched once per scan; DRAIN separates input channels.
    Partial_Sum_Memory #(
        .ACC_WIDTH(ACC_WIDTH),
        .DEPTH(MAX_PIXELS)
    ) u_partial_sum_memory (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .rd_en_i(result_valid_w || state_r==OUT_REQ),
        .rd_addr_i(state_r==OUT_REQ ? spatial_r : result_r),
        .rd_data_o(previous_w),
        .wr_en_i(accumulate_valid_r),
        .wr_addr_i(accumulate_addr_r),
        .wr_data_i(updated_w)
    );
    assign updated_w[0*ACC_WIDTH +: ACC_WIDTH] =
        (ic_r==0 ? {ACC_WIDTH{1'b0}} : previous_w[0*ACC_WIDTH +: ACC_WIDTH])
        + dot_r[0*ACC_WIDTH +: ACC_WIDTH];
    assign updated_w[1*ACC_WIDTH +: ACC_WIDTH] =
        (ic_r==0 ? {ACC_WIDTH{1'b0}} : previous_w[1*ACC_WIDTH +: ACC_WIDTH])
        + dot_r[1*ACC_WIDTH +: ACC_WIDTH];
    assign updated_w[2*ACC_WIDTH +: ACC_WIDTH] =
        (ic_r==0 ? {ACC_WIDTH{1'b0}} : previous_w[2*ACC_WIDTH +: ACC_WIDTH])
        + dot_r[2*ACC_WIDTH +: ACC_WIDTH];
    assign updated_w[3*ACC_WIDTH +: ACC_WIDTH] =
        (ic_r==0 ? {ACC_WIDTH{1'b0}} : previous_w[3*ACC_WIDTH +: ACC_WIDTH])
        + dot_r[3*ACC_WIDTH +: ACC_WIDTH];

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            result_r <= 0;
            committed_r <= 0;
            accumulate_valid_r <= 0;
            accumulate_addr_r <= 0;
            dot_r <= 0;
        end else if (state_r==PREPARE) begin
            result_r <= 0;
            committed_r <= 0;
            accumulate_valid_r <= 0;
        end else begin
            accumulate_valid_r <= result_valid_w;
            if (result_valid_w) begin
                dot_r <= pea_psum_i;
                accumulate_addr_r <= result_r;
                result_r <= result_r + 1'b1;
            end
            if (accumulate_valid_r)
                committed_r <= committed_r + 1'b1;
        end
    end

    //-------------------------------------//
    // Memory Request Decoder
    //-------------------------------------//
    // The activation memory accepts one request every cycle, with fixed
    // one-cycle response latency. No ready/backpressure input is required.
    always @(*) begin
        rd_en_o = state_r==STREAM;
        rd_addr_o = ic_r*input_pixels_w+request_r;
    end
    //-------------------------------------//
    //           Main Control FSM          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_r <= IDLE;

            bank_r <= 0;
            width_r <= 0;
            height_r <= 0;
            cin_r <= 0;
            cout_r <= 0;
            group_r <= 0;
            ic_r <= 0;
            request_r <= 0;
            spatial_r <= 0;

            busy_o <= 0;
            done_o <= 0;
        end else begin
            done_o <= 0;
            case (state_r)
                IDLE: if (start_i) begin
                    width_r <= width_i;
                    height_r <= height_i;
                    cin_r <= cin_i;
                    cout_r <= cout_i;
                    group_r <= 0;
                    ic_r <= 0;
                    bank_r <= 0;

                    busy_o <= 1;
                    state_r <= LOAD_DATA;
                end
                LOAD_DATA: if (loader_started_r && loader_done_w)
                    state_r <= PREPARE;
                PREPARE: begin
                    request_r<=0;
                    state_r<=STREAM;
                end
                STREAM: begin
                    if (request_r==input_pixels_w-1'b1)
                        state_r <= DRAIN;
                    else
                        request_r <= request_r + 1'b1;
                end
                // Keep weights/channel stable until every sum is committed.
                DRAIN: if (committed_r==output_pixels_w) begin
                    bank_r <= 0;

                    if (ic_r==cin_r-1'b1) begin
                        spatial_r <= 0;
                        state_r <= OUT_REQ;
                    end else begin
                        ic_r <= ic_r + 1'b1;
                        state_r <= LOAD_DATA;
                    end
                end
                // Serialize completed outputs through the one-word RAM port.
                OUT_REQ: state_r <= OUT_WAIT;
                OUT_WAIT: state_r <= WRITE;
                WRITE: begin
                    if (bank_r==3) begin
                        bank_r <= 0;
                        if (spatial_r==output_pixels_w-1'b1) begin
                            ic_r <= 0;
                            if (group_r+16'd4>=cout_r)
                                begin
                                    busy_o<=0;
                                done_o<=1;
                                state_r<=IDLE;
                                end
                            else begin
                                group_r <= group_r+16'd4;
                                state_r <= LOAD_DATA;
                            end
                        end else begin
                            spatial_r <= spatial_r+1'b1;
                            state_r <= OUT_REQ;
                        end
                    end 
					else
                        bank_r <= bank_r+1'b1;
                end
                default: begin
                    busy_o <= 0;
                    state_r <= IDLE;
                end
            endcase
        end
    end
    //-------------------------------------//
    //     Parallel Data Loader Instance   //
    //-------------------------------------//
    reg loader_started_r;
    wire loader_done_w;
    wire [25*DATA_WIDTH-1:0] unused_inputs_w;
    Parallel_Data_Loader #(.DATA_WIDTH(DATA_WIDTH)) u_loader (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .start_i(state_r==LOAD_DATA && !loader_started_r),
        .input_enable_i(1'b0),
        .bias_enable_i(ic_r==0),
        .group_i(group_r),
        .outputs_i(cout_r),
        .weight_mem_base_i((group_r*cin_r+ic_r)*16'd25),
        .weight_mem_stride_i(cin_r*16'd25),
        .input_base_i(16'd0),
        .taps_i(5'd25),
        .input_rd_en_o(),
        .input_rd_addr_o(),
        .input_rd_data_i({DATA_WIDTH{1'b0}}),
        .input_rd_valid_i(1'b0),
        .inputs_o(unused_inputs_w),
        .weight_mem_rd_en_o(weight_mem_rd_en_o),
        .weight_mem_rd_addr_o(weight_mem_rd_addr_o),
        .weight_mem_rd_data_i(weight_mem_rd_data_i),
        .weight_mem_rd_valid_i(weight_mem_rd_valid_i),
        .bias_rd_en_o(bias_rd_en_o),
        .bias_rd_addr_o(bias_rd_addr_o),
        .bias_rd_data_i(bias_rd_data_i),
        .bias_rd_valid_i(bias_rd_valid_i),
        .weights_o(weights_w),
        .biases_o(biases_w),
        .done_o(loader_done_w)
    );
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) loader_started_r<=0;
        else if (state_r!=LOAD_DATA) loader_started_r<=0;
        else loader_started_r<=1;
    end

endmodule
