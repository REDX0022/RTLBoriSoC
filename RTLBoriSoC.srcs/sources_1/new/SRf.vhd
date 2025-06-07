entity SRf is
    port (
        a : in std_logic_vector(31 downto 0);
        shamt : in std_logic_vector(4 downto 0);
        is_arithmetic : in std_logic;
        outp : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of SRf is
begin
    process(a, shamt, is_arithmetic)
    variable temp : std_logic_vector(31 downto 0);
    begin
        if is_arithmetic = '1' then
            temp := std_logic_vector(shift_right(signed(a), to_integer(unsigned(shamt))));
        else
            temp := std_logic_vector(shift_right(unsigned(a), to_integer(unsigned(shamt))));
        end if;
        outp <= temp;
    end process;
end architecture;