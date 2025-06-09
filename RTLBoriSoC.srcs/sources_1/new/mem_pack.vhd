library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package mem_pack is
    type ram_type is array (0 to 2**14-1) of  std_logic_vector(31 downto 0);
end package;