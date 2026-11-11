-makelib xcelium_lib/xilinx_vip -sv \
  "C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
  "C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
  "C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
  "C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
  "C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
  "C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
  "C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
  "C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
  "C:/Xilinx/Vivado/2022.2/data/xilinx_vip/hdl/rst_vip_if.sv" \
-endlib
-makelib xcelium_lib/xpm -sv \
  "C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
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
-endlib
-makelib xcelium_lib/axi_infrastructure_v1_1_0 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/axi_vip_v1_1_13 -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/ffc2/hdl/axi_vip_v1_1_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/zynq_ultra_ps_e_vip_v1_0_13 -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/abef/hdl/zynq_ultra_ps_e_vip_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_zynq_ultra_ps_e_0_0/sim/SOC_zynq_ultra_ps_e_0_0_vip_wrapper.v" \
-endlib
-makelib xcelium_lib/generic_baseblocks_v2_1_0 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/b752/hdl/generic_baseblocks_v2_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/axi_register_slice_v2_1_27 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/f0b4/hdl/axi_register_slice_v2_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/fifo_generator_v13_2_7 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/83df/simulation/fifo_generator_vlog_beh.v" \
-endlib
-makelib xcelium_lib/fifo_generator_v13_2_7 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/83df/hdl/fifo_generator_v13_2_rfs.vhd" \
-endlib
-makelib xcelium_lib/fifo_generator_v13_2_7 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/83df/hdl/fifo_generator_v13_2_rfs.v" \
-endlib
-makelib xcelium_lib/axi_data_fifo_v2_1_26 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/3111/hdl/axi_data_fifo_v2_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/axi_crossbar_v2_1_28 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/c40e/hdl/axi_crossbar_v2_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_xbar_0/sim/SOC_xbar_0.v" \
-endlib
-makelib xcelium_lib/axi_protocol_converter_v2_1_27 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/aeb3/hdl/axi_protocol_converter_v2_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/axi_clock_converter_v2_1_26 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/b8be/hdl/axi_clock_converter_v2_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/blk_mem_gen_v8_4_5 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/25a8/simulation/blk_mem_gen_v8_4.v" \
-endlib
-makelib xcelium_lib/axi_dwidth_converter_v2_1_27 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/4675/hdl/axi_dwidth_converter_v2_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_auto_ds_0/sim/SOC_auto_ds_0.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_auto_pc_0/sim/SOC_auto_pc_0.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_auto_ds_1/sim/SOC_auto_ds_1.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_auto_pc_1/sim/SOC_auto_pc_1.v" \
-endlib
-makelib xcelium_lib/lib_cdc_v1_0_2 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \
-endlib
-makelib xcelium_lib/proc_sys_reset_v5_0_13 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/8842/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_rst_ps8_0_99M_0/sim/SOC_rst_ps8_0_99M_0.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../SOC.gen/sources_1/bd/SOC/sim/SOC.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

