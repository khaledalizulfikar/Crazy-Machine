Library IEEE;

use ieee.std_logic_1164.all;

ENTITY Test_RegNbits IS
	PORT(SW:IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		LEDR:OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		KEY:IN std_logic_vector(1 downto 0)
	);
END entity;

ARCHITECTURE arch OF Test_RegNbits IS
	COMPONENT RegNbits IS
		PORT( D: IN std_logic_vector(3 downto 0);
			RST, CLK, ENB:IN std_logic;
			Q:OUT std_logic_vector(3 downto 0)
		);
	END COMPONENT;
	SIGNAL CLK:std_logic:='0';
	CONSTANT clk_period:TIME:=20 ns;
	BEGIN
		CLK<=not CLK after (clk_period/2);
		reg: RegNbits PORT MAP(D=>SW(3 downto 0), 
							 RST=>KEY(1),
							 CLK=>not KEY(0),
							 ENB=>SW(4),
							 Q=>LEDR(3 downto 0)
							 );
END arch;