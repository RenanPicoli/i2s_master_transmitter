--------------------------------------------------
--I2S master generic component
--by Renan Picoli de Souza
--sends data to SD bus and drives SCK clock and WS line
--supports only 8 bit sending/receiving
--Generates IRQs in following events:
--received NACK
--transmission ended (STOP)
--NO support for clock stretching
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;--std_logic types, to_x01
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;--to_integer

entity i2s_master_transmitter_generic is
	generic (N: natural);--number of bits in each word
	port (
			DR_out: in std_logic_vector(31 downto 0);--data to be transmitted
			CLK_IN: in std_logic;--clock input, divided by 2 to generate SCK
			RST: in std_logic;--reset
			I2S_EN: in std_logic;--enables transfer to start
			left_data: in std_logic_vector(31 downto 0);--left channel
			right_data: in std_logic_vector(31 downto 0);--right channel
			NFR: in std_logic_vector(2 downto 0);--controls number of frames to send (left channel	first, MSB first in each channel), 000 means unlimited
			IACK: in std_logic_vector(0 downto 0);--acknowledgement of interrupt request: successfully transmitted all words;
			IRQ: out std_logic_vector(0 downto 0);--interrupt request: successfully transmitted all words;
			pop: out std_logic;--requests another data to the fifo
			TX: out std_logic;-- indicates transmission
			SD: buffer std_logic;--data line
			WS: buffer std_logic;--left/right clock (0 left, 1 right)
			SCK: buffer std_logic--continuous clock (bit clock)
	);
end i2s_master_transmitter_generic;

architecture structure of i2s_master_transmitter_generic is

	component prescaler
	generic(factor: integer);
	port (CLK_IN: in std_logic;--input clock
			rst: in std_logic;--synchronous reset
			CLK_OUT: out std_logic--output clock
	);
	end component;
	
	signal fifo_sd_out: std_logic_vector(N-1 downto 0);--data to write on SD: one byte plus stop bit
	signal fifo_SD_in: std_logic_vector(N-1 downto 0);-- data read from SD: one byte plus start and stop bits
	
	--signals representing I2S transfer state
	signal start: std_logic;-- indicates start bit being transmitted (also applies to repeated start)
	signal stop: std_logic;-- indicates stop bit being transmitted
	signal stop_stretched: std_logic;-- indicates stop bit being transmitted (useful to send last bit)
	signal stop_stretched_2: std_logic;-- indicates stop bit being transmitted (useful to send last bit)
	
	--signals inherent to this implementation
	signal parallel_data_in: std_logic_vector(N-1 downto 0);--data to write on SD: one word
	signal load: std_logic;--load shift register asynchronously
	signal I2S_EN_delayed: std_logic;-- I2S_EN flag delayed one SCK clock cycle (for WS synchronizing)
	signal WS_delayed: std_logic;
	signal prescaler_out: std_logic;
	signal prescaler_rst: std_logic;--prescaler reset
	signal CLK: std_logic;--used to generate SCK (when sck_en = '1')
	
	signal SCK_n: std_logic;-- not SCK
	signal bits_sent: natural;--number of bits transmitted
	signal frame_number: natural;--number of the frame (pairs left-right data) being transmitted
	signal frame_number_delayed: natural;--needs a delay to be read after stop rising_edge
	
	signal sck_en: std_logic;--enables SCK to follow CLK
	
