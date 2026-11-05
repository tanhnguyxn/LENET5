`timescale 1ns/1ps
module tb_loader;
    reg clk_r=0;
    always #5 clk_r=~clk_r;
    reg rst_n_r=0, start_r=0, bias_enable_r=1;
    reg [15:0] group_r=4, outputs_r=7, base_r=123, stride_r=41, input_base_r=50;
    reg [4:0] taps_r=6;
    wire done_w, xe_w, we_w, be_w;
    wire [15:0] xa_w, wa_w, ba_w;
    reg [15:0] xd_r=0, wd_r=0, bd_r=0;
    reg xv_r=0, wv_r=0, bv_r=0;
    wire [1599:0] weights_w;
    wire [399:0] inputs_w;
    wire [63:0] biases_w;
    reg [31:0] errors_r=0, cycles_r=0, index_r=0, bank_r=0, tap_r=0;
    reg [31:0] wc_r=0, xc_r=0, bc_r=0, overlap_r=0;
    reg [15:0] expected_r;
    Parallel_Data_Loader dut (
        .clk_i(clk_r), .rst_n_i(rst_n_r), .start_i(start_r),
        .input_enable_i(1'b1), .bias_enable_i(bias_enable_r),
        .group_i(group_r), .outputs_i(outputs_r), .weight_base_i(base_r),
        .weight_stride_i(stride_r), .input_base_i(input_base_r), .taps_i(taps_r),
        .done_o(done_w), .input_rd_en_o(xe_w), .input_rd_addr_o(xa_w),
        .input_rd_data_i(xd_r), .input_rd_valid_i(xv_r),
        .weight_rd_en_o(we_w), .weight_rd_addr_o(wa_w),
        .weight_rd_data_i(wd_r), .weight_rd_valid_i(wv_r),
        .bias_rd_en_o(be_w), .bias_rd_addr_o(ba_w),
        .bias_rd_data_i(bd_r), .bias_rd_valid_i(bv_r),
        .weights_o(weights_w), .inputs_o(inputs_w), .biases_o(biases_w)
    );
    always @(posedge clk_r) begin
        xv_r<=rst_n_r && xe_w; wv_r<=rst_n_r && we_w; bv_r<=rst_n_r && be_w;
        if (xe_w) begin xd_r<=xa_w+16'h1000; xc_r=xc_r+1; end
        if (we_w) begin wd_r<=wa_w+16'h8000; wc_r=wc_r+1; end
        if (be_w) begin bd_r<=ba_w+16'h2000; bc_r=bc_r+1; end
        if (xe_w && we_w && be_w) overlap_r=overlap_r+1;
    end
    task run_load;
    begin
        @(negedge clk_r); start_r=1;
        @(negedge clk_r); start_r=0; cycles_r=0;
        while (!done_w && cycles_r<200) begin
            @(negedge clk_r); cycles_r=cycles_r+1;
        end
        if (!done_w) errors_r=errors_r+1;
        index_r=0; bank_r=0; tap_r=0;
        while (index_r<100) begin
            expected_r=0;
            if (group_r+bank_r<outputs_r && tap_r<taps_r)
                expected_r=base_r+bank_r*stride_r+tap_r+16'h8000;
            if (weights_w[index_r*16 +: 16]!==expected_r) errors_r=errors_r+1;
            if (tap_r==24) begin tap_r=0; bank_r=bank_r+1; end
            else tap_r=tap_r+1;
            index_r=index_r+1;
        end
        index_r=0;
        while (index_r<25) begin
            expected_r=index_r<taps_r ? input_base_r+index_r+16'h1000 : 0;
            if (inputs_w[index_r*16 +: 16]!==expected_r) errors_r=errors_r+1;
            index_r=index_r+1;
        end
    end
    endtask
    initial begin
        repeat (3) @(negedge clk_r); rst_n_r=1;
        run_load;
        if (wc_r!=18 || xc_r!=6 || bc_r!=3 || overlap_r!=3) errors_r=errors_r+1;
        if (biases_w!==64'h0000200620052004) errors_r=errors_r+1;
        // Next chunk retains bias but replaces all input/weight slots.
        bias_enable_r=0; base_r=900; input_base_r=100; taps_r=25;
        run_load;
        if (wc_r!=93 || xc_r!=31 || bc_r!=3) errors_r=errors_r+1;
        if (biases_w!==64'h0000200620052004) errors_r=errors_r+1;
        // Abort an active transfer, reset, then load a new group.
        @(negedge clk_r); start_r=1;
        @(negedge clk_r); start_r=0;
        repeat (8) @(negedge clk_r);
        rst_n_r=0;
        repeat (2) @(negedge clk_r);
        rst_n_r=1; group_r=0; outputs_r=4; base_r=0; taps_r=1; bias_enable_r=1;
        run_load;
        if (biases_w!==64'h2003200220012000) errors_r=errors_r+1;
        if (errors_r==0) $display("PASS loader: parallel reads, address tags, tails, retained bias, reset recovery");
        else $display("FAIL loader errors=%0d",errors_r);
        $finish;
    end
endmodule
