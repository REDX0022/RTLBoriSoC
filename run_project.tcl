open_project RTLBoriSoC.xpr
add_files RTLBoriSoC.srcs/sources_1/new/subtr.vhd
set_property source_mgmt_mode DisplayOnly [current_project]
set_property top adder [get_filesets sources_1]
reset_run synth_1
launch_runs synth_1 -jobs 6
wait_on_run synth_1
report_timing_summary -file timing_summary.rpt
exit