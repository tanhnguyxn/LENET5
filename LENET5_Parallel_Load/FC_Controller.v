`timescale 1ns/1ps
// Four neurons in parallel, 25 inputs per chunk, using the SAME physical PEA.

module FC_Controller #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH = 48
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire                                       start_i,
    input wire [15:0]                                inputs_i,
    input wire [15:0]                                outputs_i,
    input wire                                       relu_enable_i,
    output reg                                       busy_o,
    output reg                                       done_o,
    output wire                                      rd_en_o,
    output wire weight_rd_en_o,
    output wire [15:0] weight_rd_addr_o,
    input wire [DATA_WIDTH-1:0] weight_rd_data_i,
    input wire weight_rd_valid_i,
    output wire bias_rd_en_o,
    output wire [15:0] bias_rd_addr_o,
    input wire [DATA_WIDTH-1:0] bias_rd_data_i,
    input wire bias_rd_valid_i,
    output wire [15:0]                               rd_addr_o,
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
    //     Local Parameter Declarations    //
    //-------------------------------------//
    localparam [2:0] IDLE=0, LOAD_DATA=1, LOAD=2, SEND=3, DOT_WAIT=4, WRITE=5;

    //-------------------------------------//
    //        Register Declarations        //
    //-------------------------------------//
    reg [2:0] state_r;
    reg [1:0] bank_r;
    reg [15:0] inputs_r, outputs_r, group_r, chunk_r;
    reg relu_enable_r;
    wire [100*DATA_WIDTH-1:0] weights_w;
    wire [25*DATA_WIDTH-1:0] inputs_vector_w;
    wire [4*DATA_WIDTH-1:0] biases_w;
    reg signed [ACC_WIDTH-1:0] total_0_r;
    reg signed [ACC_WIDTH-1:0] total_1_r;
    reg signed [ACC_WIDTH-1:0] total_2_r;
    reg signed [ACC_WIDTH-1:0] total_3_r;

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire [4*ACC_WIDTH-1:0] total_bus_w;
    wire signed [ACC_WIDTH-1:0] selected_sum_w;
    wire signed [DATA_WIDTH-1:0] selected_bias_w;
    wire signed [ACC_WIDTH-1:0] dot_0_w;
    wire signed [ACC_WIDTH-1:0] dot_1_w;
    wire signed [ACC_WIDTH-1:0] dot_2_w;
    wire signed [ACC_WIDTH-1:0] dot_3_w;

    //-------------------------------------//
    //      Datapath and Control Logic     //
    //-------------------------------------//
    assign pea_weight_o = weights_w;
    assign pea_weight_load_o = (state_r == LOAD);
    assign pea_window_o = inputs_vector_w;
    assign pea_valid_o = (state_r == SEND);
    assign wr_en_o = (state_r == WRITE && group_r+bank_r<outputs_r);
    assign wr_addr_o = group_r+bank_r;
    assign selected_sum_w = total_bus_w[bank_r*ACC_WIDTH +: ACC_WIDTH];
    assign selected_bias_w = biases_w[bank_r*DATA_WIDTH +: DATA_WIDTH];

    //-------------------------------------//
    //       Postprocess Q16 Instance      //
    //-------------------------------------//
    Postprocess_Q16 #(
        .DATA_WIDTH             (DATA_WIDTH),
        .ACC_WIDTH              (ACC_WIDTH)
    ) u_post (
        .psum_i                 (selected_sum_w),
        .bias_i                 (selected_bias_w),
        .relu_enable_i          (relu_enable_r),
        .data_o                 (wr_data_o)
    );

    //-------------------------------------//
    //                Bank 0               //
    //-------------------------------------//
    assign dot_0_w = pea_psum_i[0*ACC_WIDTH +: ACC_WIDTH];

    //-------------------------------------//
    //           Sequential Logic          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) total_0_r <= 0;
        else if (state_r == DOT_WAIT && pea_valid_i) begin
            if (chunk_r == 0) total_0_r <= dot_0_w;
            else total_0_r <= total_0_r+dot_0_w;
        end
    end
    assign total_bus_w[0*ACC_WIDTH +: ACC_WIDTH] = total_0_r;

    //-------------------------------------//
    //                Bank 1               //
    //-------------------------------------//
    assign dot_1_w = pea_psum_i[1*ACC_WIDTH +: ACC_WIDTH];

    //-------------------------------------//
    //           Sequential Logic          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) total_1_r <= 0;
        else if (state_r == DOT_WAIT && pea_valid_i) begin
            if (chunk_r == 0) total_1_r <= dot_1_w;
            else total_1_r <= total_1_r+dot_1_w;
        end
    end
    assign total_bus_w[1*ACC_WIDTH +: ACC_WIDTH] = total_1_r;

    //-------------------------------------//
    //                Bank 2               //
    //-------------------------------------//
    assign dot_2_w = pea_psum_i[2*ACC_WIDTH +: ACC_WIDTH];

    //-------------------------------------//
    //           Sequential Logic          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) total_2_r <= 0;
        else if (state_r == DOT_WAIT && pea_valid_i) begin
            if (chunk_r == 0) total_2_r <= dot_2_w;
            else total_2_r <= total_2_r+dot_2_w;
        end
    end
    assign total_bus_w[2*ACC_WIDTH +: ACC_WIDTH] = total_2_r;

    //-------------------------------------//
    //                Bank 3               //
    //-------------------------------------//
    assign dot_3_w = pea_psum_i[3*ACC_WIDTH +: ACC_WIDTH];

    //-------------------------------------//
    //           Sequential Logic          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) total_3_r <= 0;
        else if (state_r == DOT_WAIT && pea_valid_i) begin
            if (chunk_r == 0) total_3_r <= dot_3_w;
            else total_3_r <= total_3_r+dot_3_w;
        end
    end
    assign total_bus_w[3*ACC_WIDTH +: ACC_WIDTH] = total_3_r;

    //-------------------------------------//
    //           Main Control FSM          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_r <= IDLE;

            bank_r <= 0;
            inputs_r <= 0;
            outputs_r <= 0;
            group_r <= 0;
            chunk_r <= 0;
            relu_enable_r <= 0;

            busy_o <= 0;
            done_o <= 0;
        end
        else begin
            done_o <= 0;
            case (state_r)
                // Wait for a new layer request and latch its dimensions.
                IDLE: if (start_i) begin
                    inputs_r <= inputs_i;
                    outputs_r <= outputs_i;
                    relu_enable_r <= relu_enable_i;
                    group_r <= 0;
                    chunk_r <= 0;
                    bank_r <= 0;

                    busy_o <= 1;
                    state_r <= LOAD_DATA;
                end
                LOAD_DATA: if (loader_started_r && loader_done_w)
                    state_r <= LOAD;
                // Latch the complete weight vector into the physical PEs.
                LOAD: state_r <= SEND;
                SEND: state_r <= DOT_WAIT;
                // Wait for the pipelined PEA result before advancing.
                DOT_WAIT: if (pea_valid_i) begin
                    bank_r <= 0;

                    if (chunk_r+16'd25 >= inputs_r) state_r <= WRITE;
                    else begin
                        chunk_r <= chunk_r+16'd25;
                        state_r <= LOAD_DATA;
                    end
                end
                // Write one active output bank after bias and postprocessing.
                WRITE: if (bank_r == 3) begin
                    bank_r <= 0;
                    chunk_r <= 0;
                    if (group_r+16'd4 >= outputs_r) begin
                        busy_o<=0;
                    done_o<=1;
                    state_r<=IDLE;
                    end
                    else begin
                        group_r <= group_r+16'd4;
                        state_r <= LOAD_DATA;
                    end
                end
                else bank_r <= bank_r+1'b1;
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
    wire [4:0] active_taps_w;
    assign active_taps_w = inputs_r-chunk_r>=25 ? 5'd25 : inputs_r-chunk_r;
    Parallel_Data_Loader #(.DATA_WIDTH(DATA_WIDTH)) u_loader (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .start_i(state_r==LOAD_DATA && !loader_started_r),
        .input_enable_i(1'b1),
        .bias_enable_i(chunk_r==0),
        .group_i(group_r),
        .outputs_i(outputs_r),
        .weight_base_i(group_r*inputs_r+chunk_r),
        .weight_stride_i(inputs_r),
        .input_base_i(chunk_r),
        .taps_i(active_taps_w),
        .input_rd_en_o(rd_en_o),
        .input_rd_addr_o(rd_addr_o),
        .input_rd_data_i(rd_data_i),
        .input_rd_valid_i(rd_valid_i),
        .inputs_o(inputs_vector_w),
        .weight_rd_en_o(weight_rd_en_o),
        .weight_rd_addr_o(weight_rd_addr_o),
        .weight_rd_data_i(weight_rd_data_i),
        .weight_rd_valid_i(weight_rd_valid_i),
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
