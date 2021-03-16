--Average of 13 data
--Epsilon
--Final Evidence (Chika Shioriko XVI)*
--CDMX 11/03/2021
--*Personal code name, ignore

library ieee;
use ieee.std_logic_1164.all;
use ieee.Numeric_Std.all;		--To convert int to unsigned or vice versa


Entity PROMEDIO is
	Port(
		RX : in std_logic;							--Receive from accel drive with inside TXSERIAL bridge
		CLK : in std_logic;							--Clock 50Mhz
		R : in std_logic;								--Reset
		P : out std_logic_vector(7 downto 0);	--Average data output
		E : out std_logic								--Enable for TX serial output
	);
end PROMEDIO;

Architecture behavior of PROMEDIO is
	Component RXSERIAL is
		Port(
			CLK 	: in std_logic;
			R		: in std_logic;
			RX 	: in std_logic;
			D 		: out std_logic_vector (7 downto 0);
			S		: out std_logic
			);
	end component;
	
	Signal D	: std_logic_vector (7 downto 0);		--Signal Recieve component RXSERIAL Data	
	Signal S : std_logic;								--Stop signal from RXSERIAL
	signal s_ant : std_logic;							--Signal to save previous S signal
	
	type state_type is (START, RECEIVE, SEND);	--State machine
	signal estado : state_type;
	
Begin
	U0 : RXSERIAL port map (CLK, R, RX, D, S);	--Iniside receiver serial
	
	process(R, S, CLK)
		variable counter : integer := 0;				--Counter for 13 data recived
		variable data : integer := 0;					--To convert and save data
		variable promedio : integer := 0;			--Average data
	Begin
		--if reset is on
		if (R = '1') then
			P <= "00000000";
		elsif (rising_edge(CLK)) then
			case estado is
				when START =>
					E <= '1';		--Enable
					--If Stop signal pulse change
					if(S = '0' and s_ant = '1') then
						estado <= RECEIVE;
						counter := 0;
						data := 0;
					end if;
				when RECEIVE =>
					E <= '0';
					--If Stop signal pulse change
					if(S = '1' and s_ant = '0') then
						data := data + to_integer(unsigned(D)); --Convert data to interger and sum them
						counter := counter + 1;			
						--Count to 13 data
						if (counter = 13) then
							estado <= SEND;
						else
							estado <= estado;
						end if;
					end if;
				when SEND =>
					E <= '1';		--Enable
					estado <=START;
					promedio := data / 13;		--Average 13 data
					P <= std_logic_vector(to_unsigned(promedio,8)); --Convert average to unsigned
				when others =>
					estado <= START;
			end case;
			s_ant <= S;				--Save S signal to know when theres a pulse change
		end if;
	end process;
end behavior;