`timescale 1ns/1ps
module tb_lenet5_core;
    //-------------------------------------//
    //          Signal Declarations        //
    //-------------------------------------//
    reg clk_r, rst_n_r, wr_valid_r, rd_valid_r;
    reg [22:0] wr_addr_r, rd_addr_r, file_addr_r;
    reg [127:0] wr_data_r, file_data_r, result_r;
    reg [15:0] strb_r, file_strb_r, golden_r [0:9];
    reg [31:0] fd_r, scan_r, index_r, errors_r, rows_r;
    reg [1023:0] stim_path_r, golden_path_r;
    wire [127:0] rd_data_w;


    Lenet5_Core dut (
        .clk_i(clk_r), .rst_n_i(rst_n_r),
        .host_wr_valid_i(wr_valid_r), .host_wr_addr_i(wr_addr_r),
        .host_wr_data_i(wr_data_r), .host_wr_strb_i(strb_r),
        .host_rd_valid_i(rd_valid_r),
        .host_rd_addr_i(rd_addr_r), .host_rd_data_o(rd_data_w)

    );

    //-------------------------------------//
    //          Clock and Timeout          //
    //-------------------------------------//
    initial clk_r=0;
    always #5 clk_r=~clk_r;
    initial begin
        repeat (200000) @(posedge clk_r);
        $display("FAIL: timeout, status=%h",rd_data_w);
        $finish;
    end

    //-------------------------------------//
    //       Host Writes and Inference     //
    //-------------------------------------//
    initial begin
        rst_n_r=0; wr_valid_r=0; rd_valid_r=0;
        wr_addr_r=0; wr_data_r=0; strb_r=0; rd_addr_r=0;
        errors_r=0; rows_r=0;
        if (!$value$plusargs("STIM=%s",stim_path_r)) stim_path_r="C:/SOC/SOC_UIT/LENET5/LENET_5_DMA/train_model/outputs_q88/core_writes.txt";
        if (!$value$plusargs("GOLD=%s",golden_path_r)) golden_path_r="C:/SOC/SOC_UIT/LENET5/LENET_5_DMA/train_model/outputs_q88/golden_logits.hex";
        $readmemh(golden_path_r,golden_r);
        fd_r=$fopen(stim_path_r,"r");
        if (!fd_r) begin $display("FAIL: cannot open stimulus"); $finish; end
        repeat (4) @(negedge clk_r);
        rst_n_r=1;
        scan_r=$fscanf(fd_r,"%h %h %h",file_addr_r,file_strb_r,file_data_r);
        while (scan_r==3) begin
            @(negedge clk_r);
            wr_valid_r=1; wr_addr_r=file_addr_r;
            wr_data_r=file_data_r; strb_r=file_strb_r;
            @(posedge clk_r);
            rows_r=rows_r+1;
            scan_r=$fscanf(fd_r,"%h %h %h",file_addr_r,file_strb_r,file_data_r);
        end
        $fclose(fd_r);
        if (scan_r!==32'hffffffff || rows_r!=5653) begin
            $display("FAIL: malformed or incomplete stimulus, rows=%d",rows_r); $finish;
        end
        // Exactly one rising edge accepts START.
        @(negedge clk_r);
        wr_addr_r=0; wr_data_r=1; strb_r=16'h0001;
        @(posedge clk_r);
        @(negedge clk_r);
        wr_valid_r=0; strb_r=0; rd_addr_r=0; rd_valid_r=1;
        // Status and result reads are combinational. Sample after settling.
        #1;
        while (rd_data_w[1:0] !== 2'b10) begin
            @(negedge clk_r); #1;
        end
        @(negedge clk_r);
        rd_addr_r=23'h000010;
        #1;
        $display("Prediction: class=%d score=%h",rd_data_w[19:16],rd_data_w[15:0]);
        index_r=0;
        while (index_r<10) begin
            @(negedge clk_r);
            rd_addr_r=(index_r<8)?23'h000100:23'h000110;
            #1;
            result_r=rd_data_w;
            if ((^golden_r[index_r] === 1'bx) ||
                result_r[(index_r%8)*16 +: 16] !== golden_r[index_r])
                errors_r=errors_r+1;
            $display("digit %d: RTL=%h golden=%h",index_r,
                     result_r[(index_r%8)*16 +: 16],golden_r[index_r]);
            index_r=index_r+1;
        end
        if (errors_r==0) $display("PASS: all 10 logits match");
        else $display("FAIL: %d mismatches",errors_r);
        $finish;
    end
endmodule

