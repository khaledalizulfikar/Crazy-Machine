Library IEEE;
use ieee.std_logic_1164.all;

ENTITY Reg1bit IS
	PORT( D, RST, CLK, ENB:IN std_logic;
			Q:OUT std_logic
	);
END entity;


ARCHITECTURE arch OF Reg1bit IS
	BEGIN
		PROCESS(CLK)
			BEGIN
				IF CLK'EVENT AND CLK='1' THEN
					IF RST='0' THEN
						Q<='0';
					ELSE
						IF ENB='1' THEN
							Q<=D;
						END IF;
					END IF;
				END IF;
		END PROCESS;
END arch;