--this does not work at the end, we need a double input double output ALU
entity instr_dec is
    port(
        reg_wen: out std_logic;
        buffer_wen: out std_logic;
        instr_wen: out std_logic;
        PC_wen: out std_logic;
        ALU_res_mux: out std_logic(2 downto 0);
        adder_sp_mux: out std_logic;
        
    );

end entity;