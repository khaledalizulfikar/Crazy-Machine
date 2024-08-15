library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ws2812b;
use ws2812b.all;

entity Ladder_RTL2 is
	port(
		CLK    : in  std_logic;	
		so     : out std_logic;
		sig_io : inout std_logic_vector(1 downto 0 );
		--dubugging
		LED : out  std_logic_vector(1 downto 0) ;
		finish_state: out std_logic_vector(1 downto 0)
	);
end entity Ladder_RTL2;

architecture RTL of Ladder_RTL2 is
	constant length : integer := 16;	
	type STATEMACHINE is (s_idle, s_balldetected);
	type Colour_array is array (0 to length, 0 to 3) of integer range 0 to 255;	
	
	
	constant LED_lagtime   : natural := 4800000; -- 25000000 is 0.5s, 2500000 is 0.05s 
	constant LED_maxtime   : natural := 25000000*30; -- 15s

	signal addr          : std_logic_vector(integer(ceil(log2(real(length - 1)))) downto 0) := (others => '1');
	signal data_red      : std_logic_vector(7 downto 0) := (others => '0');
	signal data_green    : std_logic_vector(7 downto 0) := (others => '0');
	signal data_blue     : std_logic_vector(7 downto 0) := (others => '0');
	signal dataOut_red   : std_logic_vector(7 downto 0);
	signal dataOut_green : std_logic_vector(7 downto 0);
	signal dataOut_blue  : std_logic_vector(7 downto 0);
	signal rst           : std_logic := '0';
	signal we            : std_logic := '0';
	signal render        : std_logic := '1';
	signal vsync         : std_logic;
	signal done          : std_logic := '1';
	signal colIdx        : std_logic_vector(integer(ceil(log2(real(length - 1)))) downto 0);
	signal colour : Colour_array;
	
	signal state : STATEMACHINE := s_idle;
	signal led_state   : std_logic_vector(length downto 0);
	signal finished_led          : std_logic := '0';
	signal LED_timer   : natural range 0 to LED_maxtime;
	
	signal ir_signal   : std_logic_vector(1 downto 0);

	
	component ir2 is		
		 Port (
			  clk : in STD_LOGIC;
			  sig_io : inout STD_LOGIC;
			  finish_state : out STD_LOGIC;
			  LED : OUT STD_LOGIC
		 );
	end component;		
	
begin

	colour(0,0) <= 255; -- red
	colour(0,1) <= 0;
	colour(0,2) <= 0;

	colour(1,0) <= 255; -- red-orange
	colour(1,1) <= 69;
	colour(1,2) <= 0;

	colour(2,0) <= 255; -- orange
	colour(2,1) <= 165;
	colour(2,2) <= 0;

	colour(3,0) <= 255; -- yellow-orange
	colour(3,1) <= 215;
	colour(3,2) <= 0;

	colour(4,0) <= 255; -- yellow
	colour(4,1) <= 255;
	colour(4,2) <= 0;

	colour(5,0) <= 173; -- yellow-green
	colour(5,1) <= 255;
	colour(5,2) <= 47;

	colour(6,0) <= 0; -- green
	colour(6,1) <= 255;
	colour(6,2) <= 0;

	colour(7,0) <= 0; -- green-cyan
	colour(7,1) <= 255;
	colour(7,2) <= 87;

	colour(8,0) <= 0; -- cyan
	colour(8,1) <= 255;
	colour(8,2) <= 255;

	colour(9,0) <= 0; -- sky blue
	colour(9,1) <= 191;
	colour(9,2) <= 255;

	colour(10,0) <= 0; -- blue
	colour(10,1) <= 0;
	colour(10,2) <= 255;

	colour(11,0) <= 75; -- indigo
	colour(11,1) <= 0;
	colour(11,2) <= 130;

	colour(12,0) <= 138; -- deep indigo
	colour(12,1) <= 43;
	colour(12,2) <= 226;

	colour(13,0) <= 148; -- violet
	colour(13,1) <= 0;
	colour(13,2) <= 211;

	colour(14,0) <= 186; -- purple
	colour(14,1) <= 85;
	colour(14,2) <= 211;

	colour(15,0) <= 221; -- magenta
	colour(15,1) <= 160;
	colour(15,2) <= 221;

	
	colIdx <= addr;

	ws2812b_controller_inst : entity ws2812b.ws2812b_controller
		generic map(
			length => length,
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

		
	ir_instance1 : ir2 port map (CLK, sig_io(0), finish_state(0), ir_signal(0));
	ir_instance2 : ir2 port map (CLK, sig_io(1), finish_state(1), ir_signal(1));
	
	LED(0) <= ir_signal(0);
	LED(1) <= ir_signal(1);

	led_state_process : process(clk,ir_signal) -- led 0 to led 6 turns on 1 by 1 with delay led_delay.
	begin -- state machine. first state is when leds are off. go to next state (turn on with delay when line sensor is active)
			if rising_edge( CLK) then
				
				case state is
					when s_idle =>	
					
						led_state <= (others => '0');								
						

						if ir_signal(0) = '1' then --if  first line sensor is rising edge, progress to next state
							state <= s_balldetected;						
						else
							state <= s_idle;
						end if;						
					
					when s_balldetected =>							
						if ir_signal(1) = '1' or LED_Timer > LED_maxtime- 1 then						
							state <= s_idle;
							LED_Timer <= 0;							
						else
							LED_Timer <= LED_Timer + 1;
							state <= s_balldetected;
							for i in 0 to length-1 loop -- code to activate leds based on LED_timer and LED_lagtime
								if LED_lagtime*i <= LED_Timer then -- if led_lagtime(i)
									led_state(i) <= '1';
								else
									led_state(i) <= '0';
								end if;						
							end loop;							
						end if;						
					when others =>
						state <= s_idle;
				end case;
			end if;
	end process led_state_process;
	
	prog : process(clk, rst) is
		variable colRot : unsigned(3 downto 0);
		variable c2     : integer range 0 to 25000000 ;
	begin
		if rst = '1' then
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
			if to_integer(unsigned(addr)) = length - 1 then
				done   <= '1';
				render <= '1';
			end if;
				
				for i in 0 to length-1 loop
					if unsigned(colIdx) = to_unsigned(i-1,integer(ceil(log2(real(length - 1))))) then
						if led_state(i) = '1' then
								data_red   <= std_logic_vector(to_unsigned(colour(i,1), 8));
								data_green <= std_logic_vector(to_unsigned(colour(i,0), 8));
								data_blue  <= std_logic_vector(to_unsigned(colour(i,2), 8));
						else
								data_red   <= (others => '0');
								data_green <= (others => '0');
								data_blue  <= (others => '0');						
						end if;
					end if;
				end loop;
		
				we <= '1';
			else
				if c2 = 10000 then
					done   <= '0';
					c2     := 0;
				else
					c2 := c2 + 1;
				end if;
			end if;	
		end if;

	end process prog;

end architecture RTL;


