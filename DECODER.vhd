--DECODER to 7 segments
--Epsilon
--Final Evidence (Chika Shioriko XVI)*
--CDMX 11/03/2020
--*Personal code name, ignore

library ieee;
use ieee.std_logic_1164.all;

Entity DECODER is
	Port(
		I 	: in std_logic_vector (3 downto 0);		--4 bist number
		S 	: out std_logic_vector (6 downto 0)		--Output 7 segments
		);
end DECODER;

Architecture behavior of DECODER is
	Signal S_TEMP : std_logic_vector (6 downto 0);	--Signal with the output before its denied
Begin
	S_TEMP <= 	"0111111" when I = "0000" else	--0
					"0000110" when I = "0001" else	--1
					"1011011" when I = "0010" else	--2
					"1001111" when I = "0011" else	--3
					"1100110" when I = "0100" else	--4
					"1101101" when I = "0101" else	--5
					"1111101" when I = "0110" else	--6
					"0000111" when I = "0111" else	--7
					"1111111" when I = "1000" else	--8
					"1101111" when I = "1001" else	--9
					"1110111" when I = "1010" else	--10 (A)
					"1111100" when I = "1011" else	--11 (B)
					"0111001" when I = "1100" else	--12 (C)
					"1011110" when I = "1101" else	--13 (D)
					"1111001" when I = "1110" else	--14 (E)
					"1110001" when I = "1111" else	--15 (F)
					"0000000";								--others
					
	S <= not(S_TEMP); --Its denied because leds is on with 0, not with 1

end behavior;