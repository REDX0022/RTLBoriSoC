library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LUI is
    port (
        imm20 : in std_logic_vector(19 downto 0);  -- 20-bit immediate
        outp  : out std_logic_vector(31 downto 0)  -- 32-bit result
    );
end entity;

architecture RTL of LUI is
begin
    outp <= imm20 & (others => '0');  -- upper 20 bits = imm20, lower 12 bits = 0
end architecture RTL;