library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entity declaration
entity LED_Control_TEST is
    Port ( SW  : in  STD_LOGIC;  -- Input from the switch
           LED : out STD_LOGIC   -- Output to the LED
         );
end LED_Control_TEST;

-- Architecture body
architecture Behavioral of LED_Control_TEST is
begin
    -- Process to control LED based on switch
    process(SW)
    begin
        if SW = '1' then
            LED <= '1';  -- Turn on the LED when switch is ON
        else
            LED <= '0';  -- Turn off the LED when switch is OFF
        end if;
    end process;
end Behavioral;
