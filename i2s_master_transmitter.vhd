--------------------------------------------------
--I2S master transmitter peripheral
--by Renan Picoli de Souza
--instantiates a generic I2S master transmitter and provides access to its registers 
--supports only 8 bit sending/receiving
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;--addition of std_logic_vector
use ieee.numeric_std.all;--to_integer, unsigned
use work.my_types.all;--array32

entity i2s_master_transmitter is
	port (
			D: in std_logic_vector(31 downto 0);--for register write
			ADDR: in std_logic_vector(1 downto 0);--address offset of registers relative to peripheral base address
			CLK: in std_logic;--for register read/write, also used to generate SCK
			RST: in std_logic;--reset
			WREN: in std_logic;--enables register write
			RDEN: in std_logic;--enables register read
			IACK: in std_logic;--interrupt acknowledgement
			Q: out std_logic_vector(31 downto 0);--for register read
			IRQ: out std_logic;--interrupt request
			SD: out std_logic;--data line
			WS: buffer std_logic;--left/right clock
			SCK: out std_logic--continuous clock (bit clock)
	);
end i2s_master_transmitter;

architecture structure of i2s_master_transmitter is
	component address_decoder_register_map
	--N: address width in bits
	--boundaries: upper limits of each end (except the last, which is 2**N-1)
	generic	(N: natural);
	port(	ADDR: in std_logic_vector(N-1 downto 0);-- input
			RDEN: in std_logic;-- input
			WREN: in std_logic;-- input
			WREN_OUT: out std_logic_vector;-- output
			data_in: in array32;-- input: outputs of all peripheral/registers
			data_out: out std_logic_vector(31 downto 0)-- data read
	);
	end component;
	
	component d_flip_flop
		port (D:	in std_logic_vector(31 downto 0);
				rst:	in std_logic;--synchronous reset
				ENA:	in std_logic:='1';--enables writes
				CLK:in std_logic;
				Q:	out std_logic_vector(31 downto 0)  
				);
	end component;
	
	component i2s_master_transmitter_generic
	generic (N: natural);--number of bits in each word
	port (
			DR_out: in std_logic_vector(31 downto 0);--data to be transmitted
			CLK_IN: in std_logic;--clock input, divided by 2 to generate SCL
			RST: in std_logic;--reset
			I2S_EN: in std_logic;--enables transfer to start
			left_data: in std_logic_vector(31 downto 0);--left channel
			right_data: in std_logic_vector(31 downto 0);--right channel
			NFR: in std_logic_vector(2 downto 0);--controls number of frames to send (left channel	first, MSB first in each channel), 000 means unlimited
			IACK: in std_logic_vector(0 downto 0);--acknowledgement of interrupt request: successfully transmitted all words;
			IRQ: out std_logic_vector(0 downto 0);--interrupt request: successfully transmitted all words;
			pop: out std_logic;--requests another data to the fifo
			TX: out std_logic;-- indicates transmission
			SD: out std_logic;--data line
			WS: out std_logic;--left/right clock (0 left, 1 right)
			SCK: out std_logic--continuous clock (bit clock)
	);
	end component;
	
	component smart_fifo
	port (
			DATA_IN: in std_logic_vector(31 downto 0);--for register write
			CLK: in std_logic;
			RST: in std_logic;
			WREN: in std_logic;--enables software write
			POP: in std_logic;--tells the fifo to move oldest data to position 0 if there is valid data
			FULL: out std_logic;--'1' indicates that fifo is full
			EMPTY: out std_logic;--'1' indicates that fifo is empty
			OVF: out std_logic;--'1' indicates that fifo is overflowing (and dropping data)
			DATA_OUT: out std_logic_vector(31 downto 0)--oldest data
	);
	end component;
	
	component interrupt_controller
	generic	(L: natural);--L: number of IRQ lines
	port(	D: in std_logic_vector(31 downto 0);-- input: data to register write
			CLK: in std_logic;-- input
			RST: in std_logic;-- input
			WREN: in std_logic;-- input
			RDEN: in std_logic;-- input
			IRQ_IN: in std_logic_vector(L-1 downto 0);--input: all IRQ lines
			IRQ_OUT: out std_logic;--output: IRQ line to cpu
			IACK_IN: in std_logic;--input: IACK line coming from cpu
			IACK_OUT: buffer std_logic_vector(L-1 downto 0);--output: all IACK lines going to peripherals
			output: out std_logic_vector(31 downto 0)-- output of register reading
	);

	end component;
	
	constant N: natural := 4;--number of bits in each data written/read
	signal words: std_logic_vector(1 downto 0);--00: 1 word; 01:2 words; 10: 3 words (unused); 11: 4 words
	signal i2s_tx: std_logic;--flag indicating I2S is transmitting
	signal all_i2s_irq: std_logic_vector(0 downto 0);--successfully transmitted all words
	signal all_i2s_iack: std_logic_vector(0 downto 0);
	
	signal irq_ctrl_Q: std_logic_vector(31 downto 0);
	signal irq_ctrl_rden: std_logic;-- not used, just to keep form
	signal irq_ctrl_wren: std_logic;
	
	signal DR_out: std_logic_vector(31 downto 0);--data transmitted/received
	signal DR_in:  std_logic_vector(31 downto 0);--data that will be written to DR
	signal DR_wren:std_logic;--enables write value from D port
	signal DR_ena:std_logic;--DR ENA (enables DR write)
	
	-- 8 stage fifos
	signal left_data: std_logic_vector(31 downto 0);
	signal left_pop: std_logic;--tells the (left) fifo to provide another data
	signal left_wren: std_logic;--enables write on left fifo
	signal left_full: std_logic;--left fifo is full
	signal left_empty: std_logic;--left fifo is empty
	signal left_overflow: std_logic;--left fifo is overflowing
	signal right_data: std_logic_vector(31 downto 0);
	signal right_pop: std_logic;--tells the (left) fifo to provide another data
	signal right_wren: std_logic;--enables write on right fifo
	signal right_full: std_logic;--right fifo is full
	signal right_empty: std_logic;--right fifo is empty
	signal right_overflow: std_logic;--right fifo is overflowing
	signal pop: std_logic;--tells the (left) fifo to provide another data
	
	signal CR_in: std_logic_vector(31 downto 0);--CR input
	signal CR_Q: std_logic_vector(31 downto 0);--CR output
	signal CR_wren:std_logic;
	signal CR_ena:std_logic;
		
	signal SR_in: std_logic_vector(31 downto 0);--SR input
	signal SR_Q: std_logic_vector(31 downto 0);--SR output
	signal SR_wren:std_logic;
	signal SR_ena:std_logic;
	
	signal all_registers_output: array32 (3 downto 0);
	signal all_periphs_rden: std_logic_vector(3 downto 0);
	signal address_decoder_wren: std_logic_vector(3 downto 0);
