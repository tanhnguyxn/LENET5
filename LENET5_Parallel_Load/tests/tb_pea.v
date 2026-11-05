`timescale 1ns/1ps
module tb_pea;
reg clk_r = 0;
always #5 clk_r = ~clk_r;
reg rst_n_r = 0, load_r = 0, valid_r = 0;
reg [1599:0] weights_r = 0;
reg [399:0] window_r = 0;
wire [191:0] sums_w;
wire valid_w;
reg [15:0] weights_mem_r[0:99], inputs_mem_r[0:199];
reg [47:0] expected_r[0:31];
reg [31:0] i_r, j_r, k_r, received_r = 0, errors_r = 0;
reg signed [47:0] post_sum_r = 0;
reg signed [15:0] post_bias_r = 0;
reg relu_r = 0;
wire signed [15:0] post_data_w;
PEA_5x5 dut(.clk_i(clk_r),
    .rst_n_i                (rst_n_r),
    .weight_load_i          (load_r),
    .weight_i               (weights_r),
    .window_i               (window_r),
    .valid_i                (valid_r),
    .psum_o                 (sums_w),
    .valid_o                (valid_w)
);
    Postprocess_Q16 post(.psum_i(post_sum_r),
        .bias_i                 (post_bias_r),
        .relu_enable_i          (relu_r),
        .data_o                 (post_data_w)
    );
    always @(negedge clk_r) if (valid_w) begin
        if (received_r >= 8) errors_r = errors_r+1;
        else begin
            k_r = 0;
            repeat (4) begin
                if (sums_w[k_r*48 +: 48] !== expected_r[received_r*4+k_r]) begin
                    $display("FAIL PEA transaction=%d bank=%d got=%h expected=%h", received_r, k_r,
                        sums_w[k_r*48 +: 48], expected_r[received_r*4+k_r]);
                    errors_r = errors_r+1;
                end
                k_r = k_r+1;
            end
        end
        received_r = received_r+1;
    end
    initial begin
        $readmemh("tests/pea/weights.txt", weights_mem_r);
        $readmemh("tests/pea/inputs.txt", inputs_mem_r);
        $readmemh("tests/pea/expected.txt", expected_r);
        repeat (4) @(negedge clk_r);
        rst_n_r = 1;
        begin
            j_r = 0;
            repeat (100) begin
                weights_r[j_r*16 +: 16] = weights_mem_r[j_r];
                j_r = j_r+1;
            end
        end
        load_r = 1;
        @(negedge clk_r);
        load_r = 0;
        begin
            i_r = 0;
            repeat (8) begin
                begin
                    j_r = 0;
                    repeat (25) begin
                        window_r[j_r*16 +: 16] = inputs_mem_r[i_r*25+j_r];
                        j_r = j_r+1;
                    end
                end
                valid_r = 1;
                @(negedge clk_r);
                if (i_r == 2 || i_r == 5) begin
                    valid_r = 0;
                    repeat (2) @(negedge clk_r);
                end
                i_r = i_r+1;
            end
        end
        valid_r = 0;
        repeat (10) @(negedge clk_r);
        if (received_r != 8) errors_r = errors_r+1;
        post_sum_r = 48'sd1000000;
        #1;
        if (post_data_w !== 16'h7FFF) errors_r = errors_r+1;
        post_sum_r = -48'sd1000000;
        #1;
        if (post_data_w !== 16'h8000) errors_r = errors_r+1;
        relu_r = 1;
        #1;
        if (post_data_w !== 16'd0) errors_r = errors_r+1;
        relu_r = 0;
        post_sum_r = 48'sd32770;
        post_bias_r = -16'sd10;
        #1;
        if (post_data_w !== 16'd32760) errors_r = errors_r+1;
        if (errors_r == 0) $display("PASS PEA: signed products, pipeline bubbles, wide sums and postprocess");
        else $display("FAIL PEA errors=%d", errors_r);
        $finish;
    end
endmodule
