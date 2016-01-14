onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /lock/clk
add wave -noupdate /lock/rst_n
add wave -noupdate /lock/keys_in
add wave -noupdate /lock/lock_out
add wave -noupdate /lock/curr_state_r
add wave -noupdate /lock/next_state
add wave -noupdate /lock/reset_counter_r
add wave -noupdate /lock/STTRAN/count_v
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1166 ns}
