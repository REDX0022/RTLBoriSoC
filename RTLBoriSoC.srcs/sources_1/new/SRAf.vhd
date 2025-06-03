library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SRAf is
    port (
        a : in std_logic_vector(31 downto 0);
        shamt : in std_logic_vector(4 downto 0);
        outp : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of SRAf is
begin
    process(a, shamt)
    begin
        outp <= std_logic_vector(shift_right(signed(a), to_integer(unsigned(shamt))));
    end process;
end architecture RTL;