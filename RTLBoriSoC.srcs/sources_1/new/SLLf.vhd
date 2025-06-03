library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SLLf is
    port (
        a : in std_logic_vector(31 downto 0);
        shamt : in std_logic_vector(4 downto 0); -- 5 bits for shift amount
        outp : out std_logic_vector(31 downto 0)
    );
end entity;
architecture RTL of SLLf is
begin
    process(a, shamt)
    begin
        -- Perform logical left shift
        outp <= std_logic_vector(shift_left(unsigned(a), to_integer(unsigned(shamt))));

    end process;
end architecture RTL;