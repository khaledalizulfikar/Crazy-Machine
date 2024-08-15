library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;
use ieee.math_real.all;


library ws2812b;
use ws2812b.all;

entity Button_RTL is

	generic (

		CLKS_PER_5S : integer := 250000000;  -- 250000000 is 5s (how long the leds will blink) change to 60s for final
		CLKS_PER_5S2 : integer := 350000000*2;  -- 250000000 is 5s (how long the leds will blink) change to 60s for final
		LENGTH_LONG_LED_STRIP : integer := 68 
	);

	port(
		BTN : in std_logic_vector(3 downto 0);  --button inputs
		RX_DATA : in std_logic_vector( 7 downto 0 );
		CLK : in std_logic;
		TX_LINE : out std_logic;  -- TX to arduino
		LED : out std_logic_vector(3 downto 0); --LED output on buttons 
		sig_io : inout STD_LOGIC;
		LONG_LED_STRIP : out std_logic;
		LED_test : out std_logic_vector(LENGTH_LONG_LED_STRIP-1 downto 0);
		ARDUINO_RESET : out std_logic
	);

end entity;

architecture arch of Button_RTL is
	type Colour_array is array (0 to 3) of integer range 0 to 255;	
	
	type STATEMACHINE is (s_initialise, s_notflashing, s_flashing);
		
	type ascii_data_type is array(0 to 4) of std_logic_vector(7 downto 0);
	
	type button_detector is array(0 to 3, 0 to 1) of std_logic;
	
		
	  -- Constants to create the frequencies needed:
	  -- Formula is: (50 MHz / 100 Hz * 50% duty cycle)
	  -- So for 100 Hz: 50,000,000 / 100 * 0.5 = 250,000	
	  
	constant c_CNT_1HZ   : natural := 2500000; -- how fast push buttons will flash

	signal RST      : std_logic:= '1';
	
																			-- 250000000 -
	signal clkCount  : integer range 0 to CLKS_PER_5S - 1 := 0;-- this will be 1-CLKS_PER_5S is how long buttons flash on startup
	signal clkCount2  : integer range 0 to CLKS_PER_5S2 - 1 := 0;-- this will be 1-CLKS_PER_5S is how long buttons flash on startup
	signal r_CNT_1HZ   : natural range 0 to c_CNT_1HZ;
	signal flash_led   : std_logic := '0';

	signal BTN_O      : std_logic_vector(3 downto 0);	
	signal TOGGLE_O      : std_logic_vector(3 downto 0);
	signal SW_TOGGLE_O      : std_logic_vector(3 downto 0);
	signal BTN_PULSE_O      : std_logic_vector(3 downto 0);
	signal BTN_FALL_PULSE_O : std_logic_vector(3 downto 0);
	signal LED_O      : std_logic_vector(3 downto 0);
	
	signal state : STATEMACHINE := s_initialise;
	signal ascii_table : ascii_data_type;
	signal btn_sync : button_detector;

	
	
	signal btn_pulse  : std_logic_vector(3 downto 0);

 
	signal dataValid_TX : std_logic := '0';
	signal data_TX      : std_logic_vector( 7 downto 0 ) := ( others => '0' );
	signal active_TX     : std_logic;
	signal done_TX       : std_logic;
	signal ir_pulse : std_logic;
	signal ir_signal : std_logic;
	signal ir_sync : std_logic_vector(1 downto 0);
	
	signal DEMO_LED : std_logic;
	signal LED_pressed_colour : std_logic_vector(1 downto 0);
	SIGNAL LED_PRESSED_STATE : std_logic_vector(LENGTH_LONG_LED_STRIP-1 downto 0) := (others => '0');
	
	constant LED_pressed_delay   : natural := 2500000/2; -- how fast the LEDS will go in circle pattern
	signal LED_pressed_timer   : natural range 0 to LED_pressed_delay;
	
	
	signal rst_LED           : std_logic := '0';
	signal we            : std_logic := '0';
	signal render        : std_logic := '1';
	signal vsync         : std_logic;
	signal done          : std_logic := '1';
	signal so          : std_logic;
	signal colIdx        : std_logic_vector(integer(ceil(log2(real(LENGTH_LONG_LED_STRIP - 1)))) downto 0);
	signal addr          : std_logic_vector(integer(ceil(log2(real(LENGTH_LONG_LED_STRIP - 1)))) downto 0) := (others => '1');
	signal data_red      : std_logic_vector(7 downto 0) := (others => '0');
	signal data_green    : std_logic_vector(7 downto 0) := (others => '0');
	signal data_blue     : std_logic_vector(7 downto 0) := (others => '0');
	signal dataOut_red   : std_logic_vector(7 downto 0);
	signal dataOut_green : std_logic_vector(7 downto 0);
	signal dataOut_blue  : std_logic_vector(7 downto 0);
	
	signal colour : Colour_array;
	signal ascii_tableRX : ascii_data_type;
	
	


	component btn_debounce_toggle is
		 Port ( BTN_I 	: in  STD_LOGIC;
				  CLK 		: in  STD_LOGIC;
				  RES			: in STD_LOGIC;
				  BTN_O 	: out  STD_LOGIC;
				  TOGGLE_O : out  STD_LOGIC;
				  SW_TOGGLE_O  : out STD_LOGIC;
				  BTN_PULSE_O : OUT STD_LOGIC;
				  BTN_FALL_PULSE_O :  OUT STD_LOGIC
		);

	end component;
	
	component UART_TX is

		port(

			CLK           : in std_logic;
			TX_DATA_VALID : in std_logic;  -- used to start transmission
			TX_DATA       : in std_logic_vector( 7 downto 0 );  -- buffer
			TX_LINE       : out std_logic;
			TX_ACTIVE     : out std_logic;
			TX_DONE       : out std_logic
		);
	end component;
	
	component ir2 is		
		 Port (
			  clk : in STD_LOGIC;
			  sig_io : inout STD_LOGIC;
			  LED : OUT STD_LOGIC
		 );
	end component;	

	component demo_rainbow is		
		port(
			clk    : in  std_logic;
			so     : out std_logic
		);
	end component;	
	
		