begin
	
	i2s: i2s_master_transmitter_generic
	generic map (N => N)
	port map(DR_out => DR_out,
				CLK_IN => CLK,
				RST => RST,
				I2S_EN => CR_Q(0),
				left_data => left_data,
				right_data => right_data,
				NFR => CR_Q(3 downto 1),
				IACK => all_i2s_iack,
				IRQ => all_i2s_irq,
				pop => pop,
				TX => i2s_tx,
				WS => WS,
				SD => SD,
				SCK => SCK
	);
	
	--bit 0: BTF (sucessful transfer)
	irq_ctrl_wren <= address_decoder_wren(2);
	irq_ctrl_rden <= '1';--not necessary, just to keep form
	irq_ctrl: interrupt_controller
	generic map (L => 1)
	port map(D => D,
				CLK => CLK,
				RST => RST,
				WREN => irq_ctrl_wren,
				RDEN => irq_ctrl_rden,
				IRQ_IN => all_i2s_irq,
				IRQ_OUT => IRQ,
				IACK_IN => IACK,
				IACK_OUT => all_i2s_iack,
				output => irq_ctrl_Q
	);
	
	--data register: data to be transmited (goes to fifo, if fifo is full, discard older data and raises irq)
	--each stage of fifo stores a 32 bit word,
	--if word length (audio depth) is less than 32 bits, only LSB of a fifo stage is transmitted
	DR_wren <= address_decoder_wren(1);
	DR_ena <=	DR_wren;--DR_wren='1' indicates software write
	DR_in <= D;-- write mode (master transmitter)
	
	DR: d_flip_flop port map(D => DR_in,
									RST=> RST,--resets all previous history of input signal
									CLK=> CLK,--sampling clock
									ENA=> DR_ena,
									Q=> DR_out
									);
	
	--older data is available at position 0
	--pop: tells the fifo to move oldest data to position 0 if there is valid data
	left_pop <= pop and (not WS);
	left_wren <= DR_wren and (not CR_Q(7));
	l_fifo: smart_fifo port map(	DATA_IN => DR_out,
											RST => RST,
											CLK => CLK,
											WREN => left_wren,
											POP => left_pop,
											FULL => left_full,
											EMPTY => left_empty,
											OVF => left_overflow,
											DATA_OUT => left_data);
	
	--older data is available at position 0
	--pop: tells the fifo to move oldest data to position 0 if there is valid data
	right_pop <= pop and WS;
	right_wren <= DR_wren and (CR_Q(7));
	r_fifo: smart_fifo port map(	DATA_IN => DR_out,
											RST => RST,
											CLK => CLK,
											WREN => right_wren,
											POP => right_pop,
											FULL => right_full,
											EMPTY => right_empty,
											OVF => right_overflow,
											DATA_OUT => right_data);
	
	--control register:
	--bit 7 LRFS: left-rifgt fifo select: 0 selects left fifo, 1 selects right fifo
	--bits 6:4 DS data size, (DS+1)*4 is the word length to use for each channel (will be also half of a frame size).
	--		Each fifo stage contains two of these words (one frame), right-aligned.
	--		(000: 4 bit, 001: 8 bit, 010: 12 bit, 011: 16 bit, 100: 20 bit, 101: 24 bit, 110: 28 bit, 111: 32 bit)
	--bits 3:1 NFR number of frames to transmit, if NFR=0, transmits forever;
	--		Each frame is a pair of left-right data.
	--		Older data from fifo is sent first, MSB first for each channel)
	--bit 0: I2S_EN (write '1' to start, reset automatically)
	CR_in <= D when CR_wren='1' else CR_Q(31 downto 1) & '0';
	CR_ena <= '1';
	CR_wren <= address_decoder_wren(0);
	CR: d_flip_flop port map(D => CR_in,
									RST=> RST,
									CLK=> CLK,
									ENA=> CR_ena,
									Q=> CR_Q
									);
	
	--status register (write-only):
	--bit 6: TX (I2S is transmitting)
	--bit 5: ROVF (right fifo is overflowing in this clock cycle)
	--bit 4: LOVF (left fifo is overflowing in this clock cycle)
	--bit 3: REMP (right fifo is empty)
	--bit 2: LEMP (left fifo is empty)
	--bit 1: RFULL (right fifo is full)
	--bit 0: LFULL (left fifo is full)
	SR_in <= (31 downto 7 => '0') & i2s_tx & right_overflow & left_overflow & right_empty & left_empty & right_full & left_full;
	SR_ena <= '1';--always writes, updating status register
	SR_wren <= address_decoder_wren(3);--not used, just to keep form
	SR: d_flip_flop port map(D => SR_in,
									RST=> RST,
									CLK=> CLK,
									ENA=> SR_ena,
									Q=> SR_Q
									);

-------------------------- address decoder ---------------------------------------------------
	--addr 00: CR
	--addr 01: DR
	--addr 10: irq_ctrl (interrupts pending)
	--addr 11: SR (status register: read-only)
	all_registers_output <= (0=> CR_Q,1=> DR_out,2=> irq_ctrl_Q,3=> SR_Q);
	decoder: address_decoder_register_map
	generic map(N => 2)
	port map(ADDR => ADDR,
				RDEN => RDEN,
				WREN => WREN,
				data_in => all_registers_output,
				WREN_OUT => address_decoder_wren,
				data_out => Q
	);
end structure;