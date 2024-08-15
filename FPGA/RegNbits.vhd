Library IEEE;

use ieee.std_logic_1164.all;
ENTITY RegNbits IS
	GENERIC(N:INTEGER :=4);
	PORT( D: IN std_logic_vector(N-1 downto 0);
			RST, CLK, ENB:IN std_logic;
			Q:OUT std_logic_vector(N-1 downto 0)
	);
END entity;

ARCHITECTURE arch OF RegNbits IS
	COMPONENT Reg1bit IS
		PORT( D, RST, CLK, ENB:IN std_logic;
			Q:OUT std_logic
		);
	END COMPONENT;
	BEGIN
		gene: FOR i IN 0 TO N-1 GENERATE
			reb_1bit:Reg1bit PORT MAP(D(i), RST, CLK, ENB, Q(i));
		END GENERATE gene;
END arch;