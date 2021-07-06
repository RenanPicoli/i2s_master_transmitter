# i2s_master_transmitter
This branch is intended to develop a DCFIFO (dual clock fifo)
This fifo has different clocks for reading and writing
For writing, new data should be pushed through a shift register
For reading, only a pointer should be updated.
All data should be multiplexed on output port, that pointer will be the selection input

Here is how I want to implement it:
There should be two counters, one for each clock
Each counter stores the number of valid operations (reading or writing) for that clock
The pointer (call it head) should be the difference between the two counters
Note that this pointer should not be stored to a register (since we have two unrelated clocks),
instead it must be implemented only with combinatorial circuit.
if reset is high, head should be zeroed (head <= difference and (not rst))
Note that the bus skew of the head is up to the sum of skews of each counter (they must be constrained)
To prevent failures, both counters should be zeroed during the following events:
* both at reset
* both when their difference is zero
Both counters and difference should be 32 bit wide, since its size determines the maximum f_fast/f_slow that can be accomodated


Besides:
* write counter should stop incrementing when the fifo overflows (more writes than readouts + fifo length, lost data can't be recovered)
* read counter should stop incrementing when the fifo is emptied

I2S (Inter_IC Sound) peripheral, works as a master transmitter. Testbench and slave receiver will be included.
