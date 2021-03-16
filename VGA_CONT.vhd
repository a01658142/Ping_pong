--VGA Color Bars
--Epsilon
--Final Evidence (Chika Shioriko XVI)*
--CDMX 11/03/2021
--*Personal code name, ignore

library ieee;
use ieee.std_logic_1164.all;
use ieee.Numeric_Std.all;  --To convert int to unsigned or vice versa

Entity VGA_CONT is
	port(	CLK: in std_logic;												--Clock 50Mhz
			SEL : in std_logic_vector (1 downto 0);					--Selector of with player scores from processing
			R_out, G_out, B_out: out std_logic_vector(3 downto 0);--4bits
			HS, VS: out std_logic);											--Horizontal and Vertical Sync
end VGA_CONT;	

Architecture behavior of VGA_CONT is
	signal clk_25, HS_int, VS_int: std_logic; 			--Clock 25Mhz, Horizontal interger and Vertical interger
	signal disp_x, disp_y: std_logic; 						--Horizontal and Vertical Display
	signal enBarra : std_logic;								--To know what color is
	signal contLinea : std_logic_vector(9 downto 0);	--Counter for vertical

begin
	--frequency division at 25MHz
	process(clk) --Clock 50MHz
	begin
		if(rising_edge(clk))then
			clk_25 <= not clk_25;
		else
			clk_25 <= clk_25;
		end if;
	end process;
	
	--HS generator
	process(clk_25)
		variable cont : integer:=0;    --counter horizontal pixels 
		variable linea : integer:=0;	 --counter vertical lines
		variable px: integer:=0;		 --counter pixels
		variable x0f : integer := 160; --final pixel of the first bar
		variable x2i : integer := 321; --initial pixel of the third bar
		variable x2f : integer := 480; --final pixel of the third bar
	begin
		if(rising_edge(clk_25))then
			cont := cont +1;
			linea:= to_integer(unsigned(contLinea));
			
			--condition pulse width
			if cont <=     96 then 
				HS_int<='0';
				disp_x<='0';
				px :=    0;
			
			--condition back porch	
			elsif cont <= 144 then 
				HS_int<='1';
				enBarra<='0';
				disp_x<='0';
			
			--condition tiempo display	
			elsif cont <= 784 then 
				HS_int <='1';
				disp_x <='1';
				px := px+1;
				enBarra <= '0'; 
				--If pixel gets to x0f(final of the first bar) then change color
				if(px <= x0f) then 
					enBarra <= '1';
				--If pixel its greater than x2i(initial pixel of third bar) and lesser than x2f(final pixel of third bar) then change color
				elsif(px>= x2i and px <= x2f)then
					enBarra <= '1';
				end if;
			
			--condition front porch	
			elsif cont <= 800 then 
				HS_int<='1';
				disp_x<='0';
				enBarra<='0';
			else
				HS_int<=HS_int;
				disp_x<='0';
				cont:=0;
				enBarra<='0';
			end if;
		end if;
	end process;
		
	process(HS_int)--VS PROCESs
		variable linea : integer:=0; 
	
		begin
		if(falling_edge(HS_int))then
			linea := linea + 1;
			contLinea <= std_logic_vector(to_unsigned(linea,10));
			if linea <=      2 then --condition pulse width
				VS_int<='0';
				disp_y<='0';
			elsif linea <=  31 then --condition back porch
				VS_int<='1';
				disp_y<='0';
			elsif linea <= 511 then --condition display time
				VS_int<='1';
				disp_y<='1';
			elsif linea <= 521 then --condition front porch
				VS_int<='1';
				disp_y<='0';
			else 
				VS_int<=VS_int;
				disp_y<='0';
				linea:=0;
			end if;
		end if;
	end process;
	
	--salidas
	HS <= HS_int;
	VS <= VS_int;
	
	--RGB code in binary (Red 0000, Green 0000, Blue 0000)
	--Red
	R_out <= "1010" when (disp_x AND disp_y)='1' and enBarra = '0' and sel = "01" else --Purple
				"1111" when (disp_x AND disp_y)='1' and enBarra = '1' and sel = "01" else --Blue
			   "1111" when (disp_x AND disp_y)='1' and enBarra = '0' and sel = "00" else --Green
				"0000" when (disp_x AND disp_y)='1' and enBarra = '1' and sel = "00" else --Yellow
				"0000";
	
   --Green	
	G_out <= "1111" when (disp_x AND disp_y)='1' and enBarra = '0' and sel = "01" else --Purple
				"1010" when (disp_x AND disp_y)='1' and enBarra = '1' and sel = "01" else --Blue
			   "1111" when (disp_x AND disp_y)='1' and enBarra = '0' and sel = "00" else --Green
				"1111" when (disp_x AND disp_y)='1' and enBarra = '1' and sel = "00" else --Yellow
				"0000";
	
	--Blue
	B_out <= "1110" when (disp_x AND disp_y)='1' and enBarra = '0' and sel = "01" else --Purple
				"1110" when (disp_x AND disp_y)='1' and enBarra = '1' and sel = "01" else --Blue
			   "0000" when (disp_x AND disp_y)='1' and enBarra = '0' and sel = "00" else --Green
				"0000" when (disp_x AND disp_y)='1' and enBarra = '1' and sel = "00" else --Blue
				"0000";
	
	
end behavior;