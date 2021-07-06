# i2s_master_transmitter
This branch is intended to develop a DCFIFO (dual clock fifo)
This fifo has different clocks for reading and writing
For writing, new data should be pushed through a shift register
For reading, only a pointer should be updated.
All data should be multiplexed on output port, that pointer will be the selection input

I2S (Inter_IC Sound) peripheral, works as a master transmitter. Testbench and slave receiver will be included.
