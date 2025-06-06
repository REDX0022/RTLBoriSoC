# Add all required VHDL files (main file first, then dependencies)
read_vhdl RTLBoriSoC.srcs/sources_1/new/signext.vhd

# Synthesize the top-level entity (change 'signext' if needed)
synth_design -top signext -part xc7a100tcsg324-1

# Optional: write a report
report_utilization -file signext_util.rpt
report_timing_summary -file signext_timing.rpt

exit