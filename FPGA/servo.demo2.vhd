-- Counter based PWM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity servo_demo2 is
	generic
	(
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
		byte_in	  : in std_logic_vector (7 downto 0);
		servo     : out std_logic_vector(3 downto 0)

	);

end entity;

architecture rtl of servo_demo2 is

type position_servo is array (0 to 3) of integer;

begin

	process (clk)
		variable   cnt		   : integer range MIN_COUNT to MAX_COUNT;
		variable   freq_div_count : integer;
		variable   period	   : integer;
		variable logic_byte : integer;
		variable   duty_count_0	   : integer;
		variable   duty_count_1	   : integer;
		variable servo_pos : position_servo;
		
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
			if logic_byte = 1 then
				-- Path 1
				servo_pos(0) := 1; --servo 0
				servo_pos(1) := 1;
				servo_pos(2) := 0;
				servo_pos(3) := 0; --servo 3
			elsif logic_byte = 3 then
				-- Path 2
				servo_pos(0) := 1;
				servo_pos(1) := 0;
				servo_pos(2) := 0;
				servo_pos(3) := 0;
			elsif logic_byte = 7 then
				-- Path 3
				servo_pos(0) := 0;
				servo_pos(1) := 0;
				servo_pos(2) := 1;
				servo_pos(3) := 1;
			elsif logic_byte = 15 then
				-- Path 4
				servo_pos(0) := 0;
				servo_pos(1) := 0;
				servo_pos(2) := 0;
				servo_pos(3) := 1;
			elsif logic_byte = 6 then
				-- exit
				servo_pos(0) := 0;
				servo_pos(1) := 0;
				servo_pos(2) := 1;
				servo_pos(3) := 0;
			end if;

				-- Downgrade the 50MHz clock to 12.75kHz
				if freq_div_count <= period then
					freq_div_count := freq_div_count + 1;
				else
					cnt := cnt + 1;
					freq_div_count := 0;
				end if;

				-- Depending on the requested position of the servo use a different duty cycle count
				for i in 0 to 3 loop
					if servo_pos(i) = 0 then
						if cnt >= duty_count_0 then
							servo(i) <= '0';
						else 
							servo(i) <= '1';
						end if;
					elsif servo_pos(i) = 1 then
						if cnt >= duty_count_1 then
							servo(i) <= '0';
						else 
							servo(i) <= '1';
						end if;
					end if;
				end loop;

				-- Reset the counter if it reaches the maximum count
				if cnt >= MAX_COUNT then 
					cnt := 0;					
				end if;
--			end if;
		end if;
	end process;

end rtl;
