-- http://www.nandland.com
-- https://youtu.be/Vh0KdoXaVgU?t=23m

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_RX is

	generic (

		g_CLKS_PER_BIT : integer := 5208;  -- 50Mhz/9600bps
		g_CLKS_PER_HALF_BIT : integer := 2604  -- 50Mhz/9600bps/2
	);

	port(

		CLK           : in std_logic;
		RX_LINE       : in std_logic;
		RX_DATA_VALID : out std_logic;
		RX_DATA_buffer : buffer std_logic_vector( 7 downto 0 );  -- buffer
		RX_DATA : out std_logic_vector( 7 downto 0 ) -- reg out
	);

end entity;


architecture arch of UART_RX is
	type ascii_data_type is array(0 to 4) of std_logic_vector(7 downto 0);
	type STATEMACHINE is ( 

		s_idle,      -- waiting for data stream
		s_startBit,  -- detected start bit
		s_dataBits,  -- gathering data bits
		s_stopBit    -- detected stop bit
	);

	signal ascii_table : ascii_data_type;
	signal state : STATEMACHINE := s_idle;

	signal clkCount  : integer range 0 to g_CLKS_PER_BIT - 1 := 0;
	signal dataIndex : integer range 0 to 7 := 0;
	signal data      : std_logic_vector( 7 downto 0 ) := ( others => '0' );
	signal dataValid : std_logic := '0';

	--signal sm_state : std_logic_vector( 2 downto 0 );  -- for simulation

begin

	RX_DATA_VALID <= dataValid;
	RX_DATA_buffer <= data;
	
	ascii_table(0) <= "01000110"; --PATH1
	ascii_table(1) <= "01000111"; --PATH2
	ascii_table(2) <= "01001000"; --PATH3
	ascii_table(3) <= "01001001"; --PATH4
	ascii_table(4) <= "01001010"; --PATH5
	
	output_register : process (CLK)
	begin
		for i in 0 to 4 loop
			if RX_DATA_buffer = ascii_table(i) then
				RX_DATA <= ascii_table(i);
			end if;
		end loop;
	end process;

	process( CLK )

	begin

		if rising_edge( CLK ) then

			case state is

				-- Idle state

				when s_idle =>

					dataValid <= '0';
					clkCount <= 0;
					dataIndex <= 0;

					if RX_LINE = '0' then  -- start bit detected

						state <= s_startBit;

					else
						
						state <= s_idle;

					end if;

				-- Start bit state. Check to make sure still low ( not spurious )

				when s_startBit =>

					if clkCount = g_CLKS_PER_HALF_BIT then  -- sample bit middle

						if RX_LINE = '0' then -- if still low, go to next state

							clkCount <= 0; -- cause reset here, clkCount + period ends up at middle of next bit

							state <= s_dataBits;

						else  -- else false read, go back to idle
							
							state <= s_idle;

						end if;

					else  -- ?

						clkCount <= clkCount + 1;

						state <= s_startBit;

					end if;

				-- Data bits state. Gather data

				when s_dataBits =>

					if clkCount < g_CLKS_PER_BIT - 1 then   -- wait till reach bit middle

						clkCount <= clkCount + 1;

						state <= s_dataBits;

					else  --- ?
						
						clkCount <= 0;

						data( dataIndex ) <= RX_LINE;  -- read the bit

						-- Check if received all the bits

						if dataIndex < 7 then

							dataIndex <= dataIndex + 1;

							state <= s_dataBits;

						else
							
							dataIndex <= 0;

							state <= s_stopBit;
							
						end if ;

					end if;

				-- Stop bit state

				when s_stopBit =>

					if clkCount < g_CLKS_PER_BIT - 1 then -- wait till reach bit middle
						
						clkCount <= clkCount + 1;

						state <= s_stopBit;

					else  --- done reading frame

						dataValid <= '1';

						clkCount <= 0;

						state <= s_idle;

					end if;

				-- Shouldn't get here

				when others =>

					state <= s_idle;

			end case;

		end if;
	end process;

end architecture;