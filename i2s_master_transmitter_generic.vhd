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
			DR_in_shift: buffer std_logic_vector(31 downto 0);--data received, will be shifted into DR
			DR_shift: out std_logic;--DR must shift left N bits to make room for new word
			CLK_IN: in std_logic;--clock input, divided by 2 to generate SCK
			RST: in std_logic;--reset
			I2S_EN: in std_logic;--enables transfer to start
			WORDS: in std_logic_vector(1 downto 0);--controls number of words to receive or send (MSByte	first, MSB first)
			IACK: in std_logic_vector(1 downto 0);--interrupt request: 0: successfully transmitted all words; 1: NACK received
			IRQ: out std_logic_vector(1 downto 0);--interrupt request: 0: successfully transmitted all words; 1: NACK received
			SD: buffer std_logic;--data line
			WS: buffer std_logic;--left/right clock
			SCK: buffer std_logic--continuous clock (bit clock)
	);
end i2s_master_transmitter_generic;

architecture structure of i2s_master_transmitter_generic is

	signal fifo_sd_out: std_logic_vector(N-1 downto 0);--data to write on SD: one byte plus stop bit
	signal fifo_SD_in: std_logic_vector(N-1 downto 0);-- data read from SD: one byte plus start and stop bits
	
	--signals representing I2S transfer state
	signal tx: std_logic;--flag indicating it is transmitting (address or data)
	signal tx_addr: std_logic;--flag indicating it is transmitting address
	signal tx_data: std_logic;--flag indicating it is transmitting data
	signal ack: std_logic;--active HIGH, indicates the state when ack should be sent or received
	signal ack_addr: std_logic;--active HIGH, indicates the state when ack of address should be received
	signal ack_data: std_logic;--active HIGH, indicates the state when ack of word (byte) should be sent or received
	signal ack_received: std_logic;--active HIGH, indicates slave-receiver acknowledged
	signal ack_addr_received: std_logic;--active HIGH, indicates slave-receiver acknowledged
	signal start: std_logic;-- indicates start bit being transmitted (also applies to repeated start)
	signal stop: std_logic;-- indicates stop bit being transmitted
	
	--signals inherent to this implementation
	signal parallel_data_in: std_logic_vector(N-1 downto 0);--data to write on SD: one word
	signal load: std_logic;--load shift register asynchronously
	signal I2S_EN_stretched: std_logic;
	signal WS_delayed: std_logic;
	signal CLK: std_logic;--used to generate SCK (when sck_en = '1')
	
	signal ack_finished: std_logic;--active HIGH, indicates the ack was high in previous SCK cycle [0 1].
	signal CLK_IN_n: std_logic;-- not CLK
	signal bits_sent: natural;--number of bits transmitted
	signal words_sent: natural;--number of words(bytes) transmitted
	
	signal sck_en: std_logic;--enables SCK to follow CLK
	
begin
--	tx <= tx_addr or tx_data;
--	ack <= ack_addr or ack_data;

	---------------start flag generation----------------------------
--	process(RST,I2S_EN_stretched,tx)
--	begin
--		if (RST ='1') then
--			start	<= '0';
--		elsif (tx='1') then
--			start	<= '0';
--		--falling_edge e rising_edge don't need to_x01 because it is already used inside these functions
--		elsif	(falling_edge(I2S_EN_stretched)) then
--			start <= '1';
--		end if;
--	end process;
--	
--	---------------I2S_EN_stretched flag generation----------------------------
--	process(RST,CLK,I2S_EN)
--	begin
--		if (RST ='1') then
--			I2S_EN_stretched	<= '0';
--		elsif (I2S_EN='1') then
--			I2S_EN_stretched	<= '1';
--		elsif	(falling_edge(CLK)) then
--			I2S_EN_stretched <= '0';
--		end if;
--	end process;
	
	---------------WS_delayed generation----------------------------
	process(RST,SCK,WS)
	begin
		if (RST ='1') then
			WS_delayed	<= '0';
		elsif	(rising_edge(SCK)) then
			WS_delayed <= WS;
		end if;
	end process;
	
	---------------stop flag generation----------------------------
	----------stop flag will be used to drive SD,SCK--------------
--	process(RST,ack,ack_received,ack_finished,SD,SCK,words_sent,WORDS)
--	begin
--		if (RST ='1') then
--			stop	<= '0';
--		elsif	((ack='0' and words_sent=to_integer(unsigned(WORDS))+1) or
--				(ack='0' and ack_finished='1' and ack_received='0' and SCK='0'))--implicitly samples ack_received at falling_edge of ack
--				then
--			stop <= '1';
--		elsif (rising_edge(SD) and SCK='1') then
--			stop	<= '0';
--		end if;
--	end process;
	
	---------------load generation----------------------------
	load <= WS xor WS_delayed;
	
	---------------tx_data flag generation----------------------------
