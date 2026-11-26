create_rc_corner -name default_rc_corner -preRoute_res 1 -preRoute_cap 1 -preRoute_clkres 0 -preRoute_clkcap 0 -postRoute_res 1 -postRoute_cap 1 -postRoute_xcap 1 -postRoute_clkres 0 -postRoute_clkcap 0
create_library_set -name default_libs_max -timing "/home/kvi026/Innovus_tutorial/slow.lib"
create_library_set -name default_libs_min -timing "/home/kvi026/Innovus_tutorial/slow.lib"
create_constraint_mode -name default_mode_setup -sdc_files "/home/kvi026/Innovus_tutorial/mux.sdc"
create_constraint_mode -name default_mode_hold -sdc_files "/home/kvi026/Innovus_tutorial/mux.sdc"
create_delay_corner -name default_corner_min -rc_corner {default_rc_corner} -early_library_set {default_libs_min} -late_library_set {default_libs_max}
create_delay_corner -name default_corner_max -rc_corner {default_rc_corner} -early_library_set {default_libs_min} -late_library_set {default_libs_max}
create_analysis_view -name default_view_hold -constraint_mode {default_mode_hold} -delay_corner {default_corner_min}
create_analysis_view -name default_view_setup -constraint_mode {default_mode_setup} -delay_corner {default_corner_max}
set_analysis_view -setup "default_view_setup" -hold "default_view_hold"
