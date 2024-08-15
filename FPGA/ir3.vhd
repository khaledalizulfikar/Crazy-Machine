library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ir2 is --infrared calibration method
    Port (
        -- external
        clk : in STD_LOGIC;
        cal_btn : in STD_LOGIC;
        rst_btn : in STD_LOGIC;
        sig_io : inout STD_LOGIC;
        finish_state : out STD_LOGIC;
        charge : buffer STD_LOGIC
    );
end ir2;

architecture Behavioral of ir2 is
    signal pulse : STD_LOGIC;

    signal enable : STD_LOGIC;
    signal old_enable : STD_LOGIC_VECTOR(1 downto 0);
    signal count : STD_LOGIC_VECTOR(21 downto 0);
    signal charge_reg : STD_LOGIC;
    signal still_lap : STD_LOGIC;
    signal pulse_count, hold_count, cal_count : STD_LOGIC_VECTOR(25 downto 0);
    signal lap : STD_LOGIC_VECTOR(2 downto 0);
    signal finish : STD_LOGIC;

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_btn = '1' then
                lap <= "000";
                finish <= '1';
            end if;
            count <= count + 1;
            if count(18 downto 13) = "111111" then -- 1.28us charge every 655us
                enable <= '0';
                charge_reg <= '1';
            else
                charge_reg <= '0';
                enable <= '1';
                pulse_count <= pulse_count - pulse;
            end if;
            
            if (enable = '0' and old_enable(1) = '1') then
                hold_count <= pulse_count;
            end if;
            
            if (enable = '0' and old_enable(1) = '0') then
                pulse_count <= "11111111111111111111111111";
            end if;
            
            if cal_btn = '1' then
                if (enable = '0' and old_enable(1) = '1') then
                    cal_count <= hold_count;
                    lap <= "000";
                end if;
            else
                if (enable = '0' and old_enable(1) = '1') then
                    if (hold_count > cal_count - "000000000110" and cal_count < hold_count + "000000000110") then
                        if still_lap = '0' then
                            lap <= lap + 1;
                            still_lap <= '1';
                        end if;
                    else
                        still_lap <= '0';
                    end if;
                end if;
            end if;
            
            if lap = "001" then
                finish <= '0';
                lap <= "000";
            end if;
            
            old_enable <= old_enable(0) & enable;
				if enable = '0' then
					sig_io <= charge;
				else
					sig_io <= 'Z';
				end if;
        end if;
    end process;

    pulse <= sig_io;

    charge <= charge_reg;
    finish_state <= finish;

end Behavioral;