--	process(tx_data,ack,ack_received,bits_sent,words_sent,WORDS,SCK,RST,stop)
--	begin
--		if (RST ='1' or stop='1') then
--			tx_data	<= '0';
--		elsif (tx_data='1' and ack='1' and bits_sent=N) then
--			tx_data	<= '0';
--		elsif	(ack='1' and ack_received='1' and (words_sent/=to_integer(unsigned(WORDS))+1) and falling_edge(SCK)) then
--			tx_data <= '1';
--		end if;
--	end process;
	
	---------------SCK generation----------------------------
	process(start,stop,SCK,tx,CLK,RST)
	begin
		if (RST ='1') then
			sck_en	<= '0';
		elsif (stop = '1' and SCK = '1') then
			sck_en	<= '0';
		elsif	((start='1' or tx ='1') and falling_edge(CLK)) then
			sck_en <= '1';
		end if;
	end process;
	CLK <= CLK_IN;
	SCK <= CLK when (sck_en = '1') else '1';

	---------------SD write----------------------------
	--serial write on SD bus
	serial_w: process(start,SCK,fifo_sd_out,RST,stop)
	begin
		if (RST ='1' or start = '1' or stop='1') then
			SD <= '0';
		elsif(falling_edge(SCK))then--SD is driven using the fifo, which updates at falling_edge of SCK
			SD <= fifo_sd_out(N-1);--sends the MSbit of fifo_sd_out
		end if;
	end process;
	
	---------------fifo_sd_out write-----------------------------
	fifo_w: process(RST,load,SCK,stop)
	begin
		if (RST ='1'  or stop='1') then
			fifo_sd_out <= (others => '0');
		elsif (load='1') then
			fifo_sd_out <= parallel_data_in;
		--updates fifo at falling edge of SCK so it can be read at rising_edge of SCK
		elsif(falling_edge(SCK))then
			fifo_sd_out <= fifo_sd_out(N-2 downto 0) & '0';--MSB is sent first
		end if;

	end process;
	
--	bits_sent_w: process(RST,stop,ack,tx,SCK)
--	begin
--		if (RST ='1' or stop='1') then
--			bits_sent <= 0;
--		elsif(ack='1') then
--			bits_sent <= 0;
--		elsif(tx='1' and rising_edge(SCK))then
--			bits_sent <= bits_sent + 1;
--		end if;
--	end process;
--	
--	process(RST,stop,ack_data,fifo_SD_in,DR_in_shift)
--	begin
--		if (RST ='1' or stop='1') then
--			DR_in_shift <= (others=>'0');
--		elsif(rising_edge(ack_data)) then
--			DR_in_shift <= (31 downto N =>'0') & fifo_SD_in;
--		end if;
--	end process;
--	
--	---------------words_sent write-----------------------------
--	process(RST,I2S_EN,tx_data,ack,stop)
--	begin
--		if (RST ='1' or stop='1') then
--			words_sent <= 0;
--		elsif (I2S_EN = '1') then
--			words_sent <= 0;
--		elsif (stop = '1') then
--			words_sent <= 0;
--		elsif(rising_edge(ack) and tx_data='1')then
--			words_sent <= words_sent + 1;
--			if (words_sent = to_integer(unsigned(WORDS))+1) then
--				words_sent <= 0;
--			end if;
--		end if;
--
--	end process;
--	
--	---------------ack_addr flag generation----------------------
--	process(tx_addr,bits_sent,SCK,RST,stop)
--	begin
--		if (RST ='1' or stop='1') then
--			ack_addr <= '0';
--		elsif	(falling_edge(SCK)) then
--			if (tx_addr='1' and bits_sent=N) then
--				ack_addr <= '1';
--			else
--				ack_addr <= '0';
--			end if;
--		end if;
--	end process;
--	
--	---------------ack_data flag generation----------------------
--	--ack data phase: master or slave should acknowledge, depending on ADDR(0)
--	--a single N-bit word was sent-------------------
--	process(tx_data,bits_sent,SCK,RST,stop)
--	begin
--		if (RST ='1' or stop='1') then
--			ack_data <= '0';
--		elsif	(falling_edge(SCK)) then
--			if (tx_data='1' and bits_sent=N) then
--				ack_data <= '1';
--			else
--				ack_data <= '0';
--			end if;
--		end if;
--	end process;
--
--	---------------ack_received flag generation----------------------------
--	process(ack,ack_received,SCK,SD,RST,stop)
--	begin
--		if (RST ='1' or stop='1') then
--			ack_received <= '0';
--			--to_x01 converts 'H','L' to '1','0', respectively. Needed only IN SIMULATION
--		elsif	(rising_edge(SCK)) then
--			ack_received <= ack and not(to_x01(SD));
--		end if;
--	end process;
--	
--	---------------ack_finished flag generation----------------------------
--	ack_f: process(ack,SCK,SD,RST,stop)
--	begin
--		if (RST ='1') then
--			ack_finished <= '0';
--		elsif (SCK='1') then
--			ack_finished <= '0';
--		elsif	(falling_edge(SCK)) then
--			ack_finished <= ack;--active HIGH, indicates the ack was high in previous SCK cycle [0 1].
--		end if;
--	end process;
--	
--	---------------IRQ BTF----------------------------
--	---------byte transfer finished-------------------
--	----transmitted all words successfully------------
--	process(RST,IACK,stop,words_sent,WORDS)
--	begin
--		if(RST='1') then
--			IRQ(0) <= '0';
--		elsif (IACK(0) ='1') then
--			IRQ(0) <= '0';
--		elsif(rising_edge(stop) and (words_sent=to_integer(unsigned(WORDS))+1)) then
--			IRQ(0) <= '1';
--		end if;
--	end process;
--	
--	---------------IRQ NACK---------------------------
--	-------------NACK received------------------------
--	process(RST,IACK,ack,ack_finished,ack_received,ack_addr_received,stop,SCK)
--	begin
--		if(RST='1') then
--			IRQ(1) <= '0';
--		elsif (IACK(1) ='1') then
--			IRQ(1) <= '0';
--		elsif(ack='0' and ack_finished='1' and ack_received='0'
--					and not(stop='1') and SCK='0') then
--			IRQ(1) <= '1';
--		end if;
--	end process;

	
end structure;