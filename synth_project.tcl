open_project RTLBoriSoC.xpr
add_files RTLBoriSoC.srcs/sources_1/new/adder.vhd
add_files RTLBoriSoC.srcs/sources_1/new/ALUdp.vhd
add_files RTLBoriSoC.srcs/sources_1/new/MUX.vhd
add_files RTLBoriSoC.srcs/sources_1/new/MUX1.vhd

add_files RTLBoriSoC.srcs/sources_1/new/signext.vhd
add_files RTLBoriSoC.srcs/sources_1/new/zeroext.vhd
add_files RTLBoriSoC.srcs/sources_1/new/SLLf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/ORf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/XORf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/ANDf.vhd

add_files RTLBoriSoC.srcs/sources_1/new/instr_dec.vhd
add_files RTLBoriSoC.srcs/sources_1/new/cpu.vhd
add_files RTLBoriSoC.srcs/sources_1/new/reg.vhd
add_files RTLBoriSoC.srcs/sources_1/new/ANDf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/mem.vhd
add_files RTLBoriSoC.srcs/sources_1/new/mem_pack.vhd
add_files RTLBoriSoC.srcs/sources_1/new/SRf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/INCf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/regs.vhd

add_files RTLBoriSoC.srcs/sources_1/new/cmpf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/cmpUf.vhd

add_files RTLBoriSoC.srcs/sources_1/new/FSM.vhd



add_files RTLBoriSoC.srcs/sources_1/new/SOC.vhd

set_property source_mgmt_mode DisplayOnly [current_project]
set_property top SOC [get_filesets sources_1]
reset_run synth_1
launch_runs synth_1 -jobs 12
wait_on_run synth_1
report_timing_summary -file [current_run]/timing_summary.rpt
exit