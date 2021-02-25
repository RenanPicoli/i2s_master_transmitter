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
			WS: out std_logic;--left/right clock
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
			IACK: in std_logic_vector(1 downto 0);--interrupt request: 0: successfully transmitted all words; 1: NACK received
			IRQ: out std_logic_vector(1 downto 0);--interrupt request: 0: successfully transmitted all words; 1: NACK received
			pop: out std_logic;--requests another data to the fifo
			SD: out std_logic;--data line
			WS: out std_logic;--left/right clock
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
	signal all_i2c_irq: std_logic_vector(1 downto 0);--0: successfully transmitted all words; 1: NACK received
	signal all_i2c_iack: std_logic_vector(1 downto 0);--0: successfully transmitted all words; 1: NACK received
	
	signal irq_ctrl_Q: std_logic_vector(31 downto 0);
	signal irq_ctrl_rden: std_logic;-- not used, just to keep form
	signal irq_ctrl_wren: std_logic;
	
	signal DR_out: std_logic_vector(31 downto 0);--data transmitted/received
	signal DR_in:  std_logic_vector(31 downto 0);--data that will be written to DR
	signal DR_wren:std_logic;--enables write value from D port
	signal DR_ena:std_logic;--DR ENA (enables DR write)
	
	-- 8 stage fifos
	signal left_data: std_logic_vector(31 downto 0);
	signal pop: std_logic;--tells the fifo to provide another data
	
	signal CR_in: std_logic_vector(31 downto 0);--CR input
	signal CR_Q: std_logic_vector(31 downto 0);--CR output
	signal CR_wren:std_logic;
	signal CR_ena:std_logic;
	
	signal all_registers_output: array32 (2 downto 0);
	signal all_periphs_rden: std_logic_vector(2 downto 0);
	signal address_decoder_wren: std_logic_vector(2 downto 0);
begin
	
	i2s: i2s_master_transmitter_generic
	generic map (N => N)
	port map(DR_out => DR_out,
				CLK_IN => CLK,
				RST => RST,
				I2S_EN => CR_Q(0),
				left_data => left_data,
				right_data => x"0000_000A",
				NFR => CR_Q(3 downto 1),
				IACK => all_i2c_iack,
				IRQ => all_i2c_irq,
				pop => pop,
				WS => WS,
				SD => SD,
				SCK => SCK
	);
	
	irq_ctrl_wren <= address_decoder_wren(2);
	irq_ctrl_rden <= '1';--not necessary, just to keep form
	irq_ctrl: interrupt_controller
	generic map (L => 2)
	port map(D => D,
				CLK => CLK,
				RST => RST,
				WREN => irq_ctrl_wren,
				RDEN => irq_ctrl_rden,
				IRQ_IN => all_i2c_irq,
				IRQ_OUT => IRQ,
				IACK_IN => IACK,
				IACK_OUT => all_i2c_iack,
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
	l_fifo: smart_fifo port map(	DATA_IN => DR_out,
											RST => RST,
											CLK => CLK,
											WREN => DR_wren,
											POP => pop,
											DATA_OUT => left_data);
	
	--control register:
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
									RST=> RST,--resets all previous history of input signal
									CLK=> CLK,--sampling clock
									ENA=> CR_ena,
									Q=> CR_Q
									);

-------------------------- address decoder ---------------------------------------------------
	--addr 00: CR
	--addr 01: DR
	--addr 10: irq_ctrl (interrupts pending)
	all_registers_output <= (0=> CR_Q,1=> DR_out,2=> irq_ctrl_Q);
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