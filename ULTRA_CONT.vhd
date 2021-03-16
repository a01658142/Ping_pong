--Ultrasonic sensor driver
--Epsilon
--Final Evidence (Chika Shioriko XVI)*
--CDMX 11/03/2021
--*Personal code name, ignore

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;    --To convert int to unsigned or vice versa

Entity ULTRA_CONT is
	Port(
		CLK 	: in std_logic;							--Clock 50Mhz from FPGA
		T 		: out std_logic;							--Trigger to sensor
		E 		: in std_logic;							--Eccho from sensor
		R 		: in std_logic;							--Reset switch
		S 		: out std_logic;							--Led to show there's new data at D
		edo   : out std_logic_vector (6 downto 0);--Test states 7 segment
		D 		: out std_logic_vector(7 downto 0)	--Data output
	);
end ULTRA_CONT;

Architecture behavior of ULTRA_CONT is
	component DIVISOR is 
		generic(
			P : integer := 25000000		--Default. To change CLK from 50 MHz to 1 Hz
			);
		port(
			CLK 		: in std_logic;	--Clock 50Mhz input
			CLK_OUT 	: out std_logic	--Clock output
			);
	end component;
	
	Component DECODER is
	Port(
		I 	: in std_logic_vector (3 downto 0);		--Número de 4 bits
		S 	: out std_logic_vector (6 downto 0)		--Salida de 7 segmentos
		);
	end component;
	
	type state_type is (IDLE, START, WAVE, ECHO, SEND);--State machine
	signal estado : state_type;
	
	signal clk_2 : std_logic;									--Clock 1Hz
	signal echo_ant : std_logic;								--Signal previous pulse of eccho
	signal edoN : std_logic_vector (3 downto 0);			--signal for the test states to 7 segments
	
Begin
	U0 : DIVISOR generic map (250) port map (CLK, clk_2); -- 100k (ultrasonic works with 40Mhz)
	process(clk_2, R)
		variable cont : integer :=0;	--counter for received bit
	Begin
		--If reset is on 
		if (R ='1') then
			estado <= IDLE;
		elsif(rising_edge(clk_2)) then
			case estado is
				when IDLE =>
					T <= '0';
					S <= '0';
					cont := 0;				--Initialize received bit
					estado <= START;
				when START =>
					T <= '1';				--Activate trigger
					S <= '0';
					estado <= WAVE;
				when WAVE =>
					T <= '0';
					S <= '0';
					--if Eccho pulse change to recieve waves on sensor
					if(E = '1' and echo_ant = '0') then
						estado <= ECHO;
					else
						estado <= estado;
					end if;
				when ECHO =>
					cont := cont + 1;		--Counts the recieved bit
					T <= '0';
					S <= '0';
					--if Eccho pulse change when finish receiving waves
					if(E='0' and echo_ant = '1') then
						estado <= SEND;
						cont := cont;
					else
						estado <= estado;
					end if;
				when SEND =>
					D <= std_logic_vector(to_unsigned(cont, 8)); --Convert bit to vector and send data
					S <= '1';	--Led show there's new data
				when others =>
					estado <= IDLE;
			end case;
			echo_ant <= E;		--Signal previous Eccho to know there's a change
		end if;
	end process;
	--Test for states to 7 segment display 
	edoN <=  "0001" when estado = IDLE else
				"0001" when estado = START else
				"0001" when estado = WAVE else
				"0001" when estado = ECHO else
				"0100" when estado = SEND else
				"0001";
	U1 : DECODER port map (edoN, edo); --Decoder 7 segment
end behavior;