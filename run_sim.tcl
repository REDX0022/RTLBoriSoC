open_project RTLBoriSoC.xpr

set_property source_mgmt_mode All [current_project]

# Add all source files
add_files RTLBoriSoC.srcs/sources_1/new/def_pack.vhd
add_files RTLBoriSoC.srcs/sources_1/new/mnemonic_pack.vhd
add_files RTLBoriSoC.srcs/sources_1/new/IO_pack.vhd
add_files RTLBoriSoC.srcs/sources_1/new/init_pack.vhd

add_files RTLBoriSoC.srcs/sources_1/new/adder.vhd
add_files RTLBoriSoC.srcs/sources_1/new/ALUdp.vhd
add_files RTLBoriSoC.srcs/sources_1/new/MUX.vhd
add_files RTLBoriSoC.srcs/sources_1/new/MUX1.vhd

add_files RTLBoriSoC.srcs/sources_1/new/signext.vhd
add_files RTLBoriSoC.srcs/sources_1/new/zeroext.vhd
add_files RTLBoriSoC.srcs/sources_1/new/SLLf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/SRf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/ORf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/XORf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/ANDf.vhd

add_files RTLBoriSoC.srcs/sources_1/new/instr_dec.vhd
add_files RTLBoriSoC.srcs/sources_1/new/cpu.vhd
add_files RTLBoriSoC.srcs/sources_1/new/reg.vhd
add_files RTLBoriSoC.srcs/sources_1/new/regs.vhd

add_files RTLBoriSoC.srcs/sources_1/new/ANDf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/mem.vhd
add_files RTLBoriSoC.srcs/sources_1/new/mem_pack.vhd
add_files RTLBoriSoC.srcs/sources_1/new/INCf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/cmpf.vhd
add_files RTLBoriSoC.srcs/sources_1/new/cmpuf.vhd


add_files RTLBoriSoC.sim/sim_1/testbench.vhd

# Add the testbench file
add_files -fileset sim_1 RTLBoriSoC.sim/sim_1/testbench.vhd

# Set testbench.vhd as the simulation top module
set_property top testbench [get_filesets sim_1]

# Set all testbench-only files to simulation only (if needed)
set_property USED_IN {simulation} [get_files RTLBoriSoC.sim/sim_1/testbench.vhd]

# Launch simulation
launch_simulation

# Close the wave window (optional, disables waveform display)
close_wave_config