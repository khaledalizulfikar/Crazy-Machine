Library IEEE;
use ieee.std_logic_1164.all;

ENTITY Button_test IS
	PORT( D:IN std_logic;
			Q:OUT std_logic
	);
END entity;


ARCHITECTURE arch OF Button_test IS
	BEGIN

		Q <= D;

END arch;