begin
	---------------start flag generation----------------------------
	process(RST,I2S_EN,CLK_IN)
	begin
		if (RST ='1') then
			start	<= '0';
		elsif (CLK_IN='0') then
			start	<= '0';
		--falling_edge e rising_edge don't need to_x01 because it is already used inside these functions
		elsif	(rising_edge(I2S_EN)) then
			start <= '1';
		end if;
	end process;

	process(RST,I2S_EN,SCK)
	begin
		if (RST='1' or I2S_EN='0') then
			I2S_EN_delayed <='0';
		elsif (falling_edge(SCK)) then
			I2S_EN_delayed <= I2S_EN;
		end if;
	end process;

	---------------WS generation----------------------------
	ws_gen: prescaler
	generic map (factor => 2*N)
	port map(CLK_IN	=> SCK_n,--because we need WS to change when SCK falls
				RST		=> prescaler_rst,
				CLK_OUT	=> prescaler_out
	);
	prescaler_rst <= RST or I2S_EN_delayed;
	
	---------------WS generation----------------------------
	process(RST,start,sck_en,prescaler_out)
	begin
		if(RST='1' or start='1') then
			WS <='0';
		else
			WS <= sck_en and (not prescaler_out);
		end if;
	end process;
	
	---------------WS_delayed generation---------------------
	process(RST,SCK,WS,sck_en)
	begin
		if (RST ='1' or sck_en='0') then
			WS_delayed	<= '0';
		elsif	(rising_edge(SCK)) then
			WS_delayed <= WS;-- and sck_en prevents load after end of transmission (WS might have a falling edge)
		end if;
	end process;
	
	---------------stop flag generation----------------------------
	----------stop flag will be used to drive SD,SCK--------------
	process(RST,SCK,frame_number,NFR,WS,WS_delayed)
	begin
		if (RST ='1') then
			stop	<= '0';
		elsif (WS_delayed='1' and SCK='1') then
			stop	<= '0';
		elsif	(frame_number=to_integer(unsigned(NFR)) and NFR/="000" and rising_edge(WS)) then
			stop <= '1';
		end if;
	end process;
		
	---------------stop_stretched flag generation----------------------------
	process(RST,CLK,stop)
	begin
		if (RST ='1') then
			stop_stretched	<= '0';
		elsif (stop='1') then
			stop_stretched	<= '1';
		elsif	(falling_edge(CLK)) then
			stop_stretched <= '0';
		end if;
	end process;
	
	---------------stop_stretched_2 flag generation----------------------------
	process(RST,CLK,stop_stretched)
	begin
		if (RST ='1') then
			stop_stretched_2	<= '0';
		elsif	(stop_stretched='0' and CLK='1') then
			stop_stretched_2 <= '0';
		elsif (rising_edge(stop_stretched)) then
			stop_stretched_2	<= '1';
		end if;
	end process;
	---------------load generation----------------------------
	load <= WS xor WS_delayed;
	
	--load is asserted at falling edge of CLK in and deasserted before when it rises, can't be detected smart_fifo
	--pop is generated by "stretching" load
	process(RST,load,CLK_IN)
	begin
		if (RST='1') then
		elsif (load='1') then
			pop <= '1';
		elsif (falling_edge(CLK_IN)) then
			pop <= '0';
		end if;
	end process;
	
	---------------TX flag generation----------------------------
	------this complex expression aims to make--------------------
	----the TX signal sampled at rising_edge perfectly aligned with bit transmission----
	process(RST,sck_en,stop_stretched,CLK)
	begin
		if (RST ='1') then
			TX	<= '0';
		elsif (falling_edge(CLK)) then
			TX	<= sck_en and not stop_stretched;
		end if;
	end process;
	
	---------------SCK generation----------------------------
	process(start,stop_stretched_2,CLK_IN,RST)
	begin
		if (RST ='1') then
			sck_en	<= '0';
		elsif	(start='1') then
			sck_en <= '1';
		elsif (falling_edge(stop_stretched_2)) then
			sck_en	<= '0';
		end if;
	end process;
	CLK <= CLK_IN;
	SCK <= CLK when (sck_en = '1') else '1';
	SCK_n <= not SCK;

	---------------SD write----------------------------
	--serial write on SD bus
	serial_w: process(start,SCK,fifo_sd_out,RST,stop_stretched_2)
	begin
		if (RST ='1' or start = '1') then
			SD <= '0';
		elsif(falling_edge(SCK))then--SD is driven using the fifo, which updates at falling_edge of SCK
			if (stop_stretched_2='1') then
				SD <= '0';
			else
				SD <= fifo_sd_out(N-1);--sends the MSbit of fifo_sd_out
			end if;
		end if;
	end process;
	
	---------------parallel_data_in write------------------------
	parallel_data_in <= (others=>'0') when (RST='1' or start='1') else
								right_data(N-1 downto 0) when WS='1' else
								left_data(N-1 downto 0);--when WS='0'
	
	---------------fifo_sd_out write-----------------------------
	fifo_w: process(RST,parallel_data_in,load,SCK,stop)
	begin
		if (RST='1' or load='1') then
			fifo_sd_out <= parallel_data_in;
		--updates fifo at falling edge of SCK so it can be read at rising_edge of SCK
		elsif(falling_edge(SCK))then
			fifo_sd_out <= fifo_sd_out(N-2 downto 0) & '0';--MSB is sent first
		end if;
	end process;
	
	---------------frame_number write-----------------------------
	frames_w: process(RST,WS,stop)
	begin
		if (RST ='1' or stop='1') then
			frame_number <= 0;
		elsif(rising_edge(WS))then
			frame_number <= frame_number + 1;
		end if;

	end process;
	
	process(RST,frame_number,CLK)
	begin
		if (RST='1') then
			frame_number_delayed <= 0;
		elsif (rising_edge(CLK)) then--rising_edge because stop rises in the falling edge
			frame_number_delayed <= frame_number;
		end if;		
	end process;
	
	---------------IRQ BTF----------------------------
	---------byte transfer finished-------------------
	----transmitted all words successfully------------
	process(RST,I2S_EN,IACK,frame_number_delayed,stop,NFR)
	begin
		if(RST='1') then
			IRQ(0) <= '0';
		elsif (IACK(0) ='1' or I2S_EN='1') then--if the processor decides not to acknowledge, clears the IRQ when new transmission starts
			IRQ(0) <= '0';
		elsif(rising_edge(stop) and (frame_number_delayed=to_integer(unsigned(NFR)))) then--if NFR=000, stop never rises
			IRQ(0) <= '1';
		end if;
	end process;
	
end structure;