begin
	
	ascii_table(0) <= "01000001"; --A (buttons)
	ascii_table(1) <= "01000010"; --B
	ascii_table(2) <= "01000011"; --C
	ascii_table(3) <= "01000100"; --D
	ascii_table(4) <= "01000101"; --E (IR_pulse)
	

		gene: FOR i IN 0 TO 3 GENERATE
			debounce_instance:btn_debounce_toggle PORT MAP(BTN(i), CLK, RST, BTN_O(i), TOGGLE_O(i), SW_TOGGLE_O(i), BTN_PULSE_O(i), BTN_FALL_PULSE_O(i));
		END GENERATE gene;
		
		-- Instantiate UART transmitter
		UART_TX_instance : UART_TX port map (CLK, dataValid_TX, data_TX, TX_LINE, active_TX, done_TX);
		
		ir_instance : ir2 port map (CLK, sig_io, ir_signal);

		demo_rainbow_instance : demo_rainbow port map (CLK, DEMO_LED);
		
		ws2812b_controller_inst : entity ws2812b.ws2812b_controller
		generic map(
			length => LENGTH_LONG_LED_STRIP,
			f_clk  => 50000000
		)
		port map(
			clk           => clk,
			rst           => '0',
			so            => so,
			addr          => addr,
			data_red      => data_red,
			data_green    => data_green,
			data_blue     => data_blue,
			dataOut_red   => dataOut_red,
			dataOut_green => dataOut_green,
			dataOut_blue  => dataOut_blue,
			we            => we,
			render        => render,
			vsync         => vsync
		);	
		

		
  p_1_HZ : process (CLK) is --1HZ COUNTER (for flashing LEDs)
  begin
    if rising_edge(CLK) then
      if r_CNT_1HZ = c_CNT_1HZ-1 then  -- -1, since counter starts at 0
        flash_led <= not flash_led;
        r_CNT_1HZ    <= 0;
      else
        r_CNT_1HZ <= r_CNT_1HZ + 1;
      end if;
    end if;
  end process p_1_HZ;		

	
	ascii_tableRX(0) <= "01000110"; --PATH1
	ascii_tableRX(1) <= "01000111"; --PATH2
	ascii_tableRX(2) <= "01001000"; --PATH3
	ascii_tableRX(3) <= "01001001"; --PATH4
	ascii_tableRX(4) <= "01001010"; --PATH5

  LED_pressed_process : process (CLK) is-- returns strip signal upon button is pressed eg. when toggle is 0001-1110
  begin
		if LED_pressed_colour = "00" then
			colour(0) <= 255; --red (R,G,B)
			colour(1) <= 0;
			colour(2) <= 0;
		elsif LED_pressed_colour = "01" then
			colour(0) <= 0; -- green
			colour(1) <= 255;
			colour(2) <= 0;
		elsif LED_pressed_colour = "10" then
			colour(0) <= 0; -- blue
			colour(1) <= 0;
			colour(2) <= 255;
		elsif LED_pressed_colour = "11" then	
			colour(0) <= 255; --yellow
			colour(1) <= 255;
			colour(2) <= 0;
		end if;
			if rising_edge( CLK ) then
				LED_pressed_timer <= LED_pressed_Timer + 1;
