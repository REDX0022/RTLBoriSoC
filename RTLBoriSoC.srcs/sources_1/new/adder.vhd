
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity adder is
    port (
        a : in std_logic_vector(31 downto 0);
        b : in std_logic_vector(31 downto 0);
        sum : out std_logic_vector(31 downto 0);
        subtr : in std_logic
    );
end entity;

architecture RTL of adder is
begin
    process(a, b)
        
    begin
       -- carry := '0'; -- Initialize carry to 0 --this just does not infer an adder
        --for i in 0 to 31 loop
            --sum_var(i) := a(i) xor b(i) xor carry;
            --carry := (a(i) and b(i)) or (carry and (a(i) xor b(i)));
        --end loop;
        --sum <= sum_var; -- Assign the result to the output
        case subtr is
            when '0' => -- addition
                sum <= std_logic_vector(signed(a) + signed(b)); -- this infers an adder
            when '1' => -- subtraction
                sum <= std_logic_vector(signed(a) - signed(b)); -- this infers a subtractor
            when others =>
                sum <= (others => '0'); -- default case, set sum to zero
        end case;
    end process;
end architecture;