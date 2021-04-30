library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all;
--use work.my_types.all;

entity testbench is
end testbench;

architecture test of testbench is
-- internal clock period.
constant TIME_DELTA : time := 20 ns;

--reset duration must be long enough to be perceived by the slowest clock (filter clock, both polarities)
constant TIME_RST : time := 5 us;

--component i2s_slave_receiver --TO-DO
--	port (
--			D: in std_logic_vector(31 downto 0);--for register write
--			ADDR: in std_logic_vector(1 downto 0);--address offset of registers relative to peripheral base address
--			CLK: in std_logic;--for register read/write, also used to generate SCL
--			RST: in std_logic;--reset
--			WREN: in std_logic;--enables register write
--			RDEN: in std_logic;--enables register read
--			IACK: in std_logic;--interrupt acknowledgement
--			Q: out std_logic_vector(31 downto 0);--for register read
--			IRQ: out std_logic;--interrupt request
--			SDA: inout std_logic;--open drain data line
--			SCL: inout std_logic --open drain clock line
--	);
--end component;

---------------------------------------------------
--produces 12MHz from 50MHz
component pll_12MHz
	port
	(
		areset		: in std_logic  := '0';
		inclk0		: in std_logic  := '0';
		c0				: out std_logic 
	);
end component;

---------------------------------------------------
--produces fs and 256fs from 12MHz
component pll_audio
	port
	(
		areset		: in std_logic  := '0';
		inclk0		: in std_logic  := '0';
		c0		: out std_logic;
		c1		: out std_logic;
		locked		: out std_logic
	);
end component;

---------------------------------------------------

--master signals
signal D: std_logic_vector(31 downto 0);--for register write
signal CLK: std_logic;--for register read/write, also used to generate SCL
signal ADDR: std_logic_vector(2 downto 0);--address offset of registers relative to peripheral base address
signal RST:	std_logic;--reset
signal WREN: std_logic;--enables register write
signal RDEN: std_logic;--enables register read
signal IACK: std_logic;--interrupt acknowledgement
signal Q: std_logic_vector(31 downto 0);--for register read
signal IRQ: std_logic;--interrupt request
signal SD: std_logic;--data line
signal WS: std_logic;--word select (left/right clock)
signal SCK: std_logic;--bit clock
signal SCK_IN: std_logic;--clock for SCK generation (must be 256*fs, because SCK_IN is divided by 2 to generate SCK)
signal SCK_IN_PLL_LOCKED: std_logic;--'1' if PLL that provides SCK_IN is locked


signal CLK22_05kHz: std_logic;-- 22.05kHz clock
signal CLK2_8235295MHz: std_logic;-- 2.8235295MHz clock (for I2S peripheral)
signal CLK12MHz: std_logic;-- 12MHz clock (MCLK for audio codec)
signal ram_clk: std_logic;

--slave signals
--signal D_slv: std_logic_vector(31 downto 0);--for register write
--signal ADDR_slv: std_logic_vector(1 downto 0);--address offset of registers relative to peripheral base address
--signal WREN_slv: std_logic;--enables register write

begin
	SCK_IN <= CLK2_8235295MHz;
	ram_clk <= not CLK;
	DUT: entity work.i2s_master_transmitter
	port map(D 		=> D,
				CLK	=> ram_clk,
				ADDR 	=> ADDR,
				RST	=>	RST,
				WREN	=> WREN,
				RDEN	=>	RDEN,
				IACK	=> IACK,
				Q		=>	Q,
				IRQ	=>	IRQ,
				SD		=>	SD,
				WS		=> WS,
				SCK_IN	=> SCK_IN,
				SCK_IN_PLL_LOCKED => SCK_IN_PLL_LOCKED,--'1' if PLL that provides SCK_IN is locked
				SCK	=>	SCK
	);
	
