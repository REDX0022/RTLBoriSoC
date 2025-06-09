

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;





entity cmpf is
    port(
        a : in std_logic_vector(31 downto 0);
        b : in std_logic_vector(31 downto 0);
        EQ : out std_logic;
        LT : out std_logic
    );
end entity;

architecture RTL of cmpf is
    begin
    process(a, b)
    begin
        if(a = b) then
            EQ <= '1';
            LT <= '0';
        elsif(signed(a) < signed(b)) then
            EQ <= '0';
            LT <= '1';
        else
            EQ <= '0';
            LT <= '0';
        end if;
    end process;

end architecture RTL;