`timescale 1ns/1ps
// Layer sequencer and synchronous RAM routing. All data multiplication is in PEs.

module Lenet5_Engine #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 8,
    parameter ACC_WIDTH = 48,
    parameter CONV1_CH = 6,
    parameter CONV2_CH = 16,
    parameter FC1_NEURONS = 120,
    parameter FC2_NEURONS = 84
) (
    input wire                                       clk_i,
    input wire                                       rst_n_i,
    input wire                                       start_i,
    output reg                                       busy_o,
    output reg                                       done_o,
    input wire                                       ifmap_wr_en_i,
    input wire [9:0]                                 ifmap_wr_addr_i,
    input wire signed [DATA_WIDTH-1:0]               ifmap_wr_data_i,
    input wire                                       cfg_we_i,
    input wire [2:0]                                 cfg_layer_i,
    input wire                                       cfg_is_bias_i,
    input wire [15:0]                                cfg_addr_i,
    input wire signed [DATA_WIDTH-1:0]               cfg_data_i,
    output reg [10*DATA_WIDTH-1:0]                   logits_o,
    output reg [3:0]                                 pred_class_o,
    output reg signed [DATA_WIDTH-1:0]               pred_score_o
);

    //-------------------------------------//
    //     Local Parameter Declarations    //
    //-------------------------------------//
    localparam CONV1_W_SIZE = CONV1_CH*25;
    localparam CONV2_W_SIZE = CONV2_CH*CONV1_CH*25;
    localparam FC1_INPUTS = CONV2_CH*16;
    localparam FC1_W_SIZE = FC1_NEURONS*FC1_INPUTS;
    localparam FC2_W_SIZE = FC2_NEURONS*FC1_NEURONS;
    localparam FC3_W_SIZE = 10*FC2_NEURONS;
    localparam ACT0 = (CONV1_CH*576>CONV2_CH*64)?CONV1_CH*576:CONV2_CH*64;
    localparam ACT1 = (FC1_NEURONS>FC2_NEURONS)?FC1_NEURONS:FC2_NEURONS;
    localparam ACT2 = (ACT0>ACT1)?ACT0:ACT1;
    localparam ACT_DEPTH = (ACT2>784)?ACT2:784;
    localparam [2:0] SEQ_IDLE = 0, SEQ_START = 1, SEQ_WAIT = 2, ARG_REQ = 3, ARG_WAIT = 4, SEQ_FINISH = 5;
    localparam [2:0] CONV1 = 0, POOL1 = 1, CONV2 = 2, POOL2 = 3, FC1 = 4, FC2 = 5, FC3 = 6;

    //-------------------------------------//
    //        Register Declarations        //
    //-------------------------------------//
    reg [2:0] state_r, stage_r;
    reg [3:0] class_r;
    reg rd_en_w, wr_en_w;
    reg [1:0] rd_kind_w;
    reg [15:0] rd_addr_w, wr_addr_w;
    reg signed [DATA_WIDTH-1:0] wr_data_w;
    wire signed [DATA_WIDTH-1:0] rd_data_r;
    wire rd_valid_r;

    //-------------------------------------//
    //          Wire Declarations          //
    //-------------------------------------//
    wire conv_weight_en_w, fc_weight_en_w;
    wire [15:0] conv_weight_addr_w, fc_weight_addr_w;
    wire conv_bias_en_w, fc_bias_en_w;
    wire [15:0] conv_bias_addr_w, fc_bias_addr_w;
    wire [DATA_WIDTH-1:0] act_data_w, weight_data_w, bias_data_w;
    wire act_valid_w, weight_valid_w, bias_valid_w;
    wire conv_active_w, pool_active_w, fc_active_w;
    wire conv_start_w, pool_start_w, fc_start_w;
    wire conv_busy_w, conv_done_w, pool_busy_w, pool_done_w, fc_busy_w, fc_done_w;
    wire conv_rd_en_w, pool_rd_en_w, fc_rd_en_w;

    wire [15:0] conv_rd_addr_w, pool_rd_addr_w, fc_rd_addr_w;
    wire conv_wr_en_w, pool_wr_en_w, fc_wr_en_w;
    wire [15:0] conv_wr_addr_w, pool_wr_addr_w, fc_wr_addr_w;
    wire signed [DATA_WIDTH-1:0] conv_wr_data_w, pool_wr_data_w, fc_wr_data_w;
    wire conv_load_w, conv_valid_w, fc_load_w, fc_valid_w;
    wire [100*DATA_WIDTH-1:0] conv_weights_w, fc_weights_w;
    wire [25*DATA_WIDTH-1:0] conv_window_w, fc_window_w;
    wire [4*ACC_WIDTH-1:0] pea_psum_w;
    wire pea_valid_w;
    wire [5:0] conv_width_w, pool_width_w;
    wire [15:0] conv_cin_w, conv_cout_w, pool_channels_w, fc_inputs_w, fc_outputs_w;

    //-------------------------------------//
    //      Datapath and Control Logic     //

    //-------------------------------------//
    // Stage 0/2/4/6: A -> B. Stage 1/3/5: B -> A.
    assign conv_active_w = (stage_r == CONV1 || stage_r == CONV2);
    assign pool_active_w = (stage_r == POOL1 || stage_r == POOL2);
    assign fc_active_w = (stage_r == FC1 || stage_r == FC2 || stage_r == FC3);
    assign conv_start_w = (state_r == SEQ_START && conv_active_w);
    assign pool_start_w = (state_r == SEQ_START && pool_active_w);
    assign fc_start_w = (state_r == SEQ_START && fc_active_w);
    assign conv_width_w = (stage_r == CONV1)?6'd28:6'd12;
    assign conv_cin_w = (stage_r == CONV1)?16'd1:CONV1_CH;
    assign conv_cout_w = (stage_r == CONV1)?CONV1_CH:CONV2_CH;
    assign pool_width_w = (stage_r == POOL1)?6'd24:6'd8;
    assign pool_channels_w = (stage_r == POOL1)?CONV1_CH:CONV2_CH;
    assign fc_inputs_w = (stage_r == FC1)?FC1_INPUTS:(stage_r == FC2)?FC1_NEURONS:FC2_NEURONS;
    assign fc_outputs_w = (stage_r == FC1)?FC1_NEURONS:(stage_r == FC2)?FC2_NEURONS:16'd10;

    //-------------------------------------//
    //       Conv Controller Instance      //
    //-------------------------------------//
    Conv_Controller #(
        .DATA_WIDTH             (DATA_WIDTH),
        .ACC_WIDTH              (ACC_WIDTH)
    ) u_conv (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .start_i                (conv_start_w),
        .width_i                (conv_width_w),
        .height_i               (conv_width_w),
        .cin_i                  (conv_cin_w),
        .cout_i                 (conv_cout_w),
        .busy_o                 (conv_busy_w),
        .done_o                 (conv_done_w),
        .rd_en_o                (conv_rd_en_w),
        .weight_rd_en_o(conv_weight_en_w),
        .weight_rd_addr_o(conv_weight_addr_w),
        .weight_rd_data_i(weight_data_w),
        .weight_rd_valid_i(weight_valid_w && conv_active_w),
        .bias_rd_en_o(conv_bias_en_w),
        .bias_rd_addr_o(conv_bias_addr_w),
        .bias_rd_data_i(bias_data_w),
        .bias_rd_valid_i(bias_valid_w && conv_active_w),
        .rd_addr_o              (conv_rd_addr_w),
        .rd_data_i              (rd_data_r),
        .rd_valid_i             (act_valid_w && conv_active_w),
        .wr_en_o                (conv_wr_en_w),
        .wr_addr_o              (conv_wr_addr_w),
        .wr_data_o              (conv_wr_data_w),
        .pea_weight_load_o      (conv_load_w),
        .pea_weight_o           (conv_weights_w),
        .pea_window_o           (conv_window_w),
        .pea_valid_o            (conv_valid_w),
        .pea_psum_i             (pea_psum_w),
        .pea_valid_i            (pea_valid_w && conv_active_w)
    );

    //-------------------------------------//
    //        FC Controller Instance       //
    //-------------------------------------//
    FC_Controller #(
        .DATA_WIDTH             (DATA_WIDTH),
        .ACC_WIDTH              (ACC_WIDTH)
    ) u_fc (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .start_i                (fc_start_w),
        .inputs_i               (fc_inputs_w),
        .outputs_i              (fc_outputs_w),
        .relu_enable_i          (stage_r != FC3),
        .busy_o                 (fc_busy_w),
        .done_o                 (fc_done_w),
        .rd_en_o                (fc_rd_en_w),
        .weight_rd_en_o(fc_weight_en_w),
        .weight_rd_addr_o(fc_weight_addr_w),
        .weight_rd_data_i(weight_data_w),
        .weight_rd_valid_i(weight_valid_w && fc_active_w),
        .bias_rd_en_o(fc_bias_en_w),
        .bias_rd_addr_o(fc_bias_addr_w),
        .bias_rd_data_i(bias_data_w),
        .bias_rd_valid_i(bias_valid_w && fc_active_w),
        .rd_addr_o              (fc_rd_addr_w),
        .rd_data_i              (rd_data_r),
        .rd_valid_i             (act_valid_w && fc_active_w),
        .wr_en_o                (fc_wr_en_w),
        .wr_addr_o              (fc_wr_addr_w),
        .wr_data_o              (fc_wr_data_w),
        .pea_weight_load_o      (fc_load_w),
        .pea_weight_o           (fc_weights_w),
        .pea_window_o           (fc_window_w),
        .pea_valid_o            (fc_valid_w),
        .pea_psum_i             (pea_psum_w),
        .pea_valid_i            (pea_valid_w && fc_active_w)
    );

    //-------------------------------------//
    //       Pool Controller Instance      //
    //-------------------------------------//
    Pool_Controller #(
        .DATA_WIDTH             (DATA_WIDTH)
    ) u_pool (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .start_i                (pool_start_w),
        .width_i                (pool_width_w),
        .height_i               (pool_width_w),
        .channels_i             (pool_channels_w),
        .busy_o                 (pool_busy_w),
        .done_o                 (pool_done_w),
        .rd_en_o                (pool_rd_en_w),
        .rd_addr_o              (pool_rd_addr_w),
        .rd_data_i              (rd_data_r),
        .rd_valid_i             (rd_valid_r && pool_active_w),
        .wr_en_o                (pool_wr_en_w),
        .wr_addr_o              (pool_wr_addr_w),
        .wr_data_o              (pool_wr_data_w)
    );
    // Exactly ONE PEA instance is shared by both convolution and FC controllers.

    //-------------------------------------//
    //           PEA 5x5 Instance          //
    //-------------------------------------//
    PEA_5x5 #(
        .DATA_WIDTH             (DATA_WIDTH),
        .FRAC_BITS              (FRAC_BITS),
        .ACC_WIDTH              (ACC_WIDTH)
    ) u_pea (
        .clk_i                  (clk_i),
        .rst_n_i                (rst_n_i),
        .weight_load_i          (conv_active_w?conv_load_w:fc_active_w?fc_load_w:1'b0),
        .weight_i               (conv_active_w?conv_weights_w:fc_weights_w),
        .window_i               (conv_active_w?conv_window_w:fc_window_w),
        .valid_i                (conv_active_w?conv_valid_w:fc_active_w?fc_valid_w:1'b0),
        .psum_o                 (pea_psum_w),
        .valid_o                (pea_valid_w)
    );

    //-------------------------------------//
    //         Combinational Logic         //
    //-------------------------------------//
    always @(*) begin
        rd_en_w = 0;
        rd_kind_w = 0;
        rd_addr_w = 0;
        wr_en_w = 0;
        wr_addr_w = 0;
        wr_data_w = 0;
        if (state_r == SEQ_WAIT) begin
            if (conv_active_w) begin
                rd_en_w = conv_rd_en_w;
                rd_kind_w = 0;
                rd_addr_w = conv_rd_addr_w;
                wr_en_w = conv_wr_en_w;
                wr_addr_w = conv_wr_addr_w;
                wr_data_w = conv_wr_data_w;
            end
            else if (pool_active_w) begin
                rd_en_w = pool_rd_en_w;
                rd_kind_w = 0;
                rd_addr_w = pool_rd_addr_w;
                wr_en_w = pool_wr_en_w;
                wr_addr_w = pool_wr_addr_w;
                wr_data_w = pool_wr_data_w;
            end
            else if (fc_active_w) begin
                rd_en_w = fc_rd_en_w;
                rd_kind_w = 0;
                rd_addr_w = fc_rd_addr_w;
                wr_en_w = fc_wr_en_w;
                wr_addr_w = fc_wr_addr_w;
                wr_data_w = fc_wr_data_w;
            end
        end
        else if (state_r == ARG_REQ) begin
            rd_en_w = 1;
            rd_kind_w = 0;
            rd_addr_w = {12'd0, class_r};
        end
    end

    //-------------------------------------//
    // Dedicated Memory Interfaces
    //-------------------------------------//
    wire [2:0] memory_layer_w;
    assign memory_layer_w = (stage_r==CONV1) ? 3'd0 :
                            (stage_r==CONV2) ? 3'd1 :
                            (stage_r==FC1) ? 3'd2 :
                            (stage_r==FC2) ? 3'd3 : 3'd4;
    assign rd_valid_r = act_valid_w;
    assign rd_data_r = act_data_w;

    Ping_Pong_Memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(ACT_DEPTH)
    ) u_ping_pong_memory (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .host_we_i(!busy_o && ifmap_wr_en_i && ifmap_wr_addr_i<784),
        .host_addr_i(ifmap_wr_addr_i),
        .host_data_i(ifmap_wr_data_i),
        .rd_en_i(rd_en_w && rd_kind_w==0),
        .rd_bank_i(state_r==ARG_REQ || stage_r[0]),
        .rd_addr_i(rd_addr_w),
        .rd_data_o(act_data_w),
        .rd_valid_o(act_valid_w),
        .wr_en_i(wr_en_w),
        .wr_bank_i(!stage_r[0]),
        .wr_addr_i(wr_addr_w),
        .wr_data_i(wr_data_w)
    );
    Weight_Memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .CONV1_CH(CONV1_CH),
        .CONV2_CH(CONV2_CH),
        .FC1_NEURONS(FC1_NEURONS),
        .FC2_NEURONS(FC2_NEURONS)
    ) u_weight_memory (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .cfg_we_i(!busy_o && cfg_we_i && !cfg_is_bias_i),
        .cfg_layer_i(cfg_layer_i),
        .cfg_addr_i(cfg_addr_i),
        .cfg_data_i(cfg_data_i),
        .rd_en_i(state_r==SEQ_WAIT && (conv_active_w ? conv_weight_en_w : fc_active_w ? fc_weight_en_w : 1'b0)),
        .rd_layer_i(memory_layer_w),
        .rd_addr_i(conv_active_w ? conv_weight_addr_w : fc_weight_addr_w),
        .rd_data_o(weight_data_w),
        .rd_valid_o(weight_valid_w) // = rd_en_i delay 1 clock
    );
    Bias_Memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .CONV1_CH(CONV1_CH),
        .CONV2_CH(CONV2_CH),
        .FC1_NEURONS(FC1_NEURONS),
        .FC2_NEURONS(FC2_NEURONS)
    ) u_bias_memory (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .cfg_we_i(!busy_o && cfg_we_i && cfg_is_bias_i),
        .cfg_layer_i(cfg_layer_i),
        .cfg_addr_i(cfg_addr_i),
        .cfg_data_i(cfg_data_i),
        .rd_en_i(state_r==SEQ_WAIT && (conv_active_w ? conv_bias_en_w : fc_active_w ? fc_bias_en_w : 1'b0)),
        .rd_layer_i(memory_layer_w),
        .rd_addr_i(conv_active_w ? conv_bias_addr_w : fc_bias_addr_w),
        .rd_data_o(bias_data_w),
        .rd_valid_o(bias_valid_w)
    );

    //-------------------------------------//
    //         Layer Sequencer FSM         //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_r <= SEQ_IDLE;
            stage_r <= CONV1;
            class_r <= 0;
            busy_o <= 0;
            done_o <= 0;
            logits_o <= 0;
            pred_class_o <= 0;
            pred_score_o <= 0;
        end
        else begin
            case (state_r)
                SEQ_IDLE: if (start_i) begin
                    busy_o <= 1;
                    done_o <= 0;
                    stage_r <= CONV1;
                    state_r <= SEQ_START;
                end
                // Start only the controller selected by the current layer.
                SEQ_START: state_r <= SEQ_WAIT;
                // Wait for completion before selecting the next layer.
                SEQ_WAIT: if ((conv_active_w && conv_done_w) ||
                    (pool_active_w && pool_done_w) || (fc_active_w && fc_done_w)) begin
                    if (stage_r == FC3) begin
                        class_r <= 0;
                        state_r <= ARG_REQ;
                    end
                    else begin
                        stage_r <= stage_r+1'b1;
                        state_r <= SEQ_START;
                    end
                end
                // Read one final logit for signed argmax comparison.
                ARG_REQ: state_r <= ARG_WAIT;
                ARG_WAIT: if (rd_valid_r) begin
                    logits_o[class_r*DATA_WIDTH +: DATA_WIDTH] <= rd_data_r;
                    if (class_r == 0 || $signed(rd_data_r)>$signed(pred_score_o)) begin
                        pred_class_o <= class_r;
                        pred_score_o <= rd_data_r;
                    end
                    if (class_r == 9) state_r <= SEQ_FINISH;
                    else begin
                        class_r <= class_r+1'b1;
                        state_r <= ARG_REQ;
                    end
                end
                // Publish inference completion; results remain available.
                SEQ_FINISH: begin
                    busy_o <= 0;
                    done_o <= 1;
                    state_r <= SEQ_IDLE;
                end
                default: begin
                    busy_o <= 0;
                    state_r <= SEQ_IDLE;
                end
            endcase
        end
    end
endmodule
