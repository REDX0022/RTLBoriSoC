

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;




entity cmpuf is
    port(
        a : in std_logic_vector(31 downto 0);
        b : in std_logic_vector(31 downto 0);
        LTU : out std_logic
    );
end entity;

architecture RTL of cmpuf is
    begin
    process(a, b)
    begin
        if(unsigned(a) < unsigned(b)) then
            LTU <= '1';
        else
            LTU <= '0';
        end if;
    end process;

end architecture RTL;