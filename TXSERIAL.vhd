--Serial transmitter
--Epsilon
--Final Evidence (Chika Shioriko XVI)*
--CDMX 11/03/2021
--*Personal code name, ignore

library ieee;
use ieee.std_logic_1164.all;


Entity TXSERIAL is
	Port(
		CLK 	: in std_logic; --clock
		D 		: in std_logic_vector (7 downto 0);--data
		E 		: in std_logic;--enable
		R		: in std_logic;--reset
		RJ		: in std_logic;--resetGame
		TX 	: out std_logic--serial T
		);
end TXSERIAL;

Architecture behavior of TXSERIAL is
	signal clk_2 : std_logic;
	type state_type is (IDLE, START, SEND, STOP);
	signal estado : state_type;
Begin

	--Divisor of the frecuency baud rate
	process (clk)
		variable cont : integer := 0;
	Begin
		if (rising_edge (CLK)) then
			cont := cont + 1;
			if (cont = (50000000)/(2*9600)) then
				cont := 0;
				clk_2 <= not clk_2;
			end if;
		end if;
	end process;
	
	process (clk_2,R)
		variable d_bit : integer range 0 to 8;
		variable d_copy : std_logic_vector (7 downto 0);--Copy safe Data
	Begin
		if (R = '1') then
			estado <= IDLE;
			TX <= '1';
		elsif (rising_edge (clk_2)) then
			case estado is
				when IDLE =>
					d_bit := 0;
					TX <= '1';
					if (E = '1') then
						estado <= START;
						if(D = "10101010") then
							d_copy := D(7 downto 3) & "0" & D(1 downto 0);
						elsif (RJ = '1') then
							d_copy := "10101010";
						else
							d_copy := D;
						end if;
					else
						estado <= estado;
					end if;
				when START =>
					TX <= '0';
					estado <= SEND;
				when SEND =>
					TX <= d_copy(d_bit);
					if (d_bit = 7) then		--7 bit sent
						estado <= STOP;
					else
						d_bit := d_bit + 1;
						estado <= estado;
					end if;
				when STOP =>
					TX <= '0';
					if (E='0') then 			
						estado <= IDLE;
					else
						estado <= estado;
					end if;
				when others =>
					if (E='0') then 			--Enable hold
						estado <= IDLE;
					else
						estado <= estado;
					end if;
					TX <= '1';
			end case;
		end if;
	end process;
end behavior;