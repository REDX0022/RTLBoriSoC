# Add all required VHDL files (main file first, then dependencies)
read_vhdl RTLBoriSoC.srcs/sources_1/new/adder.vhd

# Synthesize the top-level entity (change 'adder' if needed)
synth_design -top ./RTLBoriSoC.srcs/sources_1/new/addr.vhd

# Optional: write a report
report_utilization -file adder_util.rpt
report_timing_summary -file adder_timing.rpt

exit