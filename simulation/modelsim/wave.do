onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /testbench/SCK_IN
add wave -noupdate /testbench/CLK12MHz
add wave -noupdate -radix hexadecimal /testbench/CLK22_05kHz
add wave -noupdate /testbench/CLK2_8235295MHz
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
add wave -noupdate /testbench/DUT/RST
add wave -noupdate /testbench/DUT/SCK_IN_PLL_LOCKED
add wave -noupdate /testbench/DUT/i2s/RST
add wave -noupdate -radix hexadecimal /testbench/DUT/all_periphs_rden
add wave -noupdate -radix hexadecimal /testbench/DUT/all_periphs_wren
add wave -noupdate -radix hexadecimal /testbench/DUT/words
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s_tx
add wave -noupdate -radix hexadecimal /testbench/DUT/all_i2s_irq
add wave -noupdate -radix hexadecimal /testbench/DUT/all_i2s_iack
add wave -noupdate -radix hexadecimal /testbench/DUT/DR_out
add wave -noupdate -radix hexadecimal /testbench/DUT/CR_Q
add wave -noupdate -radix hexadecimal /testbench/DUT/SR_Q
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/DR_out
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/CLK_IN
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/RST
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/I2S_EN
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/left_data
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/right_data
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/DS
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/NFR
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/IACK
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/IRQ
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/pop
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/TX
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/SD
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/WS
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/SCK
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/fifo_sd_out
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/start
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/stop
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/stop_stretched
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/stop_stretched_2
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/parallel_data_in
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/right_data_padded
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/left_data_padded
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/load
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/I2S_EN_delayed
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/WS_delayed
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/prescaler_out
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/prescaler_rst
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/CLK
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/SCK_n
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/bits_sent
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/frame_number
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/frame_number_delayed
add wave -noupdate -radix hexadecimal /testbench/DUT/i2s/sck_en
add wave -noupdate -radix hexadecimal -childformat {{/testbench/DUT/left_data(31) -radix hexadecimal} {/testbench/DUT/left_data(30) -radix hexadecimal} {/testbench/DUT/left_data(29) -radix hexadecimal} {/testbench/DUT/left_data(28) -radix hexadecimal} {/testbench/DUT/left_data(27) -radix hexadecimal} {/testbench/DUT/left_data(26) -radix hexadecimal} {/testbench/DUT/left_data(25) -radix hexadecimal} {/testbench/DUT/left_data(24) -radix hexadecimal} {/testbench/DUT/left_data(23) -radix hexadecimal} {/testbench/DUT/left_data(22) -radix hexadecimal} {/testbench/DUT/left_data(21) -radix hexadecimal} {/testbench/DUT/left_data(20) -radix hexadecimal} {/testbench/DUT/left_data(19) -radix hexadecimal} {/testbench/DUT/left_data(18) -radix hexadecimal} {/testbench/DUT/left_data(17) -radix hexadecimal} {/testbench/DUT/left_data(16) -radix hexadecimal} {/testbench/DUT/left_data(15) -radix hexadecimal} {/testbench/DUT/left_data(14) -radix hexadecimal} {/testbench/DUT/left_data(13) -radix hexadecimal} {/testbench/DUT/left_data(12) -radix hexadecimal} {/testbench/DUT/left_data(11) -radix hexadecimal} {/testbench/DUT/left_data(10) -radix hexadecimal} {/testbench/DUT/left_data(9) -radix hexadecimal} {/testbench/DUT/left_data(8) -radix hexadecimal} {/testbench/DUT/left_data(7) -radix hexadecimal} {/testbench/DUT/left_data(6) -radix hexadecimal} {/testbench/DUT/left_data(5) -radix hexadecimal} {/testbench/DUT/left_data(4) -radix hexadecimal} {/testbench/DUT/left_data(3) -radix hexadecimal} {/testbench/DUT/left_data(2) -radix hexadecimal} {/testbench/DUT/left_data(1) -radix hexadecimal} {/testbench/DUT/left_data(0) -radix hexadecimal}} -subitemconfig {/testbench/DUT/left_data(31) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(30) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(29) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(28) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(27) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(26) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(25) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(24) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(23) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(22) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(21) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(20) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(19) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(18) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(17) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(16) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(15) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(14) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(13) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(12) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(11) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(10) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(9) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(8) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(7) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(6) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(5) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(4) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(3) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(2) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(1) {-height 16 -radix hexadecimal} /testbench/DUT/left_data(0) {-height 16 -radix hexadecimal}} /testbench/DUT/left_data
add wave -noupdate -radix hexadecimal /testbench/DUT/l_fifo/fifo
add wave -noupdate -radix hexadecimal /testbench/DUT/left_pop
add wave -noupdate -radix hexadecimal /testbench/DUT/left_wren
add wave -noupdate -radix hexadecimal /testbench/DUT/left_full
add wave -noupdate -radix hexadecimal /testbench/DUT/left_empty
add wave -noupdate -radix hexadecimal /testbench/DUT/left_overflow
add wave -noupdate -radix hexadecimal /testbench/DUT/right_data
add wave -noupdate -radix hexadecimal /testbench/DUT/r_fifo/fifo
add wave -noupdate -radix hexadecimal /testbench/DUT/right_pop
add wave -noupdate -radix hexadecimal /testbench/DUT/right_wren
add wave -noupdate -radix hexadecimal /testbench/DUT/right_full
add wave -noupdate -radix hexadecimal /testbench/DUT/right_empty
add wave -noupdate -radix hexadecimal /testbench/DUT/right_overflow
add wave -noupdate -radix hexadecimal /testbench/DUT/pop
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {I2S_EN {5460000 ps} 0} {load {5541248 ps} 0} {LOCKED {5426665 ps} 0} {bug {5260000 ps} 0} {pop {5895415 ps} 0}
quietly wave cursor active 5
configure wave -namecolwidth 258
configure wave -valuecolwidth 83
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
WaveRestoreZoom {0 ps} {78750016 ps}
