LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY SERVO_RTL IS
  PORT(
		CLK : in std_logic;  
		BTN : in std_logic_vector(3 downto 0);  --button inputs	
		RX_LINE       :  IN   STD_LOGIC;  --rx from arduino
	
		TX_LINE : out std_logic;  -- TX to arduino
		BTN_LED : out std_logic_vector(3 downto 0);  --button inputs
		SERVO : out std_logic_vector(3 downto 0); --servo outputs
		RX_LED: out std_logic_vector(7 downto 0);
		sig_io : inout STD_LOGIC; -- ir sensor output
		RX_DATA_buffer : buffer std_logic_vector( 7 downto 0 );  -- buffer
		LONG_LED_STRIP : out std_logic;
		ARDUINO_RESET: OUT std_logic
  	);
END SERVO_RTL;


ARCHITECTURE MACHINE OF SERVO_RTL IS                        
  SIGNAL RX_DATA_VALID    :  STD_LOGIC;
  SIGNAL rx_data    :  STD_LOGIC_VECTOR(7 DOWNTO 0);   --values received


	component servo_demo is
		port
		(
			clk		  : in std_logic;
			logic_byte	  : in std_logic_vector (7 downto 0);
			servo     : out std_logic_vector(3 downto 0)
		);
	end component;
		
	component uart_rx is		
	  PORT(
			CLK           : in std_logic;
			RX_LINE       : in std_logic;
			RX_DATA_VALID : out std_logic;
			RX_DATA_buffer : buffer std_logic_vector( 7 downto 0 );  -- buffer
			RX_DATA : out std_logic_vector( 7 downto 0 ) -- reg out
		);
	end component;	
	
	component Button_RTL is		
	port(
		BTN : in std_logic_vector(3 downto 0);  --button inputs
		RX_DATA : in std_logic_vector( 7 downto 0 );
		CLK : in std_logic;
		TX_LINE : out std_logic;  -- TX to arduino
		LED : out std_logic_vector(3 downto 0); --LED output on buttons 
		sig_io : inout STD_LOGIC;
		LONG_LED_STRIP : out std_logic;
		ARDUINO_RESET: OUT std_logic
	);
	end component;	
	
		
  
BEGIN

	Button_RTL_instance : Button_RTL port map (BTN, rx_data, CLK, TX_LINE, BTN_LED, sig_io,LONG_LED_STRIP, ARDUINO_RESET);
	
	uart_rx_instance : uart_rx port map (CLK, RX_LINE,RX_DATA_VALID, RX_DATA_buffer, rx_data);
	
	servo_demo_instance : servo_demo port map (CLK, rx_data, SERVO);
	
	RX_LED <= rx_data;
	
END MACHINE;