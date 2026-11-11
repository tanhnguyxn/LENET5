vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xilinx_vip
vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/axi_infrastructure_v1_1_0
vlib modelsim_lib/msim/axi_vip_v1_1_13
vlib modelsim_lib/msim/zynq_ultra_ps_e_vip_v1_0_13
vlib modelsim_lib/msim/generic_baseblocks_v2_1_0
vlib modelsim_lib/msim/axi_register_slice_v2_1_27
vlib modelsim_lib/msim/fifo_generator_v13_2_7
vlib modelsim_lib/msim/axi_data_fifo_v2_1_26
vlib modelsim_lib/msim/axi_crossbar_v2_1_28
vlib modelsim_lib/msim/axi_protocol_converter_v2_1_27
vlib modelsim_lib/msim/axi_clock_converter_v2_1_26
vlib modelsim_lib/msim/blk_mem_gen_v8_4_5
vlib modelsim_lib/msim/axi_dwidth_converter_v2_1_27
vlib modelsim_lib/msim/lib_cdc_v1_0_2
vlib modelsim_lib/msim/proc_sys_reset_v5_0_13

vmap xilinx_vip modelsim_lib/msim/xilinx_vip
vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap axi_infrastructure_v1_1_0 modelsim_lib/msim/axi_infrastructure_v1_1_0
vmap axi_vip_v1_1_13 modelsim_lib/msim/axi_vip_v1_1_13
vmap zynq_ultra_ps_e_vip_v1_0_13 modelsim_lib/msim/zynq_ultra_ps_e_vip_v1_0_13
vmap generic_baseblocks_v2_1_0 modelsim_lib/msim/generic_baseblocks_v2_1_0
vmap axi_register_slice_v2_1_27 modelsim_lib/msim/axi_register_slice_v2_1_27
vmap fifo_generator_v13_2_7 modelsim_lib/msim/fifo_generator_v13_2_7
vmap axi_data_fifo_v2_1_26 modelsim_lib/msim/axi_data_fifo_v2_1_26
vmap axi_crossbar_v2_1_28 modelsim_lib/msim/axi_crossbar_v2_1_28
vmap axi_protocol_converter_v2_1_27 modelsim_lib/msim/axi_protocol_converter_v2_1_27
vmap axi_clock_converter_v2_1_26 modelsim_lib/msim/axi_clock_converter_v2_1_26
vmap blk_mem_gen_v8_4_5 modelsim_lib/msim/blk_mem_gen_v8_4_5
vmap axi_dwidth_converter_v2_1_27 modelsim_lib/msim/axi_dwidth_converter_v2_1_27
vmap lib_cdc_v1_0_2 modelsim_lib/msim/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_13 modelsim_lib/msim/proc_sys_reset_v5_0_13

vlog -work xilinx_vip  -incr -mfcu  -sv -L axi_vip_v1_1_13 -L zynq_ultra_ps_e_vip_v1_0_13 -L xilinx_vip "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm  -incr -mfcu  -sv -L axi_vip_v1_1_13 -L zynq_ultra_ps_e_vip_v1_0_13 -L xilinx_vip "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Adder_Tree_25.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Arbiter.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Bias_Memory.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Conv_Bank_5x5.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Conv_Controller.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/FC_Controller.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/hdl/LENET5_FIXED_CNN_IP_v1_0_S00_AXI.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Lenet5_Core.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Lenet5_Engine.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Line_Buffer_5x5.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Line_Buffer_Memory.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/MaxPool2x2_Q16.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/PEA_5x5.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/PE_5x5.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Parallel_Data_Loader.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Partial_Sum_Memory.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Ping_Pong_Memory.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Pool_Controller.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Postprocess_Q16.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/ReLU_Q16.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Sync_RAM_1R1W.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/src/Weight_Memory.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/fdc4/hdl/LENET5_FIXED_CNN_IP_v1_0.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_LENET5_FIXED_CNN_IP_0_0/sim/SOC_LENET5_FIXED_CNN_IP_0_0.v" \

vlog -work axi_infrastructure_v1_1_0  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_vip_v1_1_13  -incr -mfcu  -sv -L axi_vip_v1_1_13 -L zynq_ultra_ps_e_vip_v1_0_13 -L xilinx_vip "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/ffc2/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work zynq_ultra_ps_e_vip_v1_0_13  -incr -mfcu  -sv -L axi_vip_v1_1_13 -L zynq_ultra_ps_e_vip_v1_0_13 -L xilinx_vip "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl/zynq_ultra_ps_e_vip_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_zynq_ultra_ps_e_0_0/sim/SOC_zynq_ultra_ps_e_0_0_vip_wrapper.v" \

vlog -work generic_baseblocks_v2_1_0  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/b752/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_27  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/f0b4/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work fifo_generator_v13_2_7  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/83df/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_7  -93  \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/83df/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_7  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/83df/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work axi_data_fifo_v2_1_26  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/3111/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_crossbar_v2_1_28  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/c40e/hdl/axi_crossbar_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_xbar_0/sim/SOC_xbar_0.v" \

vlog -work axi_protocol_converter_v2_1_27  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/aeb3/hdl/axi_protocol_converter_v2_1_vl_rfs.v" \

vlog -work axi_clock_converter_v2_1_26  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/b8be/hdl/axi_clock_converter_v2_1_vl_rfs.v" \

vlog -work blk_mem_gen_v8_4_5  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/25a8/simulation/blk_mem_gen_v8_4.v" \

vlog -work axi_dwidth_converter_v2_1_27  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/4675/hdl/axi_dwidth_converter_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_auto_ds_0/sim/SOC_auto_ds_0.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_auto_pc_0/sim/SOC_auto_pc_0.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_auto_ds_1/sim/SOC_auto_ds_1.v" \
"../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_auto_pc_1/sim/SOC_auto_pc_1.v" \

vcom -work lib_cdc_v1_0_2  -93  \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_13  -93  \
"../../../../SOC.gen/sources_1/bd/SOC/ipshared/8842/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib  -93  \
"../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_rst_ps8_0_99M_0/sim/SOC_rst_ps8_0_99M_0.vhd" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl" "+incdir+../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl" "+incdir+C:/Xilinx/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../SOC.gen/sources_1/bd/SOC/sim/SOC.v" \

vlog -work xil_defaultlib \
"glbl.v"

