-- filepath: c:\Users\ceran\Documents\RTLBoriSoC\RTLBoriSoC.srcs\sources_1\new\XORf.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity XORf is
    port (
        a : in std_logic_vector(31 downto 0);
        b : in std_logic_vector(31 downto 0);
        outp : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of XORf is
begin
    outp <= a xor b;
end architecture RTL;