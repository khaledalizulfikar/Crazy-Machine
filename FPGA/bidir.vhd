LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY bidir IS
    PORT(
        bidir   : INOUT STD_LOGIC;
        clk : IN STD_LOGIC;
        LED    : OUT STD_LOGIC_vector(1 downto 0)		  
		  );

END bidir;

ARCHITECTURE maxpld OF bidir IS

type STATEMACHINE is (s_chargecapacitor, s_readhightime);
SIGNAL  sensorstate  : STD_LOGIC;  -- DFF that stores value from input.                                           

constant chargetime   : natural := 250; --10us
signal chargetimer  : natural range 0 to chargetime - 1 := 0;

constant readtime   : natural := 75000; --3000us
signal readtimer  : natural range 0 to readtime - 1 := 0;
SIGNAL  dischargetime  : natural range 0 to readtime - 1 := 0;

signal state : STATEMACHINE := s_chargecapacitor; 

BEGIN                                        
	 
	process(clk, bidir) --statemachine that cycles through input, output
	BEGIN
		if rising_edge( CLK ) then
		case state is
			when s_chargecapacitor =>
				bidir <= '1'; --charge the capacitor
				chargetimer <= chargetimer + 1;	
			
				if chargetimer < chargetime - 1 then --time has reached 10 microseconds
					state <= s_chargecapacitor;
							
				else
					state <= s_readhightime;					
				end if;
			
			when s_readhightime =>
				bidir <= 'Z';
				sensorstate <= bidir;
				LED(1) <= '1';
				readtimer <= readtimer + 1;
				
				if sensorstate = '1' and readtimer < readtime - 1 then --if sensor state is still high and time is less than 3000us
					state <= s_readhightime;
					
				else if sensorstate = '0' or readtimer > readtime - 1 then
					dischargetime <= readtimer;
					if dischargetime < 74998 then --2000us
						LED(0) <= '1';
					else
						LED(0) <= '0';
					end if;
					state <= s_chargecapacitor;	
				end if;
				end if;
		end case;
		end if;
	END PROCESS;
END maxpld;
