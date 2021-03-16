--Frequency divisor
--Epsilon
--Final Evidence (Chika Shioriko XVI)*
--CDMX 11/03/2021
--*Personal code name, ignore

library ieee;
use ieee.std_logic_1164.all;

Entity DIVISOR is 
	generic(
		P : integer := 25000000		--Default is to change CLK from 50 MHz to 1 Hz
		);
	port(
		CLK 		: in std_logic;	--Clock 50Mhz input
		CLK_OUT 	: out std_logic	--Clock output
		);

end DIVISOR;


Architecture behavior of DIVISOR is
	signal CLK_TEMP : std_logic;	--temporal signal to change value
Begin
	process(CLK)
		variable counter : integer := 0;	--Counts the Pulses
	Begin
		if(rising_edge(CLK)) then
			counter := counter + 1;			--Plus 1 for each pulse above
			if(counter = P) then
				CLK_TEMP <= not CLK_TEMP;	--Change clock
				counter := 0;					--Reinitialize counter
			end if;
		end if;
	end process;
	
	CLK_OUT <= CLK_TEMP;						--Assign clk_out
	
end behavior;