onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /testbench/D
add wave -noupdate -radix hexadecimal /testbench/CLK
add wave -noupdate -radix hexadecimal /testbench/ADDR
add wave -noupdate -radix hexadecimal /testbench/RST
add wave -noupdate -radix hexadecimal /testbench/WREN
add wave -noupdate -radix hexadecimal /testbench/RDEN
add wave -noupdate -radix hexadecimal /testbench/IACK
add wave -noupdate -radix hexadecimal /testbench/Q
add wave -noupdate -radix hexadecimal /testbench/IRQ
add wave -noupdate -radix hexadecimal /testbench/SCK
add wave -noupdate -radix hexadecimal /testbench/SD
add wave -noupdate -radix hexadecimal /testbench/WS
add wave -noupdate -radix hexadecimal /testbench/SCK_IN
add wave -noupdate /testbench/CLK12MHz
add wave -noupdate -radix hexadecimal /testbench/CLK22_05kHz
add wave -noupdate -radix hexadecimal /testbench/CLK5_647059MHz
add wave -noupdate -radix hexadecimal /testbench/ram_clk
add wave -noupdate -radix hexadecimal /testbench/DUT/D
add wave -noupdate -radix hexadecimal /testbench/DUT/ADDR
add wave -noupdate -radix hexadecimal /testbench/DUT/CLK
add wave -noupdate -radix hexadecimal /testbench/DUT/RST
add wave -noupdate -radix hexadecimal /testbench/DUT/WREN
add wave -noupdate -radix hexadecimal /testbench/DUT/RDEN
add wave -noupdate -radix hexadecimal /testbench/DUT/IACK
add wave -noupdate -radix hexadecimal /testbench/DUT/Q
add wave -noupdate -radix hexadecimal /testbench/DUT/IRQ
add wave -noupdate -radix hexadecimal /testbench/DUT/SCK_IN
add wave -noupdate -radix hexadecimal /testbench/DUT/SD
add wave -noupdate -radix hexadecimal /testbench/DUT/WS
add wave -noupdate -radix hexadecimal /testbench/DUT/SCK
add wave -noupdate -radix hexadecimal /testbench/DUT/all_periphs_output
add wave -noupdate -radix hexadecimal /testbench/DUT/all_periphs_rden
add wave -noupdate -radix hexadecimal /testbench/DUT/all_periphs_wren
add wave -noupdate -radix hexadecimal /testbench/DUT/words
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s_tx
add wave -noupdate -radix hexadecimal /testbench/DUT/all_i2s_irq
add wave -noupdate -radix hexadecimal /testbench/DUT/all_i2s_iack
add wave -noupdate -radix hexadecimal /testbench/DUT/irq_ctrl_Q
add wave -noupdate -radix hexadecimal /testbench/DUT/DR_out
add wave -noupdate -radix hexadecimal /testbench/DUT/CR_Q
add wave -noupdate -radix hexadecimal /testbench/DUT/SR_Q
add wave -noupdate -radix hexadecimal /testbench/DUT/irq_ctrl_rden
add wave -noupdate -radix hexadecimal /testbench/DUT/irq_ctrl_wren
add wave -noupdate -radix hexadecimal -childformat {{/testbench/DUT/left_data(31) -radix hexadecimal} {/testbench/DUT/left_data(30) -radix hexadecimal} {/testbench/DUT/left_data(29) -radix hexadecimal} {/testbench/DUT/left_data(28) -radix hexadecimal} {/testbench/DUT/left_data(27) -radix hexadecimal} {/testbench/DUT/left_data(26) -radix hexadecimal} {/testbench/DUT/left_data(25) -radix hexadecimal} {/testbench/DUT/left_data(24) -radix hexadecimal} {/testbench/DUT/left_data(23) -radix hexadecimal} {/testbench/DUT/left_data(22) -radix hexadecimal} {/testbench/DUT/left_data(21) -radix hexadecimal} {/testbench/DUT/left_data(20) -radix hexadecimal} {/testbench/DUT/left_data(19) -radix hexadecimal} {/testbench/DUT/left_data(18) -radix hexadecimal} {/testbench/DUT/left_data(17) -radix hexadecimal} {/testbench/DUT/left_data(16) -radix hexadecimal} {/testbench/DUT/left_data(15) -radix hexadecimal} {/testbench/DUT/left_data(14) -radix hexadecimal} {/testbench/DUT/left_data(13) -radix hexadecimal} {/testbench/DUT/left_data(12) -radix hexadecimal} {/testbench/DUT/left_data(11) -radix hexadecimal} {/testbench/DUT/left_data(10) -radix hexadecimal} {/testbench/DUT/left_data(9) -radix hexadecimal} {/testbench/DUT/left_data(8) -radix hexadecimal} {/testbench/DUT/left_data(7) -radix hexadecimal} {/testbench/DUT/left_data(6) -radix hexadecimal} {/testbench/DUT/left_data(5) -radix hexadecimal} {/testbench/DUT/left_data(4) -radix hexadecimal} {/testbench/DUT/left_data(3) -radix hexadecimal} {/testbench/DUT/left_data(2) -radix hexadecimal} {/testbench/DUT/left_data(1) -radix hexadecimal} {/testbench/DUT/left_data(0) -radix hexadecimal}} -subitemconfig {/testbench/DUT/left_data(31) {-radix hexadecimal} /testbench/DUT/left_data(30) {-radix hexadecimal} /testbench/DUT/left_data(29) {-radix hexadecimal} /testbench/DUT/left_data(28) {-radix hexadecimal} /testbench/DUT/left_data(27) {-radix hexadecimal} /testbench/DUT/left_data(26) {-radix hexadecimal} /testbench/DUT/left_data(25) {-radix hexadecimal} /testbench/DUT/left_data(24) {-radix hexadecimal} /testbench/DUT/left_data(23) {-radix hexadecimal} /testbench/DUT/left_data(22) {-radix hexadecimal} /testbench/DUT/left_data(21) {-radix hexadecimal} /testbench/DUT/left_data(20) {-radix hexadecimal} /testbench/DUT/left_data(19) {-radix hexadecimal} /testbench/DUT/left_data(18) {-radix hexadecimal} /testbench/DUT/left_data(17) {-radix hexadecimal} /testbench/DUT/left_data(16) {-radix hexadecimal} /testbench/DUT/left_data(15) {-radix hexadecimal} /testbench/DUT/left_data(14) {-radix hexadecimal} /testbench/DUT/left_data(13) {-radix hexadecimal} /testbench/DUT/left_data(12) {-radix hexadecimal} /testbench/DUT/left_data(11) {-radix hexadecimal} /testbench/DUT/left_data(10) {-radix hexadecimal} /testbench/DUT/left_data(9) {-radix hexadecimal} /testbench/DUT/left_data(8) {-radix hexadecimal} /testbench/DUT/left_data(7) {-radix hexadecimal} /testbench/DUT/left_data(6) {-radix hexadecimal} /testbench/DUT/left_data(5) {-radix hexadecimal} /testbench/DUT/left_data(4) {-radix hexadecimal} /testbench/DUT/left_data(3) {-radix hexadecimal} /testbench/DUT/left_data(2) {-radix hexadecimal} /testbench/DUT/left_data(1) {-radix hexadecimal} /testbench/DUT/left_data(0) {-radix hexadecimal}} /testbench/DUT/left_data
add wave -noupdate -radix hexadecimal /testbench/DUT/left_pop
add wave -noupdate -radix hexadecimal /testbench/DUT/left_wren
add wave -noupdate -radix hexadecimal /testbench/DUT/left_full
add wave -noupdate -radix hexadecimal /testbench/DUT/left_empty
add wave -noupdate -radix hexadecimal /testbench/DUT/left_overflow
add wave -noupdate -radix hexadecimal /testbench/DUT/right_data
add wave -noupdate -radix hexadecimal /testbench/DUT/right_pop
add wave -noupdate -radix hexadecimal /testbench/DUT/right_wren
add wave -noupdate -radix hexadecimal /testbench/DUT/right_full
add wave -noupdate -radix hexadecimal /testbench/DUT/right_empty
add wave -noupdate -radix hexadecimal /testbench/DUT/right_overflow
add wave -noupdate -radix hexadecimal /testbench/DUT/pop
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5790000 ps} 0} {{Cursor 2} {5000000 ps} 0} {{Cursor 3} {7740000 ps} 0} {{Cursor 4} {4677755 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 258
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
configure wave -timelineunits ps
update
WaveRestoreZoom {4622792 ps} {7904056 ps}
