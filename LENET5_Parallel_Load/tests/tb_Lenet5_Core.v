`timescale 1ns/1ps

module tb_Lenet5_Core;

    parameter DATA_ROOT =
    "C:/SOC/SOC_UIT/LENET5/LENET_5_Version1/LENET5/LENET5_Parallel_Load/train_model/outputs_q88/";

    parameter MAX_CYCLES = 32'd10000000;

    reg         clk_r;
    reg         rst_n_r;

    reg  [19:0] host_wr_addr_r;
    reg  [63:0] host_wr_data_r;
    reg         host_wr_valid_r;

    reg  [19:0] host_rd_addr_r;
    reg         host_rd_valid_r;
    wire [63:0] host_rd_data_w;

    reg [15:0] input_mem [0:783];
    reg [15:0] golden_mem [0:9];

    reg [15:0] conv1_weight_mem [0:149];
    reg [15:0] conv1_bias_mem   [0:5];

    reg [15:0] conv2_weight_mem [0:2399];
    reg [15:0] conv2_bias_mem   [0:15];

    reg [15:0] fc1_weight_mem [0:30719];
    reg [15:0] fc1_bias_mem   [0:119];

    reg [15:0] fc2_weight_mem [0:10079];
    reg [15:0] fc2_bias_mem   [0:83];

    reg [15:0] fc3_weight_mem [0:839];
    reg [15:0] fc3_bias_mem   [0:9];

    reg [19:0] index_r;
    reg [63:0] read_data_r;

    reg signed [15:0] logit_r;
    reg signed [15:0] golden_score_r;

    reg [3:0] golden_class_r;
    reg [4:0] mismatch_r;
    reg       prediction_match_r;

    reg [31:0] cycles_r;
    reg        running_r;

    //-------------------------------------//
    //                 DUT                 //
    //-------------------------------------//

    Lenet5_Core #(
        .DATA_WIDTH      (16),
        .FRAC_BITS       (8),
        .ACC_WIDTH       (48),
        .CONV1_CH        (6),
        .CONV2_CH        (16),
        .FC1_NEURONS     (120),
        .FC2_NEURONS     (84),
        .HOST_DATA_WIDTH (64)
    ) dut (
        .clk_i           (clk_r),
        .rst_n_i         (rst_n_r),

        .host_wr_addr_i   (host_wr_addr_r),
        .host_wr_data_i   (host_wr_data_r),
        .host_wr_valid_i  (host_wr_valid_r),

        .host_rd_addr_i   (host_rd_addr_r),
        .host_rd_valid_i  (host_rd_valid_r),
        .host_rd_data_o   (host_rd_data_w)
    );

    //-------------------------------------//
    //            100 MHz Clock            //
    //-------------------------------------//

    initial clk_r = 1'b0;
    always #5 clk_r = ~clk_r;

    //-------------------------------------//
    //              Host Write             //
    //-------------------------------------//

    task host_write;
        input [19:0] addr_i;
        input [15:0] data_i;

        begin
            // Reject missing or invalid HEX data before writing.
            if ((^data_i) === 1'bx) begin
                $display(
                    "ERROR: X/Z data at host write address %05h.",
                    addr_i
                );
                $display("Check HEX file paths and contents.");
                $finish;
            end

            @(negedge clk_r);
            host_wr_addr_r  = addr_i;
            host_wr_data_r  = {48'd0, data_i};
            host_wr_valid_r = 1'b1;

            @(negedge clk_r);
            host_wr_valid_r = 1'b0;
        end
    endtask

    //-------------------------------------//
    //              Host Read              //
    //-------------------------------------//

    task host_read;
        input  [19:0] addr_i;
        output [63:0] data_o;

        begin
            @(negedge clk_r);
            host_rd_addr_r  = addr_i;
            host_rd_valid_r = 1'b1;

            @(posedge clk_r);
            #1;
            data_o = host_rd_data_w;

            @(negedge clk_r);
            host_rd_valid_r = 1'b0;
        end
    endtask

    //-------------------------------------//
    //          Inference Timeout          //
    //-------------------------------------//

    always @(posedge clk_r) begin
        if (!rst_n_r)
            cycles_r <= 0;
        else if (running_r) begin
            cycles_r <= cycles_r + 1'b1;

            if (cycles_r >= MAX_CYCLES) begin
                $display("FAIL: inference timeout.");
                $display("No DONE after %0d clocks.", cycles_r);
                $finish;
            end
        end
    end

    //-------------------------------------//
    //             Test Sequence           //
    //-------------------------------------//

    initial begin
        rst_n_r            = 1'b0;

        host_wr_addr_r     = 0;
        host_wr_data_r     = 0;
        host_wr_valid_r    = 0;

        host_rd_addr_r     = 0;
        host_rd_valid_r    = 0;

        index_r            = 0;
        read_data_r        = 0;
        logit_r            = 0;

        golden_score_r     = 0;
        golden_class_r     = 0;
        mismatch_r         = 0;
        prediction_match_r = 0;
        running_r          = 0;

        //-------------------------------------//
        //           Load HEX Files            //
        //-------------------------------------//

        $display("Reading HEX files from:");
        $display("%0s", DATA_ROOT);

        $readmemh(
            {DATA_ROOT, "sample_input.hex"},
            input_mem
        );

        $readmemh(
            {DATA_ROOT, "sample_logits.hex"},
            golden_mem
        );

        $readmemh(
            {DATA_ROOT, "conv1_weight.hex"},
            conv1_weight_mem
        );

        $readmemh(
            {DATA_ROOT, "conv1_bias.hex"},
            conv1_bias_mem
        );

        $readmemh(
            {DATA_ROOT, "conv2_weight.hex"},
            conv2_weight_mem
        );

        $readmemh(
            {DATA_ROOT, "conv2_bias.hex"},
            conv2_bias_mem
        );

        $readmemh(
            {DATA_ROOT, "fc1_weight.hex"},
            fc1_weight_mem
        );

        $readmemh(
            {DATA_ROOT, "fc1_bias.hex"},
            fc1_bias_mem
        );

        $readmemh(
            {DATA_ROOT, "fc2_weight.hex"},
            fc2_weight_mem
        );

        $readmemh(
            {DATA_ROOT, "fc2_bias.hex"},
            fc2_bias_mem
        );

        $readmemh(
            {DATA_ROOT, "fc3_weight.hex"},
            fc3_weight_mem
        );

        $readmemh(
            {DATA_ROOT, "fc3_bias.hex"},
            fc3_bias_mem
        );

        //-------------------------------------//
        //         Check Input and Golden      //
        //-------------------------------------//

        index_r = 0;
        while (index_r < 784) begin
            if ((^input_mem[index_r]) === 1'bx) begin
                $display(
                    "ERROR: input[%0d] is X/Z. Check sample_input.hex.",
                    index_r
                );
                $finish;
            end

            index_r = index_r + 1'b1;
        end

        index_r = 0;
        while (index_r < 10) begin
            if ((^golden_mem[index_r]) === 1'bx) begin
                $display(
                    "ERROR: golden[%0d] is X/Z. Check sample_logits.hex.",
                    index_r
                );
                $finish;
            end

            index_r = index_r + 1'b1;
        end

        $display("Input and golden files loaded.");
        $display(
            "Input[0]=%04h, Input[400]=%04h, Input[783]=%04h",
            input_mem[0],
            input_mem[400],
            input_mem[783]
        );

        //-------------------------------------//
        //           Golden Argmax             //
        //-------------------------------------//

        golden_class_r = 0;
        golden_score_r = $signed(golden_mem[0]);

        index_r = 1;
        while (index_r < 10) begin
            // Keep the first class when scores are equal.
            if ($signed(golden_mem[index_r]) > golden_score_r) begin
                golden_score_r = $signed(golden_mem[index_r]);
                golden_class_r = index_r[3:0];
            end

            index_r = index_r + 1'b1;
        end

        //-------------------------------------//
        //             Release Reset           //
        //-------------------------------------//

        repeat (5) @(negedge clk_r);
        rst_n_r = 1'b1;

        //-------------------------------------//
        //             Load Weights            //
        //-------------------------------------//

        $display("Loading Conv1 weights...");

        index_r = 0;
        while (index_r < 150) begin
            host_write(
                20'h20000 + index_r,
                conv1_weight_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        $display("Loading Conv2 weights...");

        index_r = 0;
        while (index_r < 2400) begin
            host_write(
                20'h30000 + index_r,
                conv2_weight_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        $display("Loading FC1 weights...");

        index_r = 0;
        while (index_r < 30720) begin
            host_write(
                20'h40000 + index_r,
                fc1_weight_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        $display("Loading FC2 weights...");

        index_r = 0;
        while (index_r < 10080) begin
            host_write(
                20'h50000 + index_r,
                fc2_weight_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        $display("Loading FC3 weights...");

        index_r = 0;
        while (index_r < 840) begin
            host_write(
                20'h60000 + index_r,
                fc3_weight_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        //-------------------------------------//
        //              Load Biases            //
        //-------------------------------------//

        $display("Loading biases...");

        index_r = 0;
        while (index_r < 6) begin
            host_write(
                20'h70000 + index_r,
                conv1_bias_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        index_r = 0;
        while (index_r < 16) begin
            host_write(
                20'h72000 + index_r,
                conv2_bias_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        index_r = 0;
        while (index_r < 120) begin
            host_write(
                20'h74000 + index_r,
                fc1_bias_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        index_r = 0;
        while (index_r < 84) begin
            host_write(
                20'h76000 + index_r,
                fc2_bias_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        index_r = 0;
        while (index_r < 10) begin
            host_write(
                20'h78000 + index_r,
                fc3_bias_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        //-------------------------------------//
        //             Load Input              //
        //-------------------------------------//

        $display("Loading input image...");

        index_r = 0;
        while (index_r < 784) begin
            host_write(
                20'h10000 + index_r,
                input_mem[index_r]
            );
            index_r = index_r + 1'b1;
        end

        $display("Input loading completed: 784 pixels written to DUT.");

        //-------------------------------------//
        //           Start Inference           //
        //-------------------------------------//

        $display("Starting inference...");

        running_r = 1'b1;
        host_write(20'h00000, 16'h0001);

        //-------------------------------------//
        //             Wait for DONE           //
        //-------------------------------------//

        // Status bit 0 = busy; bit 1 = done.
        read_data_r = 0;

        while (read_data_r[1] !== 1'b1) begin
            host_read(20'h00000, read_data_r);

            if ((^read_data_r[1:0]) === 1'bx) begin
                $display("FAIL: status contains X/Z.");
                $finish;
            end
        end

        running_r = 1'b0;

        $display("Inference finished.");
        $display("Clocks during start/polling: %0d", cycles_r);

        //-------------------------------------//
        //         Compare Final Logits        //
        //-------------------------------------//

        mismatch_r = 0;

        $display("------------------------------------------------------------");
        $display("Digit | RTL HEX | Golden HEX | RTL Q8.8 | Golden Q8.8 | Result");
        $display("------------------------------------------------------------");

        index_r = 0;
        while (index_r < 10) begin
            host_read(20'h90000 + index_r, read_data_r);
            logit_r = $signed(read_data_r[15:0]);

            // Case inequality also detects unknown RTL output.
            if (logit_r !== golden_mem[index_r]) begin
                mismatch_r = mismatch_r + 1'b1;

                $display(
                    "%0d | %04h | %04h | %0.6f | %0.6f | FAIL",
                    index_r,
                    logit_r,
                    golden_mem[index_r],
                    $itor(logit_r) / 256.0,
                    $itor($signed(golden_mem[index_r])) / 256.0
                );
            end
            else begin
                $display(
                    "%0d | %04h | %04h | %0.6f | %0.6f | PASS",
                    index_r,
                    logit_r,
                    golden_mem[index_r],
                    $itor(logit_r) / 256.0,
                    $itor($signed(golden_mem[index_r])) / 256.0
                );
            end

            index_r = index_r + 1'b1;
        end

        //-------------------------------------//
        //         Compare Prediction          //
        //-------------------------------------//

        // Bits [19:16] = class; bits [15:0] = signed score.
        host_read(20'h80000, read_data_r);
        logit_r = $signed(read_data_r[15:0]);

        prediction_match_r =
            (read_data_r[19:16] === golden_class_r) &&
            (logit_r === golden_score_r);

        $display("------------------------------------------------------------");
        $display("RTL predicted digit    : %0d", read_data_r[19:16]);
        $display("Golden predicted digit : %0d", golden_class_r);

        $display(
            "RTL score              : %04h / %0.6f",
            logit_r,
            $itor(logit_r) / 256.0
        );

        $display(
            "Golden score           : %04h / %0.6f",
            golden_score_r,
            $itor(golden_score_r) / 256.0
        );

        $display("Logit mismatches       : %0d / 10", mismatch_r);

        if ((mismatch_r == 0) && prediction_match_r)
            $display("PASS: all logits and prediction match golden.");
        else
            $display("FAIL: RTL output differs from golden.");

        $finish;
    end

endmodule