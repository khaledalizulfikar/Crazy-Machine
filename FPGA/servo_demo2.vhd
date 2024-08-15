-- Counter based PWM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity servo_demo2 is
	generic
	(g
		MIN_COUNT : natural := 0;
		MAX_COUNT : natural := 255;
		CLK_FREQ  : natural := 50_000_000;
		TARGET_FREQ : natural := 12750; --12750
		DUTY_CYCLE_0 : integer := 10;
		DUTY_CYCLE_1 : integer := 17
	);

	port
	(
		clk		  : in std_logic;
		SW		  : in std_logic;
		reset	  : in std_logic;
		enable	  : in std_logic;
		byte_in	  : in std_logic_vector (7 downto 0);
		servo1       : out std_logic;
		servo2		: out std_logic;
		servo3		: out std_logic;
		servo4		: out std_logic
	);

end entity;

architecture rtl of servo_demo2 is
begin

	process (clk)
		variable   cnt		   : integer range MIN_COUNT to MAX_COUNT;
		variable   freq_div_count : integer;
		variable   period	   : integer;
		variable logic_byte : integer;
		variable   duty_count_0	   : integer;
		variable   duty_count_1	   : integer;
		variable servo1_pos : integer;
		variable servo2_pos : integer;
		variable servo3_pos : integer;
		variable servo4_pos : integer;
	begin
		-- Divide the clock frequency by the target frequency to get the period
		period := CLK_FREQ / TARGET_FREQ;
		duty_count_0 := DUTY_CYCLE_0 * MAX_COUNT / 255;
		duty_count_1 := DUTY_CYCLE_1 * MAX_COUNT / 255;

		-- Convert the input byte to an integer
		logic_byte := to_integer(unsigned(byte_in));

		-- Each clk cycle
		if (rising_edge(clk)) then

			-- check for the different logic codes signified by an integer
			if SW = '1' then
				-- Path 1
				servo1_pos := 1;
				servo2_pos := 1;
				servo3_pos := 0;
				servo4_pos := 0;
			elsif logic_byte = 3 then
				-- Path 2
				servo1_pos := 1;
				servo2_pos := 0;
				servo3_pos := 0;
				servo4_pos := 0;
			elsif logic_byte = 7 then
				-- Path 3
				servo1_pos := 0;
				servo2_pos := 0;
				servo3_pos := 1;
				servo4_pos := 1;
			elsif logic_byte = 15 then
				-- Path 4
				servo1_pos := 0;
				servo2_pos := 0;
				servo3_pos := 0;
				servo4_pos := 1;
			elsif logic_byte = 6 then
				-- exit
				servo1_pos := 0;
				servo2_pos := 0;
				servo3_pos := 1;
				servo4_pos := 0;
			else
				-- Path 1
				servo1_pos := 0;
				servo2_pos := 0;
				servo3_pos := 0;
				servo4_pos := 0;
			end if;

--			-- Reset the counter if the reset switch is active
--			if reset = '1' then
--				-- Reset the counter to 0
--				freq_div_count := 0;
--				cnt := 0;
--			end if;

			-- Increment the counter if the enable switch is active
--			if enable = '1' then
				-- Downgrade the 50MHz clock to 12.75kHz
				if freq_div_count <= period then
					freq_div_count := freq_div_count + 1;
				else
					cnt := cnt + 1;
					freq_div_count := 0;
				end if;

				-- Depending on the requested position of the servo use a different duty cycle count
				if servo1_pos = 0 then
					if cnt >= duty_count_0 then
						servo1 <= '0';
					else 
						servo1 <= '1';
					end if;
				elsif servo1_pos = 1 then
					if cnt >= duty_count_1 then
						servo1 <= '0';
					else 
						servo1 <= '1';
					end if;
				end if;
				if servo2_pos = 0 then
					if cnt >= duty_count_0 then
						servo2 <= '0';
					else 
						servo2 <= '1';
					end if;
				elsif servo2_pos = 1 then
					if cnt >= duty_count_1 then
						servo2 <= '0';
					else 
						servo2 <= '1';
					end if;
				end if;
				if servo3_pos = 0 then
					if cnt >= duty_count_0 then
						servo3 <= '0';
					else 
						servo3 <= '1';
					end if;
				elsif servo3_pos = 1 then
					if cnt >= duty_count_1 then
						servo3 <= '0';
					else 
						servo3 <= '1';
					end if;
				end if;
				if servo4_pos = 0 then
					if cnt >= duty_count_0 then
						servo4 <= '0';
					else 
						servo4 <= '1';
					end if;
				elsif servo4_pos = 1 then
					if cnt >= duty_count_1 then
						servo4 <= '0';
					else 
						servo4 <= '1';
					end if;
				end if;

				-- Reset the counter if it reaches the maximum count
				if cnt >= MAX_COUNT then 
					cnt := 0;					
				end if;
--			end if;
		end if;
	end process;

end rtl;
