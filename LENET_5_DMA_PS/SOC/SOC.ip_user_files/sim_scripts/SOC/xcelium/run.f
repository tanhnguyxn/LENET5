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
  "C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
  "C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \
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
  "../../../../SOC.gen/sources_1/bd/SOC/Simulation/Simulation.srcs/sources_1/ip/ila_0/sim/ila_0.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Adder_Tree_25.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Arbiter.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Banked_RAM_128_16.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Bias_Memory.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Conv_Bank_5x5.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Conv_Controller.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/FC_Controller.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/978a/hdl/LENET5_DMA_IP_v1_0_S00_AXI.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Lenet5_Core.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Lenet5_Engine.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Line_Buffer_5x5.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Line_Buffer_Memory.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/MaxPool2x2_Q16.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/PEA_5x5.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/PE_5x5.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Parallel_Data_Loader.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Partial_Sum_Memory.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Ping_Pong_Memory.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Pool_Controller.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Postprocess_Q16.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/ReLU_Q16.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Sync_RAM_1R1W.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/RTL/Weight_Memory.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/978a/hdl/LENET5_DMA_IP_v1_0.v" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_LENET5_DMA_IP_0_0/sim/SOC_LENET5_DMA_IP_0_0.v" \
-endlib
-makelib xcelium_lib/xlconstant_v1_1_7 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/badb/hdl/xlconstant_v1_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_0/sim/bd_683f_one_0.v" \
-endlib
-makelib xcelium_lib/lib_cdc_v1_0_2 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \
-endlib
-makelib xcelium_lib/proc_sys_reset_v5_0_13 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/8842/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_1/sim/bd_683f_psr_aclk_0.vhd" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/f0b6/hdl/sc_util_v1_0_vl_rfs.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/c012/hdl/sc_switchboard_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_2/sim/bd_683f_arsw_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_3/sim/bd_683f_rsw_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_4/sim/bd_683f_awsw_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_5/sim/bd_683f_wsw_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_6/sim/bd_683f_bsw_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/be1f/hdl/sc_mmu_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_7/sim/bd_683f_s00mmu_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/4fd2/hdl/sc_transaction_regulator_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_8/sim/bd_683f_s00tr_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/637d/hdl/sc_si_converter_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_9/sim/bd_683f_s00sic_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/f38e/hdl/sc_axi2sc_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_10/sim/bd_683f_s00a2s_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/66be/hdl/sc_node_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_11/sim/bd_683f_sarn_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_12/sim/bd_683f_srn_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_13/sim/bd_683f_sawn_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_14/sim/bd_683f_swn_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_15/sim/bd_683f_sbn_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_16/sim/bd_683f_s01mmu_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_17/sim/bd_683f_s01tr_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_18/sim/bd_683f_s01sic_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_19/sim/bd_683f_s01a2s_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_20/sim/bd_683f_sarn_1.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_21/sim/bd_683f_srn_1.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_22/sim/bd_683f_sawn_1.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_23/sim/bd_683f_swn_1.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_24/sim/bd_683f_sbn_1.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/9cc5/hdl/sc_sc2axi_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_25/sim/bd_683f_m00s2a_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_26/sim/bd_683f_m00arn_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_27/sim/bd_683f_m00rn_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_28/sim/bd_683f_m00awn_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_29/sim/bd_683f_m00wn_0.sv" \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_30/sim/bd_683f_m00bn_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/6bba/hdl/sc_exit_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/ip/ip_31/sim/bd_683f_m00e_0.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/bd_0/sim/bd_683f.v" \
-endlib
-makelib xcelium_lib/axi_register_slice_v2_1_27 \
  "../../../../SOC.gen/sources_1/bd/SOC/ipshared/f0b4/hdl/axi_register_slice_v2_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../SOC.gen/sources_1/bd/SOC/ip/SOC_axi_smc_0/sim/SOC_axi_smc_0.v" \
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

