--------------------------------------------------
--smart fifo component
--by Renan Picoli de Souza
--8 stages fifo
--32 bit data
--newest data is always at 0 position
--TO-DO implement validity bit
--TO-DO implement IRQ if tries to read from empty fifo
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;--addition of std_logic_vector
use ieee.numeric_std.all;--to_integer, unsigned
use work.my_types.all;--array32

entity smart_fifo is
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
end smart_fifo;


architecture structure of smart_fifo is
--newest data is available at position 0
--pop: tells the fifo that data at head was read and can be discarded
signal head: std_logic_vector(3 downto 0);--points to the position where oldest data should be read, MSB is a overflow bit
signal fifo: array32(0 to 7);
signal difference: std_logic_vector(31 downto 0);-- writes - readings
signal c_writes: std_logic_vector(31 downto 0);-- writes
signal c_readings: std_logic_vector(31 downto 0);-- readings

begin

	--write counter
	process(RST,WCLK,WREN,FULL)
	begin
		if(RST='1') then
			c_writes <= (others=>'0');
		elsif (rising_edge(WCLK) and WREN='1' and FULL='0') then		
			c_writes <= c_writes + '1';
		end if;
	end process;
	
	--read counter
	process(RST,RCLK,POP,EMPTY)
	begin
		if(RST='1') then
			c_readings <= (others=>'0');
		elsif (rising_edge(RCLK) and POP='1' and EMPTY='0') then		
			c_readings <= c_readings + '1';
		end if;
	end process;
	
	difference <= c_writes - c_readings - 1;
	
	--head(3) indicates overflow
	head_i: for i in 0 to 3 generate
		process(RST,difference)
		begin
			if (RST='1') then
				head(i) <= '1';--if RST then (head = -1)
			else
				head(i) <= difference(i);
			end if;
		end process;
	end generate head_i;
	
	--shift register writes
	process(RST,DATA_IN,WCLK,POP,WREN)
	begin
		if(RST='1')then
			--reset fifo
			fifo <= (others=>(others=>'0'));
		elsif(rising_edge(WCLK) and WREN='1') then--rising edge to detect pop assertion (command to shift data) or WREN (async load)
			fifo <= DATA_IN & fifo(0 to 6);
		end if;
	end process;
	
	--data_out assertion	
	DATA_OUT <= fifo(to_integer(unsigned(head(2 downto 0))));
	
--	FULL		<= head(3) and (not RST);
	process (RST,head)
	begin
		if(RST='1' or head="1111")then
			FULL <= '0';
		elsif (head(3)='1') then
			FULL <= '1';
		end if;
	end process;
	EMPTY		<= '1' when (head="0000" and c_writes=x"00000000") else '0';	
	OVF		<= head(3) and WREN and (not POP);--FULL and WREN='1' and POP='0'
	
end structure;