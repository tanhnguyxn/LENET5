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
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/axi_vip_v1_1_13 -sv \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/ffc2/hdl/axi_vip_v1_1_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/zynq_ultra_ps_e_vip_v1_0_13 -sv \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/abef/hdl/zynq_ultra_ps_e_vip_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/SoC/ip/SoC_zynq_ultra_ps_e_0_0/sim/SoC_zynq_ultra_ps_e_0_0_vip_wrapper.v" \
  "../../../bd/SoC/Simulation/Simulation.srcs/sources_1/ip/ila_0/sim/ila_0.v" \
  "../../../bd/SoC/RTL/Adder_Tree_25.v" \
  "../../../bd/SoC/RTL/Arbiter.v" \
  "../../../bd/SoC/RTL/Banked_RAM_128_16.v" \
  "../../../bd/SoC/RTL/Bias_Memory.v" \
  "../../../bd/SoC/RTL/Conv_Bank_5x5.v" \
  "../../../bd/SoC/RTL/Conv_Controller.v" \
  "../../../bd/SoC/RTL/FC_Controller.v" \
  "../../../bd/SoC/ipshared/978a/hdl/LENET5_DMA_IP_v1_0_S00_AXI.v" \
  "../../../bd/SoC/RTL/Lenet5_Core.v" \
  "../../../bd/SoC/RTL/Lenet5_Engine.v" \
  "../../../bd/SoC/RTL/Line_Buffer_5x5.v" \
  "../../../bd/SoC/RTL/Line_Buffer_Memory.v" \
  "../../../bd/SoC/RTL/MaxPool2x2_Q16.v" \
  "../../../bd/SoC/RTL/PEA_5x5.v" \
  "../../../bd/SoC/RTL/PE_5x5.v" \
  "../../../bd/SoC/RTL/Parallel_Data_Loader.v" \
  "../../../bd/SoC/RTL/Partial_Sum_Memory.v" \
  "../../../bd/SoC/RTL/Ping_Pong_Memory.v" \
  "../../../bd/SoC/RTL/Pool_Controller.v" \
  "../../../bd/SoC/RTL/Postprocess_Q16.v" \
  "../../../bd/SoC/RTL/ReLU_Q16.v" \
  "../../../bd/SoC/RTL/Sync_RAM_1R1W.v" \
  "../../../bd/SoC/RTL/Weight_Memory.v" \
  "../../../bd/SoC/ipshared/978a/hdl/LENET5_DMA_IP_v1_0.v" \
  "../../../bd/SoC/ip/SoC_LENET5_DMA_IP_0_0/sim/SoC_LENET5_DMA_IP_0_0.v" \
-endlib
-makelib xcelium_lib/xlconstant_v1_1_7 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/badb/hdl/xlconstant_v1_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_0/sim/bd_d7be_one_0.v" \
-endlib
-makelib xcelium_lib/lib_cdc_v1_0_2 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \
-endlib
-makelib xcelium_lib/proc_sys_reset_v5_0_13 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/8842/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_1/sim/bd_d7be_psr_aclk_0.vhd" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/f0b6/hdl/sc_util_v1_0_vl_rfs.sv" \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/c012/hdl/sc_switchboard_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_2/sim/bd_d7be_arsw_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_3/sim/bd_d7be_rsw_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_4/sim/bd_d7be_awsw_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_5/sim/bd_d7be_wsw_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_6/sim/bd_d7be_bsw_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/be1f/hdl/sc_mmu_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_7/sim/bd_d7be_s00mmu_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/4fd2/hdl/sc_transaction_regulator_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_8/sim/bd_d7be_s00tr_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/637d/hdl/sc_si_converter_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_9/sim/bd_d7be_s00sic_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/f38e/hdl/sc_axi2sc_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_10/sim/bd_d7be_s00a2s_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/66be/hdl/sc_node_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_11/sim/bd_d7be_sarn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_12/sim/bd_d7be_srn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_13/sim/bd_d7be_sawn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_14/sim/bd_d7be_swn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_15/sim/bd_d7be_sbn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_16/sim/bd_d7be_s01mmu_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_17/sim/bd_d7be_s01tr_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_18/sim/bd_d7be_s01sic_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_19/sim/bd_d7be_s01a2s_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_20/sim/bd_d7be_sarn_1.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_21/sim/bd_d7be_srn_1.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_22/sim/bd_d7be_sawn_1.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_23/sim/bd_d7be_swn_1.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_24/sim/bd_d7be_sbn_1.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_25/sim/bd_d7be_s02mmu_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_26/sim/bd_d7be_s02tr_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_27/sim/bd_d7be_s02sic_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_28/sim/bd_d7be_s02a2s_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_29/sim/bd_d7be_sarn_2.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_30/sim/bd_d7be_srn_2.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_31/sim/bd_d7be_sawn_2.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_32/sim/bd_d7be_swn_2.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_33/sim/bd_d7be_sbn_2.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/9cc5/hdl/sc_sc2axi_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_34/sim/bd_d7be_m00s2a_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_35/sim/bd_d7be_m00arn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_36/sim/bd_d7be_m00rn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_37/sim/bd_d7be_m00awn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_38/sim/bd_d7be_m00wn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_39/sim/bd_d7be_m00bn_0.sv" \
-endlib
-makelib xcelium_lib/smartconnect_v1_0 -sv \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/6bba/hdl/sc_exit_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_40/sim/bd_d7be_m00e_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_41/sim/bd_d7be_m01s2a_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_42/sim/bd_d7be_m01arn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_43/sim/bd_d7be_m01rn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_44/sim/bd_d7be_m01awn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_45/sim/bd_d7be_m01wn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_46/sim/bd_d7be_m01bn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_47/sim/bd_d7be_m01e_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_48/sim/bd_d7be_m02s2a_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_49/sim/bd_d7be_m02arn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_50/sim/bd_d7be_m02rn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_51/sim/bd_d7be_m02awn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_52/sim/bd_d7be_m02wn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_53/sim/bd_d7be_m02bn_0.sv" \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/ip/ip_54/sim/bd_d7be_m02e_0.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/SoC/ip/SoC_axi_smc_0/bd_0/sim/bd_d7be.v" \
-endlib
-makelib xcelium_lib/axi_register_slice_v2_1_27 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/f0b4/hdl/axi_register_slice_v2_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/SoC/ip/SoC_axi_smc_0/sim/SoC_axi_smc_0.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/SoC/ip/SoC_rst_ps8_0_99M_0/sim/SoC_rst_ps8_0_99M_0.vhd" \
-endlib
-makelib xcelium_lib/lib_pkg_v1_0_2 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/0513/hdl/lib_pkg_v1_0_rfs.vhd" \
-endlib
-makelib xcelium_lib/lib_srl_fifo_v1_0_2 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/51ce/hdl/lib_srl_fifo_v1_0_rfs.vhd" \
-endlib
-makelib xcelium_lib/fifo_generator_v13_2_7 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/83df/simulation/fifo_generator_vlog_beh.v" \
-endlib
-makelib xcelium_lib/fifo_generator_v13_2_7 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/83df/hdl/fifo_generator_v13_2_rfs.vhd" \
-endlib
-makelib xcelium_lib/fifo_generator_v13_2_7 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/83df/hdl/fifo_generator_v13_2_rfs.v" \
-endlib
-makelib xcelium_lib/lib_fifo_v1_0_16 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/6c82/hdl/lib_fifo_v1_0_rfs.vhd" \
-endlib
-makelib xcelium_lib/axi_datamover_v5_1_29 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/2237/hdl/axi_datamover_v5_1_vh_rfs.vhd" \
-endlib
-makelib xcelium_lib/axi_sg_v4_1_15 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/751a/hdl/axi_sg_v4_1_rfs.vhd" \
-endlib
-makelib xcelium_lib/axi_cdma_v4_1_27 \
  "../../../../SOC.gen/sources_1/bd/SoC/ipshared/6590/hdl/axi_cdma_v4_1_vh_rfs.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/SoC/ip/SoC_axi_cdma_0_0/sim/SoC_axi_cdma_0_0.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/SoC/sim/SoC.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

