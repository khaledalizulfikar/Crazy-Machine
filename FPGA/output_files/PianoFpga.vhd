library ieee;
use ieee.std_logic_1164.all;

entity PianoFpga is 
port( a : in STD_LOGIC;
b : in STD_LOGIC;
c : in STD_LOGIC;
d : in STD_LOGIC;
e : in STD_LOGIC;
f : in STD_LOGIC;
g : in STD_LOGIC;
clk: in  STD_LOGIC;
hexo: out std_logic_vector (6 downto 0);
hex1: out std_logic_vector(6 downto 0);
audioout : out STD_LOGIC);

end entity PianoFpga;

architecture piano of  PianoFpga is 
	signal counter: integer:=0;
	signal temp_out : STD_LOGIC := '0';
	signal note :  std_logic_vector(2 downto 0);
  signal seg7display: std_logic_vector(6 downto 0);
  signal seg7display1: std_logic_vector(6 downto 0);
	begin



	counterproc : process(clk, note)
	begin
	if(rising_edge(clk)) then
	case note is 
		when "000" => 
				if (counter >= 18180  ) then 
						counter <= 0;
						temp_out <= not temp_out;
				else
						counter <= counter+ 1;
				end if;
	-- 7999342 clk 8MHz/note_Freqency
		when "001" => 
				if (counter >= 16192) then   -- 440Hz do
						counter <= 0;
						temp_out <= not temp_out;
				else
						counter <= counter+ 1;
				end if;
		when "010" => 
				if (counter >= 15290) then    --494hz re
						counter <= 0;
						temp_out <= not temp_out;
				else
						counter <= counter+ 1; 
				end if;
		when "011" => 
				if (counter >= 13628) then   -- 593hz 
						counter <= 0;
						temp_out <= not temp_out;
				else                                                                                                                                                                                         
						counter <= counter+ 1;
				end if;
		when "100" => 
				if (counter >= 12140) then 
						counter <= 0;
						temp_out <= not temp_out;
				else
						counter <= counter+ 1;
				end if;
		when "101" => 
				if (counter >= 11461) then 
						counter <= 0;
						temp_out <= not temp_out;
				else
						counter <= counter+ 1;
				end if;
		when "110" => 
				if (counter >= 10203) then 
						counter <= 0;
						temp_out <= not temp_out;
				else
						counter <= counter+ 1;
				end if;
		when others =>
					temp_out <= '0';
					counter <= 0;
		end case;
	end if;
	
	end process counterproc;