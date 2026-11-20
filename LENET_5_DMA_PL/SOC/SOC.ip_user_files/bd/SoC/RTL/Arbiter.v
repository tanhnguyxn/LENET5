// Host address ports carry 128-bit row indices (eight Q8.8 elements per row).
`timescale 1ns/1ps

module Arbiter #(
    parameter CONV1_CH    = 6,
    parameter CONV2_CH    = 16,
    parameter FC1_NEURONS = 120,
    parameter FC2_NEURONS = 84
) (
    input  wire         clk_i,
    input  wire         rst_n_i,

    // Host write interface
    input  wire         host_wr_valid_i,
    input  wire [18:0]  host_wr_addr_i,
    input  wire [127:0] host_wr_data_i,
    input  wire [15:0]  host_wr_strb_i, // which byte valid to write

    // Host read interface
    input  wire [18:0]  host_rd_addr_i,
    output reg  [127:0] host_rd_data_o,

    // Status and results from the compute engine
    input  wire         core_busy_i,
    input  wire         core_done_i,
    input  wire [159:0] core_logits_i,
    input  wire [3:0]   core_pred_class_i,
    input  wire signed [15:0] core_pred_score_i,

    // Start command
    output wire         core_start_o,

    // Input image write interface
    output wire         core_ifmap_wr_en_o,
    output wire [6:0]   core_ifmap_wr_addr_o,
    output wire [127:0] core_ifmap_wr_data_o,
    output wire [15:0]  core_ifmap_wr_strb_o,

    // Weight and bias write interface
    output wire         core_cfg_we_o,
    output wire [2:0]   core_cfg_layer_o,
    output wire         core_cfg_is_bias_o,
    output wire [12:0]  core_cfg_addr_o,
    output wire [127:0] core_cfg_data_o,
    output wire [15:0]  core_cfg_strb_o // which byte valid in bus to write to ip mem
);

    //-------------------------------------//
    //         Register Row Addresses     //
    //-------------------------------------//
    // All addresses are 128-bit row offsets from the LeNet5 IP base.
    localparam [18:0] ADDR_START_STATUS          = 19'h00000;
    localparam [18:0] ADDR_PREDICTION_RESULT     = 19'h00001;
    localparam [18:0] ADDR_BUSY_CYCLE_COUNT      = 19'h00002;
    localparam [18:0] ADDR_VERSION_ID            = 19'h00003;
    localparam [18:0] ADDR_LOGITS_0_TO_7         = 19'h00010;
    localparam [18:0] ADDR_LOGITS_8_TO_9         = 19'h00011;

    //-------------------------------------//
    //          Memory Row Addresses      //
    //-------------------------------------//
    localparam [18:0] ADDR_INPUT_IMAGE_BASE      = 19'h01000;

    localparam [18:0] ADDR_CONV1_WEIGHT_BASE     = 19'h02000;
    localparam [18:0] ADDR_CONV2_WEIGHT_BASE     = 19'h03000;
    localparam [18:0] ADDR_FC1_WEIGHT_BASE       = 19'h04000;
    localparam [18:0] ADDR_FC2_WEIGHT_BASE       = 19'h05000;
    localparam [18:0] ADDR_FC3_WEIGHT_BASE       = 19'h06000;

    localparam [18:0] ADDR_BIAS_REGION_BASE      = 19'h07000;
    localparam [18:0] ADDR_CONV1_BIAS_BASE       = 19'h07000;
    localparam [18:0] ADDR_CONV2_BIAS_BASE       = 19'h07100;
    localparam [18:0] ADDR_FC1_BIAS_BASE         = 19'h07200;
    localparam [18:0] ADDR_FC2_BIAS_BASE         = 19'h07300;
    localparam [18:0] ADDR_FC3_BIAS_BASE         = 19'h07400;

    //-------------------------------------//
    //         Memory Configuration        //
    //-------------------------------------//
    localparam Q88_BYTES   = 2;
    localparam KERNEL_TAPS = 5 * 5;
    localparam FC1_INPUTS  = CONV2_CH * 4 * 4;
    localparam NUM_CLASSES = 10;

    localparam IMAGE_BYTES        = 28 * 28 * Q88_BYTES;
    localparam CONV1_WEIGHT_BYTES = CONV1_CH * KERNEL_TAPS * Q88_BYTES;
    localparam CONV2_WEIGHT_BYTES = CONV2_CH * CONV1_CH * KERNEL_TAPS
                                  * Q88_BYTES;
    localparam FC1_WEIGHT_BYTES   = FC1_NEURONS * FC1_INPUTS * Q88_BYTES;
    localparam FC2_WEIGHT_BYTES   = FC2_NEURONS * FC1_NEURONS * Q88_BYTES;
    localparam FC3_WEIGHT_BYTES   = NUM_CLASSES * FC2_NEURONS * Q88_BYTES;

    localparam CONV1_BIAS_BYTES = CONV1_CH    * Q88_BYTES;
    localparam CONV2_BIAS_BYTES = CONV2_CH    * Q88_BYTES;
    localparam FC1_BIAS_BYTES   = FC1_NEURONS * Q88_BYTES;
    localparam FC2_BIAS_BYTES   = FC2_NEURONS * Q88_BYTES;
    localparam FC3_BIAS_BYTES   = NUM_CLASSES * Q88_BYTES;

    localparam [2:0] LAYER_CONV1 = 3'd0;
    localparam [2:0] LAYER_CONV2 = 3'd1;
    localparam [2:0] LAYER_FC1   = 3'd2;
    localparam [2:0] LAYER_FC2   = 3'd3;
    localparam [2:0] LAYER_FC3   = 3'd4;

    // Exactly one write destination is selected for each address.
    localparam [2:0] DEST_NONE    = 3'd0;
    localparam [2:0] DEST_CONTROL = 3'd1;
    localparam [2:0] DEST_IMAGE   = 3'd2;
    localparam [2:0] DEST_WEIGHT  = 3'd3;
    localparam [2:0] DEST_BIAS    = 3'd4;

    localparam [31:0] VERSION_ID = 32'h4C4E1281;

    //-------------------------------------//
    //       Signal Declarations           //
    //-------------------------------------//
    reg  [2:0]  write_dest_w;
    reg  [2:0]  layer_id_w;
    reg  [18:0] memory_base_w;
    reg  [22:0] memory_size_bytes_w;

    wire [18:0] row_index_w;
    wire [22:0] row_first_byte_w;

    wire [22:0] bytes_remaining_w;
    reg  [15:0] allowed_strb_w;

    wire        write_accepted_w;
    reg  [31:0] cycles_r;

    //-------------------------------------//
    //   1. Select the Write Destination   //
    //-------------------------------------//
    // Main regions are spaced 64 KiB apart.
    // Bias regions are spaced 4 KiB apart within the bias region.
    always @(*) begin
        write_dest_w        = DEST_NONE;
        layer_id_w          = LAYER_CONV1;
        memory_base_w       = 23'd0;
        memory_size_bytes_w = 23'd0;

        case (host_wr_addr_i[18:12])

            ADDR_START_STATUS[18:12]: begin
                // Only the START word is writable in the register region.
                if (host_wr_addr_i[11:0] == ADDR_START_STATUS[11:0])
                    write_dest_w = DEST_CONTROL;
            end

            ADDR_INPUT_IMAGE_BASE[18:12]: begin
                write_dest_w        = DEST_IMAGE;
                memory_base_w       = ADDR_INPUT_IMAGE_BASE;
                memory_size_bytes_w = IMAGE_BYTES;
            end

            ADDR_CONV1_WEIGHT_BASE[18:12]: begin
                write_dest_w        = DEST_WEIGHT;
                layer_id_w          = LAYER_CONV1;
                memory_base_w       = ADDR_CONV1_WEIGHT_BASE;
                memory_size_bytes_w = CONV1_WEIGHT_BYTES;
            end

            ADDR_CONV2_WEIGHT_BASE[18:12]: begin
                write_dest_w        = DEST_WEIGHT;
                layer_id_w          = LAYER_CONV2;
                memory_base_w       = ADDR_CONV2_WEIGHT_BASE;
                memory_size_bytes_w = CONV2_WEIGHT_BYTES;
            end

            ADDR_FC1_WEIGHT_BASE[18:12]: begin
                write_dest_w        = DEST_WEIGHT;
                layer_id_w          = LAYER_FC1;
                memory_base_w       = ADDR_FC1_WEIGHT_BASE;
                memory_size_bytes_w = FC1_WEIGHT_BYTES;
            end

            ADDR_FC2_WEIGHT_BASE[18:12]: begin
                write_dest_w        = DEST_WEIGHT;
                layer_id_w          = LAYER_FC2;
                memory_base_w       = ADDR_FC2_WEIGHT_BASE;
                memory_size_bytes_w = FC2_WEIGHT_BYTES;
            end

            ADDR_FC3_WEIGHT_BASE[18:12]: begin
                write_dest_w        = DEST_WEIGHT;
                layer_id_w          = LAYER_FC3;
                memory_base_w       = ADDR_FC3_WEIGHT_BASE;
                memory_size_bytes_w = FC3_WEIGHT_BYTES;
            end

            ADDR_BIAS_REGION_BASE[18:12]: begin
                write_dest_w = DEST_BIAS;

                case (host_wr_addr_i[11:8])
                    ADDR_CONV1_BIAS_BASE[11:8]: begin
                        layer_id_w          = LAYER_CONV1;
                        memory_base_w       = ADDR_CONV1_BIAS_BASE;
                        memory_size_bytes_w = CONV1_BIAS_BYTES;
                    end

                    ADDR_CONV2_BIAS_BASE[11:8]: begin
                        layer_id_w          = LAYER_CONV2;
                        memory_base_w       = ADDR_CONV2_BIAS_BASE;
                        memory_size_bytes_w = CONV2_BIAS_BYTES;
                    end

                    ADDR_FC1_BIAS_BASE[11:8]: begin
                        layer_id_w          = LAYER_FC1;
                        memory_base_w       = ADDR_FC1_BIAS_BASE;
                        memory_size_bytes_w = FC1_BIAS_BYTES;
                    end

                    ADDR_FC2_BIAS_BASE[11:8]: begin
                        layer_id_w          = LAYER_FC2;
                        memory_base_w       = ADDR_FC2_BIAS_BASE;
                        memory_size_bytes_w = FC2_BIAS_BYTES;
                    end

                    ADDR_FC3_BIAS_BASE[11:8]: begin
                        layer_id_w          = LAYER_FC3;
                        memory_base_w       = ADDR_FC3_BIAS_BASE;
                        memory_size_bytes_w = FC3_BIAS_BYTES;
                    end

                    default: write_dest_w = DEST_NONE;
                endcase
            end

            default: write_dest_w = DEST_NONE;
        endcase
    end

    //-------------------------------------//
    //        Select the Local RAM Row     //
    //-------------------------------------//
    assign row_index_w      = host_wr_addr_i - memory_base_w;
    // Used only to mask bytes beyond the end of the memory.
    assign row_first_byte_w = {row_index_w, 4'b0000};

    //-------------------------------------//
    //    3. Check the Write Byte Lanes    //
    //-------------------------------------//
    // Count valid bytes from the beginning of this row.
    // Clamp at zero when the entire row is outside the memory.
    assign bytes_remaining_w =
        (row_first_byte_w < memory_size_bytes_w)
        ? (memory_size_bytes_w - row_first_byte_w)
        : 23'd0;

    always @(*) begin
        if (bytes_remaining_w >= 23'd16) begin
            // Full row: all sixteen byte lanes are valid.
            allowed_strb_w = 16'hFFFF;
        end else begin
            // Partial row: only the lowest N byte lanes are valid.
            // Example: N=12 gives 0x0FFF; N=0 gives 0x0000.
            allowed_strb_w = (16'h0001 << bytes_remaining_w[3:0])
                           - 16'h0001;
        end
    end


	//-------------------------------------//
	//         Host Write Enable           //
	//-------------------------------------//
	assign write_accepted_w = rst_n_i
						   && host_wr_valid_i
						   && !core_busy_i;

    // START is bit 0 of byte 0.
    assign core_start_o = write_accepted_w
                       && (write_dest_w == DEST_CONTROL)
                       && host_wr_strb_i[0]
                       && host_wr_data_i[0];

    // Input image writes go to Ping memory.
    assign core_ifmap_wr_en_o   = write_accepted_w
                               && (write_dest_w == DEST_IMAGE);
    assign core_ifmap_wr_addr_o = row_index_w[6:0];
    assign core_ifmap_wr_data_o = host_wr_data_i;
    assign core_ifmap_wr_strb_o = host_wr_strb_i & allowed_strb_w;

    // Weight and bias writes share the engine configuration interface.
    assign core_cfg_we_o      = write_accepted_w
                             && ((write_dest_w == DEST_WEIGHT) ||
                                 (write_dest_w == DEST_BIAS));
    assign core_cfg_layer_o   = layer_id_w;
    assign core_cfg_is_bias_o = (write_dest_w == DEST_BIAS);
    assign core_cfg_addr_o    = row_index_w[12:0];
    assign core_cfg_data_o    = host_wr_data_i;
    assign core_cfg_strb_o = host_wr_strb_i & allowed_strb_w;

    //-------------------------------------//
    //         Read Status and Results     //
    //-------------------------------------//
    // Decode the host read row directly.
    always @(*) begin
        host_rd_data_o  = 128'd0;

        case (host_rd_addr_i)
            ADDR_START_STATUS: begin
                host_rd_data_o[0] = core_busy_i;
                host_rd_data_o[1] = core_done_i;
            end

            ADDR_PREDICTION_RESULT: begin
                host_rd_data_o[15:0]  = core_pred_score_i;
                host_rd_data_o[19:16] = core_pred_class_i;
            end

            ADDR_BUSY_CYCLE_COUNT:
                host_rd_data_o[31:0] = cycles_r;

            ADDR_VERSION_ID:
                host_rd_data_o[31:0] = VERSION_ID;

            ADDR_LOGITS_0_TO_7:
                host_rd_data_o = core_logits_i[127:0];

            ADDR_LOGITS_8_TO_9:
                host_rd_data_o[31:0] = core_logits_i[159:128];

            default:
                host_rd_data_o = 128'd0;
        endcase
    end

    //-------------------------------------//
    //          Count Busy Clocks          //
    //-------------------------------------//
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i)
            cycles_r <= 32'd0;
        else if (core_start_o)
            cycles_r <= 32'd0;
        else if (core_busy_i)
            cycles_r <= cycles_r + 1'b1;
    end

endmodule