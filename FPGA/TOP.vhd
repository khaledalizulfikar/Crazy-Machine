  LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY TOP IS
  PORT(
		CLK : in std_logic;  
		SPLITTER_PUSH_BTN : in std_logic_vector(3 downto 0);  --button inputs	
		SPLITTER_RX_LINE       :  IN   STD_LOGIC;  --rx from arduino
		SPLITTER_TX_LINE : out std_logic;  -- TX to arduino
		SPLITTER_BTN_LED : out std_logic_vector(3 downto 0);  --button led
		SPLITTER_SERVO : out std_logic_vector(3 downto 0); --servo outputs
		RX_LED: out std_logic_vector(7 downto 0);
		SPLITTER_LINESENSOR : inout STD_LOGIC; -- ir sensor output
		
		LADDER_LEDS     : out std_logic;
		LADDER_LINESENSOR : inout std_logic_vector(1 downto 0 );
		
		PIANO_LIMIT_SWITCHES : in std_logic_vector(6 downto 0);		
		PIANO_LEDS     : out std_logic;
		hexo: out std_logic_vector (6 downto 0);
		hex1: out std_logic_vector(6 downto 0);
		PIANO_AUDIO : out STD_LOGIC;	
		LONG_LED_STRIP: out STD_LOGIC;
		ARDUINO_RESET: OUT std_logic
  	);
END TOP;


ARCHITECTURE CRAZYMACHINE OF TOP IS                        

	component Ladder_RTL2 is
		port
		(
			CLK    : in  std_logic;	
			so     : out std_logic;
			sig_io : inout std_logic_vector(1 downto 0 )
		);
	end component;
		
	component PianoSlide_RTL is		
	  PORT(
			CLK    : in  std_logic;
			SW : in std_logic_vector(6 downto 0);		
			so     : out std_logic;
			hexo: out std_logic_vector (6 downto 0);
			hex1: out std_logic_vector(6 downto 0);
			audioout : out STD_LOGIC
		);
	end component;	
	
	component SERVO_RTL is		
	port(
		CLK : in std_logic;  
		BTN : in std_logic_vector(3 downto 0);  --button inputs	
		RX_LINE       :  IN   STD_LOGIC;  --rx from arduino
		TX_LINE : out std_logic;  -- TX to arduino
		BTN_LED : out std_logic_vector(3 downto 0);  --button inputs
		SERVO : out std_logic_vector(3 downto 0); --servo outputs
		RX_LED: out std_logic_vector(7 downto 0);
		sig_io : inout STD_LOGIC; -- ir sensor output
		--RX_DATA_buffer : buffer std_logic_vector( 7 downto 0 );  -- buffer
		LONG_LED_STRIP : out std_logic;
		ARDUINO_RESET: OUT std_logic
	);
	end component;	
	
		
  
BEGIN

	Ladder_RTL_instance : Ladder_RTL2 port map (CLK, LADDER_LEDS, LADDER_LINESENSOR);
	
	Piano_RTL_instance : PianoSlide_RTL port map (CLK, PIANO_LIMIT_SWITCHES,PIANO_LEDS,hexo,hex1,PIANO_AUDIO);
	
	Servo_RTL_instance : SERVO_RTL port map (CLK, SPLITTER_PUSH_BTN, SPLITTER_RX_LINE,SPLITTER_TX_LINE,SPLITTER_BTN_LED,SPLITTER_SERVO,RX_LED, SPLITTER_LINESENSOR ,LONG_LED_STRIP, ARDUINO_RESET);
	
	
END CRAZYMACHINE;