--------------------------------------------------
--smart fifo component
--by Renan Picoli de Souza
--8 stages fifo
--32 bit data
--oldest data is always at 0 position
--newest data is above the position of the previous, like a stack
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
			CLK: in std_logic;
			RST: in std_logic;
			WREN: in std_logic;--enables software write
			POP: in std_logic;--tells the fifo to move oldest data to position 0 if there is valid data
			DATA_OUT: out std_logic_vector(31 downto 0)--oldest data
	);
end smart_fifo;


architecture structure of smart_fifo is
--older data is available at position 0
--pop: tells the fifo to move oldest data to position 0 if there is valid data
signal head: std_logic_vector(2 downto 0);--points to the position where newest data should arrive
signal tail: std_logic_vector(2 downto 0);--points to the position where oldest valid data
signal fifo: array32(7 downto 0);

begin

	process(RST,DATA_IN,CLK,POP,WREN)
	begin
		if(RST='1')then
			--reset fifo
			fifo <= (others=>(others=>'0'));
			head<="000";
			tail<="000";
		elsif(falling_edge(CLK)) then--falling edge because data is latched in rising edge
			if (WREN='1' and POP='0') then
				fifo(to_integer(unsigned(head))) <= DATA_IN;
				head <= head + 1;
			elsif (WREN='1' and POP='1'and tail>"000") then
				fifo <= DATA_IN & fifo(7 downto 1);
				tail <= tail - 1;
			elsif (WREN='0' and POP='1' and tail>"000") then
				fifo <= x"0000_0000" & fifo(7 downto 1);
				tail <= tail - 1;
			end if;
		end if;
	end process;
	
	DATA_OUT <= fifo(0);
	
end structure;