--Main entity CONTROLLER
--Epsilon
--Final Evidence (Chika Shioriko XVI)*
--CDMX 11/03/2021
--*Personal code name, ignore

library ieee;
use ieee.std_logic_1164.all;


Entity CONTROLLER is
	Port(
		CLK : in std_logic;	--50 MHz clock
		RST : in std_logic;	--RESET sensors
		RJ  : in std_logic;	--RESET game
		DIR : in std_logic;	--Show direction of left paddle

		
		--SPI
		MOSI 			: out std_logic;	--Master out, slave in
		MISO 			: in std_logic;	--Master in, slave out
		SCLK 			: out std_logic;	--SPI serial clock
		CS 			: out std_logic;	--SPI mode sleect
		INT1			: in std_logic;	--Interrupt 1
		INTBYPASS 	: in std_logic;	--Interrupt bypass
		
		--UART
		TX : out std_logic;	--FPGA UART transmiter
		RX : in std_logic;	--FPGA UART receiver
		
		--VGA
		RV : out std_logic_vector (3 downto 0); 	--Red out
		GV : out std_logic_vector (3 downto 0);	--Green out
		BV : out std_logic_vector (3 downto 0);	--Blue out
		HS : out std_logic;								--Horizontal Sync
		VS : out std_logic;								--Vartical Sync
		
		--Ultrasonic Sensor
		T : out std_logic;	--Trigger
		E : in std_logic;		--Echo
		
		--Leds to show internal state
		V : out std_logic_vector(7 downto 0);
		mode_test : out std_logic;
		c_test : out std_logic;
		sign_test : out std_logic;
		edo_ultra : out std_logic_vector (6 downto 0)
	);
end CONTROLLER;

Architecture behavior of CONTROLLER is
	--SPI master
	Component spi_master is
    port (
		clk	: in std_logic;
		rst	: in std_logic;
      mosi	: out std_logic;
		miso 	: in std_logic;
		sclk_out : out std_logic; 
		cs_out	: out std_logic;
		int1 	: in std_logic;
		int2 	: in std_logic;
		go		: in std_logic;
		pol	: in std_logic;
		pha   : in std_logic;
		bytes : in std_logic_vector (3 downto 0);
		rxData: out std_logic_vector(7 downto 0);
		txData: in  std_logic_vector(7 downto 0);
		rxDataReady: out std_logic
		);
	end component;
	--VGA controller
	Component VGA_CONT is
		port(	
			CLK: in std_logic;
			SEL : in std_logic_vector (1 downto 0);
			R_out, G_out, B_out: out std_logic_vector(3 downto 0);--4bits
			HS, VS: out std_logic
			);
	end component;
	--Accelerometer driver
	Component accel_driver is
	port (
		rst			:		in std_logic;
		clk			:		in std_logic;
		int1			:		in std_logic;
		rxDataReady	:		in	std_logic;
		go				:		out std_logic;
		pol			:		out std_logic;
		pha			:		out std_logic;
		bytes 		:		out std_logic_vector (3 downto 0);
		txData 		:		out std_logic_vector (7 downto 0);
		rxData		: 		in std_logic_vector ( 7 downto 0);
		accel_data	:		out std_logic_vector (47 downto 0);

		m				: out std_logic;
		c				: out std_logic;
		intBypass   : in std_logic
	);
	end component;
	--UART Transmiter
	Component TXSERIAL is
	Port(
		CLK 	: in std_logic;
		D 		: in std_logic_vector (7 downto 0);
		E 		: in std_logic;
		R		: in std_logic;
		RJ		: in std_logic;
		TX 	: out std_logic
		);
	end component;
	--Makes an average
	Component PROMEDIO is
		Port(
			RX : in std_logic;
			CLK : in std_logic;
			R : in std_logic;
			P : out std_logic_vector(7 downto 0);
			E : out std_logic
		);
	end component;
	--Ultrasonic controller
	Component ULTRA_CONT is
		Port(
			CLK 	: in std_logic;
			T 		: out std_logic;
			E 		: in std_logic;
			R 		: in std_logic;
			S 		: out std_logic;
			edo : out std_logic_vector (6 downto 0);
			D 		: out std_logic_vector(7 downto 0)
		);
	end component;
	--Frequency divisor
	Component DIVISOR is 
		generic(
			P : integer := 25000000
			);
		port(
			CLK 		: in std_logic;
			CLK_OUT 	: out std_logic
			);
	end component;
	--UART Receiver
	Component RXSERIAL is
		Port(
			CLK 	: in std_logic;
			R		: in std_logic;
			RX 	: in std_logic;
			D 		: out std_logic_vector (7 downto 0);
			S		: out std_logic
			);
	end component;
	--Buffers
	signal mosi_int : std_logic;
	signal sckl_int : std_logic;
	signal sckl_spi : std_logic;
	signal cs_int : std_logic;
	signal int1_int : std_logic;
	signal c_int : std_logic;
	--spi_master to accel_driver
	signal go : std_logic;
	signal pol : std_logic;
	signal pha : std_logic;
	signal bytes : std_logic_vector (3 downto 0);
	signal rx_Data : std_logic_vector (7 downto 0);
	signal rx_Data_Ready : std_logic;
	signal tx_Data : std_logic_vector (7 downto 0);
	signal mode : std_logic;
	--Accelerometer data
	signal accel_data : std_logic_vector(47 downto 0);
	--Internal serial transmiter
	signal enable_tx : std_logic;
	signal accel2prom : std_logic;
	--External UART transmiter
	signal average_acce : std_logic_vector(7 downto 0);
	signal average_ultra : std_logic_vector(7 downto 0);
	signal average : std_logic_vector(7 downto 0);
	signal ave_cont : std_logic;
	signal enable : std_logic;
	--Ultrasonic controller
	signal rst_ultra : std_logic;
	signal ultra_ready : std_logic;
	--UART receiver
	signal rx_ready : std_logic;
	signal d_proc : std_logic_vector(7 downto 0);
	--Clock
	signal clk_2 : std_logic; -- 9600 baud
