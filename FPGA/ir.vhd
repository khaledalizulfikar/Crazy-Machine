library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ir is
    port (
        -- external
        clk : in std_logic;
        cal_btn : in std_logic;
        rst_btn : in std_logic;
        sig_io : inout std_logic;
        finish_state : out std_logic;
        
        -- internal
        charge : out std_logic
    );
end entity ir;

architecture Behavioral of ir is
    signal pulse : std_logic;
    signal enable : std_logic;
    signal old_enable : std_logic_vector(1 downto 0);
    signal count : unsigned(21 downto 0);
    signal charge_reg : std_logic;
    signal still_lap : std_logic;
    signal pulse_count, hold_count, cal_count : unsigned(25 downto 0);
    signal lap : std_logic_vector(2 downto 0);
    signal finish : std_logic;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_btn = '1' then
                lap <= (others => '0');
                finish <= '1';
            end if;
            
            count <= count + 1;
            
            if to_integer(unsigned(count(18 downto 13))) = 63 then -- 1.28us charge every 655us
                enable <= '0';
                charge_reg <= '1';
            else
                enable <= '1';
                charge_reg <= '0';
                pulse_count <= pulse_count - unsigned(pulse);
            end if;

            if enable = '0' and old_enable(1) = '1' then
                hold_count <= pulse_count;
            end if;

            if enable = '0' and old_enable(1) = '0' then
                pulse_count <= (others => '1');
            end if;

            if cal_btn = '1' then
                if enable = '0' and old_enable(1) = '1' then
                    cal_count <= hold_count;
                    lap <= (others => '0');
                end if;
            else
                if enable = '0' and old_enable(1) = '1' then
                    if hold_count > cal_count - 6 and cal_count < hold_count + 6 then
                        if still_lap = '0' then
                            lap <= std_logic_vector(unsigned(lap) + 1);
                            still_lap <= '1';
                        end if;
                    else
                        still_lap <= '0';
                    end if;
                end if;
            end if;

            if lap = "011" then
                finish <= '0';
                lap <= (others => '0');
            end if;

            old_enable <= enable & old_enable(1);
        end if;
    end process;

    charge <= charge_reg;
    finish_state <= finish;

    sig_io <= 'Z' when enable = '1' else charge_reg;

end architecture Behavioral;
