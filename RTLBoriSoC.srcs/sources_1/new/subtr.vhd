library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;




entity subtr is
    port (
        a : in std_logic_vector(31 downto 0);
        b : in std_logic_vector(31 downto 0);
        diff : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of subtr is
    begin
    process(a, b)
        begin
        
        diff <= std_logic_vector(signed(a) - signed(b)); -- this infers a subtractor
    end process;
end architecture RTL;