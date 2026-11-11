`timescale 1ns/1ps
module tb_tails;
    reg [31:0] in_flight_r=0, max_in_flight_r=0, burst_r=0, max_burst_r=0;

// Change this parameter only when moving the vector directory.
parameter DATA_ROOT = "C:/SOC/SOC_UIT/LENET5/LENET_5_Version1/LENET5/LENET5_Parallel_Load/tests";
reg clk_r = 0;
always #5 clk_r = ~clk_r;
reg rst_n_r = 0;
reg [19:0] wr_addr_r = 0, rd_addr_r = 0;
reg [63:0] wr_data_r = 0;
reg wr_valid_r = 0, rd_valid_r = 0;
wire [63:0] rd_data_w;
reg [31:0] index_r, cycles_r, errors_r, run_r, stage_index_r;
reg [31:0] writes_r[0:6];
reg [31:0] pea_requests_r[0:6];
reg checking_r = 0;
reg [15:0] input_r[0:783];
Lenet5_Core #(
    .CONV1_CH               (5),
    .CONV2_CH               (6),
    .FC1_NEURONS            (27),
    .FC2_NEURONS            (26)) dut (
    .clk_i                  (clk_r),
    .rst_n_i                (rst_n_r),
    .host_wr_addr_i         (wr_addr_r),
    .host_wr_data_i         (wr_data_r),
    .host_wr_valid_i        (wr_valid_r),
    .host_rd_addr_i         (rd_addr_r),
    .host_rd_valid_i        (rd_valid_r),
    .host_rd_data_o         (rd_data_w)
);
    task host_write;
    input [19:0] address_i;
    input [15:0] data_i;
    begin
        @(negedge clk_r);
        wr_addr_r = address_i;
        wr_data_r = {48'd0, data_i};
        wr_valid_r = 1;
        @(negedge clk_r);
        wr_valid_r = 0;
    end
    endtask
    task host_read;
    input [19:0] address_i;
    begin
        @(negedge clk_r);
        rd_addr_r = address_i;
        rd_valid_r = 1;
        @(negedge clk_r);
        rd_valid_r = 0;
    end
    endtask
    reg [15:0] conv1_w_r[0:124], conv1_b_r[0:4];
    reg [15:0] conv2_w_r[0:749], conv2_b_r[0:5];
    reg [15:0] fc1_w_r[0:2591], fc1_b_r[0:26];
    reg [15:0] fc2_w_r[0:701], fc2_b_r[0:25];
    reg [15:0] fc3_w_r[0:259], fc3_b_r[0:9];
    reg [15:0] expected0_r[0:2879];
    reg [2879:0] visited0_r;
    reg [15:0] expected1_r[0:719];
    reg [719:0] visited1_r;
    reg [15:0] expected2_r[0:383];
    reg [383:0] visited2_r;
    reg [15:0] expected3_r[0:95];
    reg [95:0] visited3_r;
    reg [15:0] expected4_r[0:26];
    reg [26:0] visited4_r;
    reg [15:0] expected5_r[0:25];
    reg [25:0] visited5_r;
    reg [15:0] expected6_r[0:9];
    reg [9:0] visited6_r;
    // Check every intermediate write while it occurs, before RAM reuse.
    always @(posedge clk_r) begin
        if (checking_r && dut.u_engine.u_pea.valid_i)
        pea_requests_r[dut.u_engine.stage_r] = pea_requests_r[dut.u_engine.stage_r]+1;
        if (checking_r && dut.u_engine.wr_en_w) begin
            writes_r[dut.u_engine.stage_r] = writes_r[dut.u_engine.stage_r]+1;
            case (dut.u_engine.stage_r)
                0: begin
                    if (dut.u_engine.wr_addr_w >= 2880) errors_r = errors_r+1;
                    else begin
                        if (visited0_r[dut.u_engine.wr_addr_w]) errors_r = errors_r+1;
                        visited0_r[dut.u_engine.wr_addr_w] = 1;
                        if (dut.u_engine.wr_data_w !== expected0_r[dut.u_engine.wr_addr_w]) begin
                            if (errors_r<8) $display("FAIL stage 0 address=%d got=%h expected=%h", dut.u_engine.wr_addr_w,
                                dut.u_engine.wr_data_w, expected0_r[dut.u_engine.wr_addr_w]);
                            errors_r = errors_r+1;
                        end
                    end
                end
                1: begin
                    if (dut.u_engine.wr_addr_w >= 720) errors_r = errors_r+1;
                    else begin
                        if (visited1_r[dut.u_engine.wr_addr_w]) errors_r = errors_r+1;
                        visited1_r[dut.u_engine.wr_addr_w] = 1;
                        if (dut.u_engine.wr_data_w !== expected1_r[dut.u_engine.wr_addr_w]) begin
                            if (errors_r<8) $display("FAIL stage 1 address=%d got=%h expected=%h", dut.u_engine.wr_addr_w,
                                dut.u_engine.wr_data_w, expected1_r[dut.u_engine.wr_addr_w]);
                            errors_r = errors_r+1;
                        end
                    end
                end
                2: begin
                    if (dut.u_engine.wr_addr_w >= 384) errors_r = errors_r+1;
                    else begin
                        if (visited2_r[dut.u_engine.wr_addr_w]) errors_r = errors_r+1;
                        visited2_r[dut.u_engine.wr_addr_w] = 1;
                        if (dut.u_engine.wr_data_w !== expected2_r[dut.u_engine.wr_addr_w]) begin
                            if (errors_r<8) $display("FAIL stage 2 address=%d got=%h expected=%h", dut.u_engine.wr_addr_w,
                                dut.u_engine.wr_data_w, expected2_r[dut.u_engine.wr_addr_w]);
                            errors_r = errors_r+1;
                        end
                    end
                end
                3: begin
                    if (dut.u_engine.wr_addr_w >= 96) errors_r = errors_r+1;
                    else begin
                        if (visited3_r[dut.u_engine.wr_addr_w]) errors_r = errors_r+1;
                        visited3_r[dut.u_engine.wr_addr_w] = 1;
                        if (dut.u_engine.wr_data_w !== expected3_r[dut.u_engine.wr_addr_w]) begin
                            if (errors_r<8) $display("FAIL stage 3 address=%d got=%h expected=%h", dut.u_engine.wr_addr_w,
                                dut.u_engine.wr_data_w, expected3_r[dut.u_engine.wr_addr_w]);
                            errors_r = errors_r+1;
                        end
                    end
                end
                4: begin
                    if (dut.u_engine.wr_addr_w >= 27) errors_r = errors_r+1;
                    else begin
                        if (visited4_r[dut.u_engine.wr_addr_w]) errors_r = errors_r+1;
                        visited4_r[dut.u_engine.wr_addr_w] = 1;
                        if (dut.u_engine.wr_data_w !== expected4_r[dut.u_engine.wr_addr_w]) begin
                            if (errors_r<8) $display("FAIL stage 4 address=%d got=%h expected=%h", dut.u_engine.wr_addr_w,
                                dut.u_engine.wr_data_w, expected4_r[dut.u_engine.wr_addr_w]);
                            errors_r = errors_r+1;
                        end
                    end
                end
                5: begin
                    if (dut.u_engine.wr_addr_w >= 26) errors_r = errors_r+1;
                    else begin
                        if (visited5_r[dut.u_engine.wr_addr_w]) errors_r = errors_r+1;
                        visited5_r[dut.u_engine.wr_addr_w] = 1;
                        if (dut.u_engine.wr_data_w !== expected5_r[dut.u_engine.wr_addr_w]) begin
                            if (errors_r<8) $display("FAIL stage 5 address=%d got=%h expected=%h", dut.u_engine.wr_addr_w,
                                dut.u_engine.wr_data_w, expected5_r[dut.u_engine.wr_addr_w]);
                            errors_r = errors_r+1;
                        end
                    end
                end
                6: begin
                    if (dut.u_engine.wr_addr_w >= 10) errors_r = errors_r+1;
                    else begin
                        if (visited6_r[dut.u_engine.wr_addr_w]) errors_r = errors_r+1;
                        visited6_r[dut.u_engine.wr_addr_w] = 1;
                        if (dut.u_engine.wr_data_w !== expected6_r[dut.u_engine.wr_addr_w]) begin
                            if (errors_r<8) $display("FAIL stage 6 address=%d got=%h expected=%h", dut.u_engine.wr_addr_w,
                                dut.u_engine.wr_data_w, expected6_r[dut.u_engine.wr_addr_w]);
                            errors_r = errors_r+1;
                        end
                    end
                end
                default: errors_r = errors_r+1;
            endcase
        end
    end
    initial begin
        errors_r = 0;
        cycles_r = 0;
        $readmemh({DATA_ROOT, "/tails/conv1_w.txt"}, conv1_w_r);
        $readmemh({DATA_ROOT, "/tails/conv1_b.txt"}, conv1_b_r);
        $readmemh({DATA_ROOT, "/tails/conv2_w.txt"}, conv2_w_r);
        $readmemh({DATA_ROOT, "/tails/conv2_b.txt"}, conv2_b_r);
        $readmemh({DATA_ROOT, "/tails/fc1_w.txt"}, fc1_w_r);
        $readmemh({DATA_ROOT, "/tails/fc1_b.txt"}, fc1_b_r);
        $readmemh({DATA_ROOT, "/tails/fc2_w.txt"}, fc2_w_r);
        $readmemh({DATA_ROOT, "/tails/fc2_b.txt"}, fc2_b_r);
        $readmemh({DATA_ROOT, "/tails/fc3_w.txt"}, fc3_w_r);
        $readmemh({DATA_ROOT, "/tails/fc3_b.txt"}, fc3_b_r);
        repeat (4) @(negedge clk_r);
        rst_n_r = 1;
        begin
            index_r = 0;
            repeat (125) begin
                host_write(20'h20000+index_r, conv1_w_r[index_r]);
                index_r = index_r+1;
            end
        end
        begin
            index_r = 0;
            repeat (5) begin
                host_write(20'h70000+index_r, conv1_b_r[index_r]);
                index_r = index_r+1;
            end
        end
        begin
            index_r = 0;
            repeat (750) begin
                host_write(20'h30000+index_r, conv2_w_r[index_r]);
                index_r = index_r+1;
            end
        end
        begin
            index_r = 0;
            repeat (6) begin
                host_write(20'h72000+index_r, conv2_b_r[index_r]);
                index_r = index_r+1;
            end
        end
        begin
            index_r = 0;
            repeat (2592) begin
                host_write(20'h40000+index_r, fc1_w_r[index_r]);
                index_r = index_r+1;
            end
        end
        begin
            index_r = 0;
            repeat (27) begin
                host_write(20'h74000+index_r, fc1_b_r[index_r]);
                index_r = index_r+1;
            end
        end
        begin
            index_r = 0;
            repeat (702) begin
                host_write(20'h50000+index_r, fc2_w_r[index_r]);
                index_r = index_r+1;
            end
        end
        begin
            index_r = 0;
            repeat (26) begin
                host_write(20'h76000+index_r, fc2_b_r[index_r]);
                index_r = index_r+1;
            end
        end
        begin
            index_r = 0;
            repeat (260) begin
                host_write(20'h60000+index_r, fc3_w_r[index_r]);
                index_r = index_r+1;
            end
        end
        begin
            index_r = 0;
            repeat (10) begin
                host_write(20'h78000+index_r, fc3_b_r[index_r]);
                index_r = index_r+1;
            end
        end
        begin
            run_r = 0;
            repeat (2) begin
                begin
                    stage_index_r = 0;
                    repeat (7) begin
                        writes_r[stage_index_r] = 0;
                        pea_requests_r[stage_index_r] = 0;
                        stage_index_r = stage_index_r+1;
                    end
                end
                visited0_r = 0;
                visited1_r = 0;
                visited2_r = 0;
                visited3_r = 0;
                visited4_r = 0;
                visited5_r = 0;
                visited6_r = 0;
                if (run_r == 0) begin
                    $readmemh({DATA_ROOT, "/tails/input0.txt"}, input_r);
                    $readmemh({DATA_ROOT, "/tails/run0_stage0.txt"}, expected0_r);
                    $readmemh({DATA_ROOT, "/tails/run0_stage1.txt"}, expected1_r);
                    $readmemh({DATA_ROOT, "/tails/run0_stage2.txt"}, expected2_r);
                    $readmemh({DATA_ROOT, "/tails/run0_stage3.txt"}, expected3_r);
                    $readmemh({DATA_ROOT, "/tails/run0_stage4.txt"}, expected4_r);
                    $readmemh({DATA_ROOT, "/tails/run0_stage5.txt"}, expected5_r);
                    $readmemh({DATA_ROOT, "/tails/run0_stage6.txt"}, expected6_r);
                end
                else begin
                    $readmemh({DATA_ROOT, "/tails/input1.txt"}, input_r);
                    $readmemh({DATA_ROOT, "/tails/run1_stage0.txt"}, expected0_r);
                    $readmemh({DATA_ROOT, "/tails/run1_stage1.txt"}, expected1_r);
                    $readmemh({DATA_ROOT, "/tails/run1_stage2.txt"}, expected2_r);
                    $readmemh({DATA_ROOT, "/tails/run1_stage3.txt"}, expected3_r);
                    $readmemh({DATA_ROOT, "/tails/run1_stage4.txt"}, expected4_r);
                    $readmemh({DATA_ROOT, "/tails/run1_stage5.txt"}, expected5_r);
                    $readmemh({DATA_ROOT, "/tails/run1_stage6.txt"}, expected6_r);
                end
    // Ping-pong RAM is reused; reload the image for each inference.
                begin
                    index_r = 0;
                    repeat (784) begin
                        host_write(20'h10000+index_r, input_r[index_r]);
                        index_r = index_r+1;
                    end
                end
                max_in_flight_r=0;
                max_burst_r=0;
                in_flight_r=0;
                checking_r = 1;
                host_write(20'h00000, 16'd1);
                repeat (3) @(negedge clk_r);
                if (!dut.busy_w || dut.done_w) errors_r = errors_r+1;
                host_write(20'h10000, 16'h7FFF);
                cycles_r = 0;
                while (!dut.done_w && cycles_r<2000000) begin
                    @(negedge clk_r);
                    cycles_r = cycles_r+1;
                end
                checking_r = 0;
                if (max_in_flight_r<2 || max_burst_r<24 || in_flight_r!=0) begin
                    $display("FAIL missing real pipeline overlap");
                    errors_r=errors_r+1;
                end
                if (pea_requests_r[0]!=1152 || pea_requests_r[2]!=640) begin
                    $display("FAIL incorrect convolution request count");
                    errors_r=errors_r+1;
                end
                $display("Pipeline max_in_flight=%0d max_consecutive_windows=%0d",max_in_flight_r,max_burst_r);
                if (cycles_r >= 2000000) begin
                    $display("FAIL TIMEOUT");
                    $finish;
                end
                if (writes_r[0] != 2880 || visited0_r !== {2880{1'b1}}) errors_r = errors_r+1;
                if (pea_requests_r[0] == 0) errors_r = errors_r+1;
                if (writes_r[1] != 720 || visited1_r !== {720{1'b1}}) errors_r = errors_r+1;
                if (writes_r[2] != 384 || visited2_r !== {384{1'b1}}) errors_r = errors_r+1;
                if (pea_requests_r[2] == 0) errors_r = errors_r+1;
                if (writes_r[3] != 96 || visited3_r !== {96{1'b1}}) errors_r = errors_r+1;
                if (writes_r[4] != 27 || visited4_r !== {27{1'b1}}) errors_r = errors_r+1;
                if (pea_requests_r[4] == 0) errors_r = errors_r+1;
                if (writes_r[5] != 26 || visited5_r !== {26{1'b1}}) errors_r = errors_r+1;
                if (pea_requests_r[5] == 0) errors_r = errors_r+1;
                if (writes_r[6] != 10 || visited6_r !== {10{1'b1}}) errors_r = errors_r+1;
                if (pea_requests_r[6] == 0) errors_r = errors_r+1;
    // Deliberate maximum tie must select the first class.
                if (dut.pred_class_w !== 4'd0 || dut.pred_score_w !== 16'h7FFF) errors_r = errors_r+1;
                begin
                    index_r = 0;
                    repeat (10) begin
                        host_read(20'h90000+index_r);
                        if (rd_data_w !== {{48{expected6_r[index_r][15]}}, expected6_r[index_r]}) errors_r = errors_r+1;
                        index_r = index_r+1;
                    end
                end
                host_read(20'h00000);
                if (rd_data_w[1:0] !== 2'b10) errors_r = errors_r+1;
                repeat (4) @(negedge clk_r);
                if (!dut.done_w) errors_r = errors_r+1;
                $display("Completed run=%d cycles=%d errors=%d", run_r, cycles_r, errors_r);
                run_r = run_r+1;
            end
        end
        if (errors_r == 0) $display("PASS tails: every intermediate value, shared PEA, two images");
        else $display("FAIL total errors=%d", errors_r);
        $finish;
    end

    //-------------------------------------//
    // Streaming Pipeline Coverage
    //-------------------------------------//
    always @(posedge clk_r) begin
        if (!rst_n_r) begin
            in_flight_r = 0;
            max_in_flight_r = 0;
            burst_r = 0;
            max_burst_r = 0;
        end else if (checking_r && dut.u_engine.conv_active_w) begin
            if (dut.u_engine.u_pea.weight_load_i && in_flight_r!=0) begin
                $display("FAIL weight changed with convolution work in flight");
                errors_r = errors_r+1;
            end
            if (dut.u_engine.pea_valid_w) begin
                if (in_flight_r==0) begin
                    $display("FAIL unexpected PEA response");
                    errors_r = errors_r+1;
                end else in_flight_r = in_flight_r-1;
            end
            if (dut.u_engine.u_pea.valid_i) begin
                in_flight_r = in_flight_r+1;
                burst_r = burst_r+1;
            end else burst_r = 0;
            if (in_flight_r>max_in_flight_r) max_in_flight_r=in_flight_r;
            if (burst_r>max_burst_r) max_burst_r=burst_r;
        end
    end
endmodule
