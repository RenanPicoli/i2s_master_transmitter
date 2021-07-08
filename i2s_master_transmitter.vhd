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
			ADDR: in std_logic_vector(2 downto 0);--address offset of registers relative to peripheral base address
			CLK: in std_logic;--for register read/write, also used to generate SCK
			RST: in std_logic;--reset
			WREN: in std_logic;--enables register write
			RDEN: in std_logic;--enables register read
			IACK: in std_logic;--interrupt acknowledgement
			Q: out std_logic_vector(31 downto 0);--for register read
			IRQ: out std_logic;--interrupt request
			SCK_IN: in std_logic;--clock for SCK generation (must be 256*fs, because SCK_IN is divided by 2 to generate SCK)
			SCK_IN_PLL_LOCKED: in std_logic;--'1' if PLL that provides SCK_IN is locked
			SD: out std_logic;--data line
			WS: buffer std_logic;--left/right clock (0 left, 1 right)
			SCK: out std_logic--continuous clock (bit clock); fSCK=128fs
	);
end i2s_master_transmitter;

architecture structure of i2s_master_transmitter is
	component address_decoder_memory_map
	--N: word address width in bits
	--B boundaries: list of values of the form (starting address,final address) of all peripherals, written as integers,
	--list MUST BE "SORTED" (start address(i) < final address(i) < start address (i+1)),
	--values OF THE FORM: "(b1 b2..bN 0..0),(b1 b2..bN 1..1)"
	generic	(N: natural; B: boundaries);
	port(	ADDR: in std_logic_vector(N-1 downto 0);-- input, it is a word address
			RDEN: in std_logic;-- input
			WREN: in std_logic;-- input
			data_in: in array32;-- input: outputs of all peripheral/registers
			RDEN_OUT: out std_logic_vector;-- output
			WREN_OUT: out std_logic_vector;-- output
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
	generic (FRS: natural);--FRS: frame size (bits or SCK cycles), FRS MUST BE EVEN
	port (
			CLK_IN: in std_logic;--clock input used to generate SCK, must be stable (PLL locked)
			RST: in std_logic;--reset
			I2S_EN: in std_logic;--enables transfer to start
			left_data: in std_logic_vector(31 downto 0);--left channel
			right_data: in std_logic_vector(31 downto 0);--right channel
			DS: in std_logic_vector(2 downto 0);--DS data size, (DS+1)*4 is the resolution (in bits) to use for each channel
			NFR: in std_logic_vector(2 downto 0);--controls number of frames to send (left channel	first, MSB first in each channel), 000 means unlimited
			IACK: in std_logic_vector(0 downto 0);--acknowledgement of interrupt request: successfully transmitted all words;
			IRQ: out std_logic_vector(0 downto 0);--interrupt request: successfully transmitted all words;
			pop: out std_logic;--requests another data to the fifo, is asserted next falling_edge of SCK after WS changes
			TX: out std_logic;-- indicates transmission
			SD: buffer std_logic;--data line
			WS: buffer std_logic;--left/right clock (0 left, 1 right)
			SCK: buffer std_logic--continuous clock (bit clock)
	);
	end component;
	
	component smart_fifo
	port (
			DATA_IN: in std_logic_vector(31 downto 0);--for register write
			WCLK: in std_logic;--processor clock for writes
			RCLK: in std_logic;--processor clock for reading
			RST: in std_logic;--asynchronous reset
			WREN: in std_logic;--enables software write
			POP: in std_logic;--aka RDEN
			FULL: buffer std_logic;--'1' indicates that fifo is full
			EMPTY: buffer std_logic;--'1' indicates that fifo is empty
			OVF: out std_logic;--'1' indicates that fifo is overflowing (and dropping data)
			DATA_OUT: out std_logic_vector(31 downto 0)--oldest data
	);
	end component;
	
	component interrupt_controller
	generic	(L: natural);--L: number of IRQ lines
	port(	D: in std_logic_vector(31 downto 0);-- input: data to register write
			ADDR: in std_logic_vector(1 downto 0);--address offset of registers relative to peripheral base address
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
	
	component sync_chain
		generic (N: natural;--bus width in bits
					L: natural);--number of registers in the chain
		port (
				data_in: in std_logic_vector(N-1 downto 0);--data generated at another clock domain
				CLK: in std_logic;--clock of new clock domain
				data_out: out std_logic_vector(N-1 downto 0)--data synchronized in CLK domain
		);
	end component;
	
	-----------signals for memory map interfacing----------------
	constant ranges: boundaries := 	(--notation: base#value#
												(16#00#,16#00#),--CR
												(16#01#,16#01#),--DR
												(16#02#,16#02#),--SR
												(16#04#,16#07#) --interrupt controller
												);
	signal all_periphs_output: array32 (3 downto 0);
	signal all_periphs_rden: std_logic_vector(3 downto 0);
	signal all_periphs_wren: std_logic_vector(3 downto 0);
	
	constant N: natural := 16;--resolution of each channel in bits
	signal words: std_logic_vector(1 downto 0);--00: 1 word; 01:2 words; 10: 3 words (unused); 11: 4 words
	signal i2s_tx: std_logic;--flag indicating I2S is transmitting
	signal all_i2s_irq: std_logic_vector(0 downto 0);--successfully transmitted all words
	signal all_i2s_iack: std_logic_vector(0 downto 0);
	signal i2s_rst: std_logic;--keeps I2S generic component at reset until PLL lockes and SCK_IN is stable
	
	signal irq_ctrl_Q: std_logic_vector(31 downto 0);
	signal irq_ctrl_rden: std_logic;-- not used, just to keep form
	signal irq_ctrl_wren: std_logic;
	
	signal DR_out: std_logic_vector(31 downto 0);--data transmitted/received
	signal DR_in:  std_logic_vector(31 downto 0);--data that will be written to DR
	signal DR_wren:std_logic;--enables write value from D port
	signal DR_rden:std_logic;-- not used, just to keep form
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
	signal CR_rden:std_logic;
	signal CR_ena:std_logic;
		
	signal SR_in: std_logic_vector(31 downto 0);--SR input
	signal SR_Q: std_logic_vector(31 downto 0);--SR output
	signal SR_wren:std_logic;
	signal SR_rden:std_logic;
	signal SR_ena:std_logic;
	
	--sync_chain outputs
	signal CR_Q_sync: std_logic_vector(31 downto 0);--CR output synchronized to SCK_IN
	signal left_data_sync: std_logic_vector(31 downto 0);
	signal right_data_sync: std_logic_vector(31 downto 0);
	signal all_i2s_iack_sync: std_logic_vector(0 downto 0);
begin

	sync_chain_CR: sync_chain
		generic map (N => 32,--bus width in bits
					L => 2)--number of registers in the chain
		port map (
				data_in => CR_Q,--data generated at another clock domain
				CLK => SCK_IN,--clock of new clock domain
				data_out => CR_Q_sync--data synchronized in CLK domain
		);

--	sync_chain_r_fifo: sync_chain
--		generic map (N => 32,--bus width in bits
--					L => 2)--number of registers in the chain
--		port map (
--				data_in => right_data,--data generated at another clock domain
--				CLK => SCK_IN,--clock of new clock domain
--				data_out => right_data_sync--data synchronized in CLK domain
--		);
--		
--	sync_chain_l_fifo: sync_chain
--		generic map (N => 32,--bus width in bits
--					L => 2)--number of registers in the chain
--		port map (
--				data_in => left_data,--data generated at another clock domain
--				CLK => SCK_IN,--clock of new clock domain
--				data_out => left_data_sync--data synchronized in CLK domain
--		);
		
	sync_chain_iack: sync_chain
		generic map (N => 1,--bus width in bits
					L => 2)--number of registers in the chain
		port map (
				data_in => all_i2s_iack,--data generated at another clock domain
				CLK => SCK_IN,--clock of new clock domain
				data_out => all_i2s_iack_sync--data synchronized in CLK domain
		);
		
	i2s_rst <= RST or (not SCK_IN_PLL_LOCKED);
	i2s: i2s_master_transmitter_generic
	generic map (FRS => 2*32)--FRS = 64 (32 bits for each channel)
	port map(
				CLK_IN => SCK_IN,
				RST => i2s_rst,
				I2S_EN => CR_Q_sync(0),
				left_data => left_data,
				right_data => right_data,
				DS => CR_Q_sync(6 downto 4),
				NFR => CR_Q_sync(3 downto 1),
				IACK => all_i2s_iack_sync,
				IRQ => all_i2s_irq,
				pop => pop,
				TX => i2s_tx,
				WS => WS,
				SD => SD,
				SCK => SCK
	);
	
	--bit 0: BTF (sucessful transfer)
	irq_ctrl: interrupt_controller
	generic map (L => 1)
	port map(D => D,
				ADDR => ADDR(1 downto 0),
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
	DR_ena <=	DR_wren;--DR_wren='1' indicates software write
	DR_in <= D;-- write mode (master transmitter)
	
	--DR stores the last data written, just for software query
	DR: d_flip_flop port map(D => DR_in,
									RST=> RST,--resets all previous history of input signal
									CLK=> CLK,--sampling clock
									ENA=> DR_ena,
									Q=> DR_out
									);
	
	--DR and the fifos are mapped to the same address
	--older data is available at position 0
	--pop: tells the fifo to move oldest data to position 0 if there is valid data
	left_pop <= pop and (not WS);
	left_wren <= DR_wren and (not CR_Q(7));
	l_fifo: smart_fifo port map(	DATA_IN => DR_in,--DR and the fifos are mapped to the same address
											RST => RST,
											WCLK => CLK,
											RCLK => SCK_IN,
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
	r_fifo: smart_fifo port map(	DATA_IN => DR_in,--DR and the fifos are mapped to the same address
											RST => RST,
											WCLK => CLK,
											RCLK => SCK_IN,
											WREN => right_wren,
											POP => right_pop,
											FULL => right_full,
											EMPTY => right_empty,
											OVF => right_overflow,
											DATA_OUT => right_data);
	
	--control register:
	--bit 7 LRFS: left-rifgt fifo select: 0 selects left fifo, 1 selects right fifo
	--bits 6:4 DS: data size, (DS+1)*4 is the resolution (in bits) to use for each channel
	--		Each fifo stage contains two of these words (one frame), right-aligned.
	--		(000: 4 bit, 001: 8 bit, 010: 12 bit, 011: 16 bit, 100: 20 bit, 101: 24 bit, 110: 28 bit, 111: 32 bit)
	--bits 3:1 NFR number of frames to transmit, if NFR=0, transmits forever;
	--		Each frame is a pair of left-right data.
	--		Older data from fifo is sent first, MSB first for each channel)
	--bit 0: I2S_EN (write '1' to start, reset automatically)
	CR_in <= D when CR_wren='1' else CR_Q(31 downto 1) & '0';
	CR_ena <= '1';
	CR: d_flip_flop port map(D => CR_in,
									RST=> RST,
									CLK=> CLK,
									ENA=> CR_ena,
									Q=> CR_Q
									);
	
	--status register (write-only):
	--bit 7: LOCKED (pll of SCK_IN is locked)
	--bit 6: TX (I2S is transmitting)
	--bit 5: ROVF (right fifo is overflowing in this clock cycle)
	--bit 4: LOVF (left fifo is overflowing in this clock cycle)
	--bit 3: REMP (right fifo is empty)
	--bit 2: LEMP (left fifo is empty)
	--bit 1: RFULL (right fifo is full)
	--bit 0: LFULL (left fifo is full)
	SR_in <= (31 downto 8 => '0') & SCK_IN_PLL_LOCKED & i2s_tx & right_overflow &
				left_overflow & right_empty & left_empty & right_full & left_full;
	SR_ena <= '1';--always writes, updating status register
	SR: d_flip_flop port map(D => SR_in,
									RST=> RST,
									CLK=> CLK,
									ENA=> SR_ena,
									Q=> SR_Q
									);

-------------------------- address decoder ---------------------------------------------------
	all_periphs_output	<= (3 => irq_ctrl_Q,	2 => SR_Q,	1 => DR_out,	0 => CR_Q);

	irq_ctrl_rden	<= all_periphs_rden(3);-- not used, just to keep form
	SR_rden			<= all_periphs_rden(2);-- not used, just to keep form
	DR_rden			<= all_periphs_rden(1);-- not used, just to keep form
	CR_rden			<= all_periphs_rden(0);-- not used, just to keep form

	irq_ctrl_wren	<= all_periphs_wren(3);
	SR_wren			<= all_periphs_wren(2);--not used, just to keep form
	DR_wren			<= all_periphs_wren(1);
	CR_wren			<= all_periphs_wren(0);
	memory_map: address_decoder_memory_map
	--N: word address width in bits
	--B boundaries: list of values of the form (starting address,final address) of all peripherals, written as integers,
	--list MUST BE "SORTED" (start address(i) < final address(i) < start address (i+1)),
	--values OF THE FORM: "(b1 b2..bN 0..0),(b1 b2..bN 1..1)"
	generic map (N => 3, B => ranges)
	port map (	ADDR => ADDR,-- input, it is a word address
			RDEN => RDEN,-- input
			WREN => WREN,-- input
			data_in => all_periphs_output,-- input: outputs of all peripheral
			RDEN_OUT => all_periphs_rden,-- output
			WREN_OUT => all_periphs_wren,-- output
			data_out => Q-- data read
	);
end structure;
