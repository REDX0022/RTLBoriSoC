


entity reg is
    generic(
        w: natural := 32
        rising: boolean := True
    );
    port(
        rst: in std_logic;
        clk: in std_logic;
        en: in std_logic;
        data_in: in std_logic_vector(w-1 downto 0);
        data_out: out std_logic_vector(w-1 downto 0)


    );

end entity;


architecture RTL of reg is
    signal sto: std_logic_vector(w-1 downto 0);
    begin;
    if (rising=True) generate
            process
            begin
            if(rst = '1') then
                sto<=(others=>0);
            elsif(rising_edge(clk)) then --reset is more important than value ig
                sto<=data_in;
            end if;

            data_out<=sto;
            
            end process;
        end generate;
    else generate
            process
            begin
            if(rst = '1') then
                sto<=(others=>0);
            elsif(falling_edge(clk)) then --reset is more important than value ig
                sto<=data_in;
            end if;

            data_out<=sto;

            end process;
        end generate;
    end if;
end architecture RTL;