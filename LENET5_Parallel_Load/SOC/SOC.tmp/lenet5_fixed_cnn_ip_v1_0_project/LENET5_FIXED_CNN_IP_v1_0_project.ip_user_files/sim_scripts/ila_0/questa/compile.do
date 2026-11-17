vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../../../../ip_repo/LENET5_FIXED_CNN_IP_1_0/src/ila_0/hdl/verilog" \
"../../../../../../../ip_repo/LENET5_FIXED_CNN_IP_1_0/src/ila_0/sim/ila_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

