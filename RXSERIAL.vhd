--Serial transmitter
--Epsilon
--Final Evidence (Chika Shioriko XVI)*
--CDMX 11/03/2021
--*Personal code name, ignore

library ieee;
use ieee.std_logic_1164.all;


Entity RXSERIAL is
	Port(
		CLK 	: in std_logic;                     --Clock 50Mhz
		R		: in std_logic;                     --Reset
		RX 	: in std_logic;                     --Serial R
		D 		: out std_logic_vector (7 downto 0);--Data
		S		: out std_logic                     --ready
		);
end RXSERIAL;

Architecture behavior of RXSERIAL is
	--signals
	signal clk_2 : std_logic;
	type state_type is (IDLE, RECEIVE, STOP);--for state machine
	signal estado : state_type;
	signal estado_anterior : std_logic;--state before
Begin

	--Divisor for the frecuency baud rate
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
	--state machine
	process (clk_2,R)
		variable d_bit : integer range 0 to 8;
		variable d_copy : std_logic_vector (7 downto 0);--Copy safe for data
		
	Begin
		if (R = '1') then
			estado <= IDLE;
		elsif (rising_edge (clk_2)) then
			case estado is
				when IDLE =>
					S <= '0';
					d_bit := 0;
					if (RX = '0' and estado_anterior = '1') then	
						estado <= RECEIVE;
					else
						estado <= estado;
					end if;
					estado_anterior <= RX;
				when RECEIVE =>
					S <= '0';
					d_copy(d_bit) := RX;
					if (d_bit = 7) then		--7 bit sent
						estado <= STOP;
					else
						d_bit := d_bit + 1;
						estado <= estado;
					end if;
				when STOP =>
					if (RX = '1') then
						estado <= IDLE;
						D <= d_copy;
						S <= '1';
					else
						estado <= estado;
					end if;
					
				when others =>
					estado <= IDLE;
			end case;
		end if;
	end process;
end behavior;