
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- You must define a reusable array type for vector arrays

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity MUX1 is
    generic (
        N : natural;  -- 2 bits → 4 elements
    );
    port (
        sel     : in std_logic_vector(N-1 downto 0); -- N-bit select
        datain  : in std_logic_vector(0 to 2**N-1);
        dataout : out std_logic --32 bit hardcoded because it might not recognize and syntehsize types well otherwise
    );
end entity;

architecture RTL of MUX1 is
begin
    process(sel, datain)
    begin
       -- assert (to_integer(unsigned(sel)) < 2**N) 
            --report "MUX instance '" & 
               --INSTANCE_NAME & 
               --"' (from " & 
               --PATH_NAME & 
               --"): Select out of range" 
            --severity failure; -- this might not work
        dataout <= '0'; -- default value
        
        
        dataout <= datain(to_integer(unsigned(sel)));
    end process;
end RTL;
