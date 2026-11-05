`timescale 1ns/1ps
module tb_cin2;
    reg clk_r=0;
    always #5 clk_r=~clk_r;
    reg rst_n_r=0, start_r=0;
    reg [15:0] input_r[0:97], weight_r[0:249], bias_r[0:4], expected_r[0:44];
    reg [15:0] rd_data_r=0;
    reg rd_valid_r=0;
    wire weight_en_w, bias_en_w;
    wire [15:0] weight_addr_w, bias_addr_w;
    reg [15:0] weight_data_r=0, bias_data_r=0;
    reg weight_valid_r=0, bias_valid_r=0;
    reg [44:0] visited_r=0;
    reg [31:0] errors_r=0, writes_r=0, cycles_r=0, requests_r=0;
    reg [31:0] in_flight_r=0, max_in_flight_r=0;
    wire busy_w,done_w,rd_en_w,wr_en_w,load_w,valid_w,psum_valid_w;
    wire [1:0] kind_w;
    wire [15:0] rd_addr_w,wr_addr_w,wr_data_w;
    wire [1599:0] weights_w;
    wire [399:0] window_w;
    wire [191:0] psum_w;

    //-------------------------------------//
    // Convolution and Physical PEA
    //-------------------------------------//
    Conv_Controller dut (
        .clk_i(clk_r), .rst_n_i(rst_n_r), .start_i(start_r),
        .width_i(6'd7), .height_i(6'd7), .cin_i(16'd2), .cout_i(16'd5),
        .busy_o(busy_w), .done_o(done_w), .rd_en_o(rd_en_w),
         .rd_addr_o(rd_addr_w),
        .rd_data_i(rd_data_r), .rd_valid_i(rd_valid_r),
        .weight_rd_en_o(weight_en_w), .weight_rd_addr_o(weight_addr_w),
        .weight_rd_data_i(weight_data_r), .weight_rd_valid_i(weight_valid_r),
        .bias_rd_en_o(bias_en_w), .bias_rd_addr_o(bias_addr_w),
        .bias_rd_data_i(bias_data_r), .bias_rd_valid_i(bias_valid_r),
        .wr_en_o(wr_en_w), .wr_addr_o(wr_addr_w), .wr_data_o(wr_data_w),
        .pea_weight_load_o(load_w), .pea_weight_o(weights_w),
        .pea_window_o(window_w), .pea_valid_o(valid_w),
        .pea_psum_i(psum_w), .pea_valid_i(psum_valid_w)
    );
    PEA_5x5 u_pea (
        .clk_i(clk_r), .rst_n_i(rst_n_r), .weight_load_i(load_w),
        .weight_i(weights_w), .window_i(window_w), .valid_i(valid_w),
        .psum_o(psum_w), .valid_o(psum_valid_w)
    );

    //-------------------------------------//
    // Fixed-Latency Memory Model and Scoreboard
    //-------------------------------------//
    always @(posedge clk_r) begin
        weight_valid_r <= rst_n_r && weight_en_w;
        bias_valid_r <= rst_n_r && bias_en_w;
        if (weight_en_w) weight_data_r<=weight_r[weight_addr_w];
        if (bias_en_w) bias_data_r<=bias_r[bias_addr_w];
        rd_valid_r <= rst_n_r && rd_en_w;
        if (rst_n_r && rd_en_w) begin
            rd_data_r <= input_r[rd_addr_w];
        end
        if (rst_n_r) begin
            if (load_w && in_flight_r!=0) errors_r=errors_r+1;
            if (psum_valid_w) begin
                if (in_flight_r==0) errors_r=errors_r+1;
                else in_flight_r=in_flight_r-1;
            end
            if (valid_w) begin
                in_flight_r=in_flight_r+1;
                requests_r=requests_r+1;
            end
            if (in_flight_r>max_in_flight_r) max_in_flight_r=in_flight_r;
            if (wr_en_w) begin
                writes_r=writes_r+1;
                if (wr_addr_w>=45) errors_r=errors_r+1;
                else begin
                    if (visited_r[wr_addr_w]) errors_r=errors_r+1;
                    visited_r[wr_addr_w]=1;
                    if (wr_data_w!==expected_r[wr_addr_w]) begin
                        $display("FAIL Cin2 address=%0d actual=%h expected=%h",wr_addr_w,wr_data_w,expected_r[wr_addr_w]);
                        errors_r=errors_r+1;
                    end
                end
            end
        end
    end

    //-------------------------------------//
    // Stimulus and Completion Checks
    //-------------------------------------//
    initial begin
        $readmemh("tests/cin2/input.txt",input_r);
        $readmemh("tests/cin2/weight.txt",weight_r);
        $readmemh("tests/cin2/bias.txt",bias_r);
        $readmemh("tests/cin2/expected.txt",expected_r);
        repeat (4) @(negedge clk_r);
        rst_n_r=1;
        @(negedge clk_r);
        start_r=1;
        @(negedge clk_r);
        start_r=0;
        while (!done_w && cycles_r<10000) begin
            @(negedge clk_r);
            cycles_r=cycles_r+1;
        end
        if (!done_w || writes_r!=45 || visited_r!=={45{1'b1}} ||
            requests_r!=36 || max_in_flight_r<2 || in_flight_r!=0)
            errors_r=errors_r+1;
        if (errors_r==0)
            $display("PASS Cin2: 45 outputs, 36 windows, max_in_flight=%0d cycles=%0d",max_in_flight_r,cycles_r);
        else $display("FAIL Cin2 errors=%0d",errors_r);
        $finish;
    end
endmodule
