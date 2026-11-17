vlib work
vlib activehdl

vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../../../../ip_repo/LENET5_FIXED_CNN_IP_1_0/src/ila_0/hdl/verilog" \
"../../../../../../../ip_repo/LENET5_FIXED_CNN_IP_1_0/src/ila_0/sim/ila_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

