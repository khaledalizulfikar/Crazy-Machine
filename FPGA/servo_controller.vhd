library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity servo_controller is
	Port ( clk : in  STD_LOGIC;
		reset : in  STD_LOGIC;
		button_l : in  STD_LOGIC;
		button_r : in  STD_LOGIC;
		pwm : out  STD_LOGIC_vector(3 downto 0)
		);
end servo_controller;

architecture RTL of servo_controller is

	component servo is
		Port ( clk : in  STD_LOGIC;
			reset : in  STD_LOGIC;
			button_l : in  STD_LOGIC;
			button_r : in  STD_LOGIC;
			pwm : out  STD_LOGIC
			);
	end component;
	
BEGIN

		gene: FOR i IN 0 TO 3 GENERATE
			servo_instance:servo PORT MAP(clk, reset, button_l, button_r, pwm(i));
		END GENERATE gene;

end architecture;