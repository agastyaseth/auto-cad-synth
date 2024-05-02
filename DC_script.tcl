
set target_library "nangate45nm_lib.db"
#set synthetic_library "dw_foundation.sldb"
set link_library   "* nangate45nm_lib.db"
# set symbol_library "/tools/synopsys/syn/O-2018.06-SP4/libraries/syn generic.sdb"
# set_dont_use {NangateOpenCellLibrary/AOI*}
# set_dont_use {NangateOpenCellLibrary/OAI*}
# set_dont_use {NangateOpenCellLibrary/TINV*}
# set_dont_use {NangateOpenCellLibrary/TBUF*}
# set_dont_use {NangateOpenCellLibrary/FA*}
# set_dont_use {NangateOpenCellLibrary/HA*}
# set_dont_use {NangateOpenCellLibrary/MUX*}
# set_dont_use {NangateOpenCellLibrary/DL*}
# set_dont_use {NangateOpenCellLibrary/SDFF*}

set timestamp [clock format [clock scan now] -format "%Y-%m-%d_%H-%M"]
set enable_page_mode false
set sh_new_variable_message false
set verilogout_no_tri true
set verilogout_show_unconnected_pins true
set hdlin_auto_save_templates true

######### Set top module here
set top_module des
#change top_module name here (module name not filename)
############# Elaborate Design ################
read_file {./} -autoread -format verilog -top des

current_design ${top_module}
link
compile

uniquify -dont_skip_empty_designs
#set set_ultra_optimization true


set all_input_but_clock  [remove_from_collection [all_inputs] clk] 
#change "clk" everywhere to the clock_name used in the design

###################################################################
##...............define generated clock............................
create_clock -period  2  [get_ports clk]
set_clock_uncertainty -setup 0.1 [get_ports clk]
set_clock_uncertainty -hold  0.1 [get_ports clk]
set_clock_transition 0.1 [get_clocks clk]
##.............delay and drive strength on input ports.............
set_input_delay -max 0 -clock clk  $all_input_but_clock
set_input_delay -min 0 -clock clk  $all_input_but_clock
#set_driving_cell  -lib_cell INVX1 $all_input_but_clock
##set_operating_conditions -min best -max worst
set_wire_load_mode segmented
set_load 0.1 [all_inputs]
###################################################################
check_design
set_max_area 0
set_fix_hold [all_clocks]
set verilogout_show_unconnected_pins true
set verilogout_no_tri true
set_fix_multiple_port_nets -all -buffer_constants
#set_svf PE.svf
compile
#compile_ultra -timing_high_effort_script -no_autoungroup
#compile_ultra -incremental -timing_high_effort_script -no_autoungroup
#compile

## Report Design
define_name_rules verilog -case_insensitive
change_names -hierarchy -rules verilog
#####comment ungroup if you want to write out hierarchical netlist
ungroup -all -flatten 
####
write  -h -format verilog -output "${top_module}_syn.v"
#write -format ddc -hierarchy -output "$output_dir/${top_module}_gate.ddc"
write_sdc "${top_module}_gate.sdc"
write_sdf "${top_module}_gate.sdf"
redirect -append -tee "Report_area.txt" {report_area -nosplit -hierarchy}
redirect -append -tee "Report_power.txt" {report_power -hier -hier_level 100 -analysis_effort high}
#redirect -append -tee "$output_dir/Report_power_netcell.txt" {report_power -net -cell -analysis_effort high -sort_mode dynamic_power}
#redirect -append -tee "$output_dir/Report_clock.txt" {report_clock -nosplit}
#redirect -append -tee "$output_dir/Report_timing.txt" {report_timing -path full -delay min -nworst 1 -max_paths 3 -significant_digits 2 -sort_by group}
exit