--	slave: i2c_slave
--	port map(D 		=> D_slv,
--				CLK	=> CLK,
--				ADDR 	=> ADDR_slv,
--				RST	=>	RST,
--				WREN	=> WREN_slv,
--				RDEN	=>	RDEN,
--				IACK	=> IACK,
--				Q		=>	open,
--				IRQ	=>	open,
--				SDA	=>	SDA,
--				SCL	=>	SCL
--	);
	
	clock: process--50MHz input clock (common to slave and master)
	begin
		CLK <= '0';
		wait for 10 ns;
		CLK <= '1';
		wait for 10 ns;
	end process clock;
	
	--I2S registers configuration	
	master_setup:process
	begin
		wait for TIME_RST+(TIME_DELTA/2);
		
		--writes to left fifo
		--zeroes & LRFS & DS[2:0] & NFR[2:0] & I2S_EN
		ADDR <= "000";--CR address
		D <= (31 downto 8 =>'0') & '0' & "011" & "010" & '0';--configura CR: seleciona left fifo, DS 16 bits, 2 frames, aguardando início
		WREN <= '1';
		wait for TIME_DELTA;
		
		--bits 7:0 data to be transmitted (goes to fifo)
		ADDR <= "001";--DR address	
		D <= x"0000_0F0F";
		WREN <= '1';
		wait for TIME_DELTA;
		
		--bits 7:0 data to be transmitted (goes to fifo)
		ADDR <= "001";--DR address	
		D <= x"0000_F0F0";
		WREN <= '1';
		wait for TIME_DELTA;

		
		--writes to right fifo
		--zeroes & LRFS & DS[2:0] & NFR[2:0] & I2S_EN
		ADDR <= "000";--CR address
		D <= (31 downto 8 =>'0') & '1' & "011" & "010" & '0';--configura CR: seleciona right fifo, DS 16 bits, 2 frames, aguardando início
		WREN <= '1';
		wait for TIME_DELTA;
		
		--bits 7:0 data to be transmitted (goes to fifo)
		ADDR <= "001";--DR address	
		D <= x"0000_0F0F";
		WREN <= '1';
		wait for TIME_DELTA;
		
		--bits 7:0 data to be transmitted (goes to fifo)
		ADDR <= "001";--DR address	
		D <= x"0000_F0F0";
		WREN <= '1';
		wait for TIME_DELTA;

		WREN <= '0';
		--waits  until pll_audio locks
		wait until rising_edge(SCK_IN_PLL_LOCKED);
		wait until falling_edge(CLK);

		--zeroes & LRFS & DS[2:0] & NFR[2:0] & I2S_EN
		ADDR <= "000";--CR address, will start transfer
		D<=(31 downto 8 =>'0') & '1' & "011" & "010" & '1';--I2S_EN: 1; NFR: 100 (4); DS: 000 (4)
		WREN <= '1';
		wait for TIME_DELTA;
		
--		--nop
--		WREN <= '0';		
--		wait for 7*TIME_DELTA;
--		
--		--bits 7:0 data to be transmitted (goes to fifo)
--		ADDR <= "01";--DR address	
--		D <= x"0000_0009";
--		WREN <= '1';
--		wait for TIME_DELTA;
--		
--		--nop
--		WREN <= '0';		
--		wait for 3*TIME_DELTA;
--		
--		--bits 7:0 data to be transmitted (goes to fifo)
--		ADDR <= "01";--DR address	
--		D <= x"0000_000A";
--		WREN <= '1';
--		wait for TIME_DELTA;
--		
--		--nop
--		WREN <= '0';		
--		wait for 1*TIME_DELTA;
--		
--		--bits 7:0 data to be transmitted (goes to fifo)
--		ADDR <= "01";--DR address	
--		D <= x"0000_000B";
--		WREN <= '1';
--		wait for TIME_DELTA;
		
		WREN <= '0';
		wait for 125 us;
		ADDR <= "100";-- irq controller address	
		D <= x"0000_0000";--zeroes irq line 0
		WREN <= '1';
		wait for TIME_DELTA;
		WREN <= '0';
--		ADDR <= "00";--CR address, will start transfer
--		D<=(31 downto 8 =>'0') & '0' & "000" & "100" & '1';--I2S_EN: 1; NFR: 100 (4); DS: 000 (4)
--		WREN <= '1';
--		wait for TIME_DELTA;
--		WREN <= '0';
		wait;--process executes once
	end process master_setup;
	
--	slave_setup:process
--	begin
--		--zeroes & WORDS & OADDR & R/W(must store RW bit sent by master; 1 read mode; 0 write mode)
--		ADDR_slv <= "00";--CR address
--		D_slv <= (31 downto 10 =>'0') & "01" & "0000101" & 'X';--WORDS: 01; OADDR: 0101
--		WREN_slv <= '1';
--		wait for TIME_RST + TIME_DELTA;
--		
--		ADDR_slv <= "01";--DR address
--		--bits 7:0 data received or to be read by master	
--		D_slv <= x"0000_00A4";-- data to be read by master
--		WREN_slv <= '1';
--		wait for TIME_DELTA;
--
--		ADDR_slv<="11";--invalid address
--		D_slv<=(others=>'0');
--		WREN_slv <= '0';
--		wait for TIME_DELTA;
--		wait;--process executes once
--	end process slave_setup;
	
	RST <= '1', '0' after TIME_RST;--reset common to slave and master
--	IACK <= '0', '1' after 300 us, '0' after 310 us;

	--produces 12MHz (MCLK) from 50MHz input
	clk_12MHz: pll_12MHz
	port map (
	inclk0 => CLK,
	areset => rst,
	c0 => CLK12MHz
	);

	--produces 22059Hz (fs) and 2.8235295MHz (128fs for BCLK_IN) from 12MHz input
	clk_fs_128fs: pll_audio
	port map (
	inclk0 => CLK12MHz,
	areset => rst,
	c0 => CLK22_05kHz,
	c1 => CLK2_8235295MHz,
	locked => SCK_IN_PLL_LOCKED
	);
	
end architecture test;