--detect a rising edge of TOGGLE_O(i). If a rising edge occurs then then set the colour register. btn_pulse(i) is 1 
--upon rising edge

--led state. All leds are off except for one. the on led address increments by one for a delay led_pressed_delay.
				if LED_pressed_Timer > LED_pressed_delay- 1 then						
					LED_pressed_Timer <= 0;
-- shift LED address
					if (LED_PRESSED_STATE = (LED_PRESSED_STATE'range => '0')) then
							LED_PRESSED_STATE(0) <= '1';	
					else
						for i in 0 to LENGTH_LONG_LED_STRIP-1 loop -- code to activate leds based on LED_timer and LED_lagtime
							if LED_PRESSED_STATE(i) = '1' then
								LED_PRESSED_STATE(i) <= '0';
								if i = LENGTH_LONG_LED_STRIP-1 then
									 LED_PRESSED_STATE(0) <= '1'; -- Set LED_PRESSED_STATE(0) to '1' when i reaches LENGTH_LONG_LED_STRIP-1
								else
									 LED_PRESSED_STATE(i+1) <= '1';
								end if;
							end if;
						end loop;
					end if;
				end if;
				
			end if;
			
			LED_test <= LED_PRESSED_STATE;
  end process LED_pressed_process;	
  colIdx <= addr;
  
	prog : process(clk, rst_LED) is
		variable colRot : unsigned(3 downto 0);
		variable c2     : integer range 0 to 25000000 ;
	begin
		if rst_LED = '1' then
			addr       <= (others => '1');
			data_red   <= (others => '0');
			data_green <= (others => '0');
			data_blue  <= (others => '0');
			we         <= '0';
			done       <= '1';
			c2         := 0;
			colRot     := "0000";
			render     <= '0';
		end if;
			
			
		if rising_edge(clk) then
			we     <= '0';
			render <= '0';
			
			if done = '0' then
				addr <= std_logic_vector(unsigned(addr) + 1);

				-- If we wrote the entire strip, render the data!
				if to_integer(unsigned(addr)) = LENGTH_LONG_LED_STRIP - 1 then
					done   <= '1';
					render <= '1';
				end if;
				
				for i in 0 to LENGTH_LONG_LED_STRIP-1 loop
					if unsigned(colIdx) = to_unsigned(i-1,integer(ceil(log2(real(LENGTH_LONG_LED_STRIP - 1))))) then
							if LED_PRESSED_STATE(i) = '1' then
									data_red   <= std_logic_vector(to_unsigned(colour(1),8));
									data_green <= std_logic_vector(to_unsigned(colour(0),8));
									data_blue  <= std_logic_vector(to_unsigned(colour(2),8));
							else
									data_red   <= (others => '0');
									data_green <= (others => '0');
									data_blue  <= (others => '0');						
							end if;
					end if;
				end loop;
			

				we <= '1';
			else
				if c2 = 1000000 then
					done   <= '0';
					c2     := 0;
				else
					c2 := c2 + 1;
				end if;
			end if;	
		end if;

	end process prog;	
	
	LED_STATE_PROCESS : process (CLK) --DETERMINE IF LED IS FLASHING/NOT FLASHING
	begin
			
			if rising_edge( CLK ) then

			--Data Transmission to arduino
				dataValid_TX <= '0';
				
				ir_sync(0) <= ir_signal;
				ir_sync(1) <= ir_sync(0);
				ir_pulse   <= not ir_sync(1) and ir_sync(0);	--rising edge
				
				if ir_pulse = '1' and active_TX = '0' then
					data_TX <= ascii_table(4);
					dataValid_TX <= '1';
				end if;
				
				for i in 0 to 3 loop
					if btn_pulse(i) = '1' then
						LED_pressed_colour <= std_logic_vector(to_unsigned(i,2));
					end if;
				end loop;
				
			IF state = s_initialise then
				ARDUINO_RESET <= '0';
			else 
				ARDUINO_RESET <= '1';
			end if;
					
			case state is
						
				when s_initialise =>
				RST <= '1';
				if clkCount <= CLKS_PER_5S/5 - 1 then
					clkCount <= clkCount + 1;
					state <= s_initialise;
					for i in 0 to 3 loop
						LED_O(i) <= flash_led;
						--LONG_LED_STRIP <= '0';
					end loop;
				else
					clkCount <= 0;
					state <= s_notflashing;
				end if;	
						
				when s_notflashing =>	
					--Data to LEDs**********************************
					RST <= '0';	
					
					LED_O(2 downto 0) <= TOGGLE_O(2 downto 0);
					LED_O(3) <= SW_TOGGLE_O(3);						
					
					if TOGGLE_O(2 downto 0) = "000" and SW_TOGGLE_O(3) = '0' then
					LONG_LED_STRIP <= DEMO_LED;
					else

					LONG_LED_STRIP <= so;-- strip signal upon button is pressed eg. when toggle is 0001-1110
					
				
					end if;
					
					FOR i IN 0 TO 2 loop														
					
						if BTN_PULSE_O(i) = '1' and active_TX = '0' then
							dataValid_TX <= '1';
							data_TX <= ascii_table(i);
						end if;
					end loop;
					
						if BTN_PULSE_O(3) = '1' or BTN_FALL_PULSE_O(3) = '1' then
							IF active_TX = '0' THEN
								dataValid_TX <= '1';
								data_TX <= ascii_table(3);
							end if;
						end if;
					
					for i in 0 to 2 loop
						if BTN_PULSE_O(i) = '1' then
						LED_pressed_colour <= std_logic_vector(to_unsigned(i,2));
						end if;
					end loop;
					
					if BTN_PULSE_O(3) = '1' or BTN_FALL_PULSE_O(3) = '1' then
						LED_pressed_colour <= std_logic_vector(to_unsigned(3,2));
					end if;
					
					
					if TOGGLE_O(2 downto 0) = "111" and SW_TOGGLE_O(3) = '1' then
						state <= s_flashing;
						
					else
						state <= s_notflashing;
					end if;
				
				when s_flashing =>
						if RX_DATA = ascii_tableRX(4) then
							LONG_LED_STRIP <= DEMO_LED;-- strip signal upon button is pressed eg. when toggle is 0001-1110
							if clkCount2 <= CLKS_PER_5S2 - 1 then
								clkCount2 <= clkCount2 + 1;
								state <= s_flashing;
								for i in 0 to 3 loop
									LED_O(i) <= flash_led;
								end loop;
							else
								clkCount2 <= 0;
								state <= s_initialise;
								RST <= '1';
							end if;	
							
						else
							for i in 0 to 3 loop
								if RX_DATA = ascii_tableRX(i) then
									LED_pressed_colour <= std_logic_vector(to_unsigned(i,2));
									LONG_LED_STRIP <= so;
									LED_O(i) <= flash_led;
								else
									LED_O(i) <= '0';
								end if;
							end loop;	
						end if;
				when others =>
					state <= s_initialise;
			end case;
		end if;		
						
	end process;
	
	LED <= LED_O;

end architecture;