Begin
	--Get data from accelerometer
	U0 : entity work.spi_master(FSM_1P) port map(CLK, RST, mosi_int, MISO, sckl_spi, cs_int, '0', '0', go, pol, pha, bytes, rx_Data, tx_Data, rx_Data_ready);
	U1 : entity work.accel_driver(FSM_1P) port map(RST, CLK, int1_int, rx_Data_Ready, go, pol, pha, bytes, tx_Data, rx_Data, accel_data, mode, c_int, INTBYPASS);
	--Process accelerometer data
	U2 : TXSERIAL port map (CLK, accel_data(25 downto 18), enable_tx, RST, '0', accel2prom); --Send Y data
	U3 : PROMEDIO port map (accel2prom, CLK, RST, average_acce, ave_cont);
	--Get data from ultrasonic sensor
	U4 : ULTRA_CONT port map (CLK, T, E, rst_ultra, ultra_ready, edo_ultra, average_ultra);
	--External UART
	U5 : TXSERIAL port map(CLK, average, enable, RST, RJ, TX);
	--Receive data from processing
	U7 : RXSERIAL port map(CLK, RST, RX, d_proc, rx_ready);
	--Send data to vga
	U8 : VGA_CONT port map (CLK, (RST or RJ) & d_proc(0), RV, GV, BV, HS, VS);
	
	--Accel driver and spi master
	process(CLK, RST)
	Begin
		if(RST = '1') then
			sckl_int <= '1';
			int1_int <= '0';
		elsif (CLK'event and CLK = '1') then
			sckl_int <= sckl_spi;
			int1_int <= INT1;
		end if;
	end process;
	
	--Data flow to internal UART transmiter
	process(clk_2)
		variable counter : integer := 0;
	Begin
		if (rising_edge(clk_2)) then
			counter := counter + 1;
			if(counter < 3) then
				enable_tx <= '1';
			elsif (counter = 12) then
				counter := 0;
				enable_tx <= '0';
			else
				enable_tx <= '0';
			end if;
		end if;
	end process;
	
	
	
	--Enable UART external transmiter
	process (ave_cont)
		variable counter : integer := 0;
		variable selector : boolean := true; --Send accel_data and ultra_adata alternately
	Begin
		if (rising_edge(ave_cont)) then
			counter := counter + 1;
			--Wait for the data to be send
			if(counter = 12) then
				--Send accelerometer with it's control bits
				if(selector) then
					average <= average_acce(7 downto 2) & DIR & '0';
					rst_ultra <= '1';--Because the ultrasonic sensor can be looped if there's no object in range, we reset it before we ask for more data
				else
				--Send ultrasonic with it's control bits
					average <= average_ultra(7 downto 1) & '1';
				end if;
				selector := not selector;--Change next data to be send
				enable <= '1';--Send enable pulse
				counter := 0;
			else
				enable <= '0';
				rst_ultra <= '0';
			end if;
		end if;
	end process;
	
	
	
	--Make 9600 baud clk
	process (CLK)
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
	
	--I/O assigment
	MOSI <= mosi_int;
	SCLK <= sckl_int;
	CS <= cs_int;
	mode_test <= mode;
	c_test <= c_int;
	V <= d_proc;
	sign_test <= accel_data(47);
end behavior;