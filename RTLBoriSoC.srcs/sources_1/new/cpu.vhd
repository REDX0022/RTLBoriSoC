--this is the next tle
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


library WORK;
use work.MUX_types.all; -- Import the MUX types package

entity cpu is
    port(
        clk: in std_logic;
        rst: in std_logic
        
    );
end entity;


architecture Structural of cpu is

    signal instr: std_logic_vector(31 downto 0);
    signal r1: std_logic_vector(31 downto 0);
    signal r2: std_logic_vector(31 downto 0);
    signal adder_r1_sp: std_logic_vector(31 downto 0);
    signal adder_sp_sel: std_logic;
    signal imm: std_logic_vector(20 downto 0); --we are gonna use the same bus for all imms, the biggest one is 20 bits, also we need to sign extend it
    signal imm_sel: std_logic_vector(1 downto 0); -- selector for immediate type, 00 for 12-bit signed, 01 for 12-bit unsigned, 10 for 20-bit signed, 11 for upper 20 bits unsigned, IMPORTANT: LSB is the sign selector(0 for signed 1 for signed)
    signal ALU_res_sel: std_logic_vector(2 downto 0); -- selector for the ALU result, this is used to select the result of the ALU operation
    signal pc_branch: std_logic;
    signal instr_branch: std_logic;
    signal funct7: std_logic_vector(6 downto 0); -- Function code for the instruction
    

    signal PC_sig: std_logic_vector(31 downto 0); -- Program Counter signal
    signal PC_in_sig: std_logic_vector(31 downto 0); -- Program Counter input signal
    signal op2_sel: std_logic; -- ALU second operand selector
    signal branch_sel: std_logic_vector(2 downto 0); -- Branch selector


    signal ALU_res: std_logic_vector(31 downto 0); -- ALU result signal
    signal PC_branch_mux_in: vector_array(0 to 1);

    component ALUdp is
        port (
        r1 : in std_logic_vector(31 downto 0);
        r2 : in std_logic_vector(31 downto 0);
        adder_r1_sp: in std_logic_vector(31 downto 0);
        adder_sp_sel: in std_logic;

        imm : in std_logic_vector(20 downto 0); --we are gonna use the same bus for all imms, the biggest one is 20 bits, also we need to sign extend it
        imm_sel: in std_logic_vector(1 downto 0); -- selector for immediate type, 00 for 12-bit signed, 01 for 12-bit unsigned, 10 for 20-bit signed, 11 for upper 20 bits unsigned, IMPORTANT: LSB is the sign selector(0 for signed 1 for signed)
        op : in std_logic_vector(8 downto 0); -- operation selector
        result : out std_logic_vector(31 downto 0);
        subtr : in std_logic; -- flag to indicate if the operatioon is a subtraction, this might be poor design
        branch: out std_logic; -- flag to indicate if to use the address from the ALU or the PC increment
        ALU_res_sel: out std_logic_vector(2 downto 0); -- selector for the ALU result, this is used to select the result of the ALU operation
        op2_sel: out std_logic;
        branch_sel: in std_logic_vector(2 downto 0)
         );
    end component;

    component INCf is
        port(
            datain: in std_logic_vector(31 downto 0);
            dataout: out std_logic_vector(31 downto 0)
        );
    end component;

    component instr_dec is
        port(
        reg_wen: out std_logic;
        buffer_wen: out std_logic;
        instr_wen: out std_logic;
        PC_wen: out std_logic;
        ALU_res_sel: out std_logic_vector(2 downto 0);
        adder_sp_sel: out std_logic;
        imm_sel: out std_logic_vector(1 downto 0);
        op2_sel: out std_logic;
        rs1_sel: out std_logic_vector(4 downto 0);
        rs2_sel: out std_logic_vector(4 downto 0);
        rd_sel: out std_logic_vector(4 downto 0);
        funct7: out std_logic_vector(6 downto 0);
        imm: out std_logic_vector(19 downto 0);
        branch_in: in std_logic;
        branch_out: out std_logic;
        instr: in std_logic_vector(31 downto 0); -- Input instruction
        branch_sel: in std_logic_vector(2 downto 0) -- Branch selector
        );
    end component;

    
    component reg is
        generic(
            w: natural;
            rising: boolean
        );
        port(
            rst: in std_logic;
            clk: in std_logic;
            en: in std_logic;
            datain: in std_logic_vector(w-1 downto 0);
            dataout: out std_logic_vector(w-1 downto 0)
        );
    end component;

    component MUX is
        generic(
            N: natural -- Number of inputs
        );
        port(
            sel: in std_logic_vector(N-1 downto 0); -- Select signal
            datain: in vector_array(0 to 2**N-1); -- Input data
            dataout: out std_logic_vector(31 downto 0) -- Output data
        );
    end component;

    component MUX1 is
        generic(
            N: natural -- Number of inputs
        );
        port(
            sel: in std_logic_vector(N-1 downto 0); -- N-bit select
            datain: in std_logic_vector(0 to 2**N-1); -- Input data
            dataout: out std_logic -- Output data
        );
    end component;
    begin
        --------------------ALU--------------------
        ALUdp_inst: ALUdp
            port map(
                r1 => r1,
                r2 => r2,
                adder_r1_sp => adder_r1_sp,
                adder_sp_sel => adder_sp_sel,
                imm => imm,
                imm_sel => imm_sel,
                op => (others => '0'), -- Placeholder for operation selector
                result => ALU_res, -- Output not used in this example
                subtr => funct7(5), --TODO: check this 
                branch => instr_branch, 
                ALU_res_sel => ALU_res_sel, -- Connect to appropriate signals
                op2_sel => op2_sel, -- Connect to appropriate signals
                branch_sel => branch_sel -- Connect to branch selector
            );



        -------------------CTRL---------------------
        instr_reg_inst: reg
            generic map(
                w => 32,
                rising => true
            )
            port map(
                rst => rst,
                clk => clk,
                en => '1',
                datain => (others => '0'), -- Placeholder for instruction input
                dataout => instr -- Output not used in this example
            );
        instr_decoder_inst: instr_dec
            port map(
                reg_wen => open, -- Connect to appropriate signals
                buffer_wen => open,
                instr_wen => open,
                PC_wen => open,
                ALU_res_sel => ALU_res_sel, -- Connect to ALU result selector
                adder_sp_sel => adder_sp_sel, -- Connect to adder stack pointer selector
                imm_sel => open,
                op2_sel => op2_sel, -- Connect to ALU second operand selector
                rs1_sel => open,
                rs2_sel => open,
                rd_sel => open,
                funct7 => funct7,
                imm => open,
                branch_in => instr_branch, -- Connect to instruction branch signal
                branch_out => pc_branch, -- Connect to PC branch signal
                instr => instr, -- Connect the instruction input
                branch_sel => branch_sel -- Connect to branch selector
            );     
        PC_inst: reg
            generic map(
                w => 32,
                rising => false
            )
            port map(
                rst => rst,
                clk => clk,
                en => '1', -- Enable the PC register
                datain => PC_in_sig, -- Placeholder for PC input
                dataout => PC_sig -- Output not used in this example
            );  

        INCf_inst: INCf
            port map(
                datain => PC_sig, -- Connect to the PC signal
                dataout => PC_in_sig -- Output not used in this example
            );
        
        PC_branch_mux: MUX
            generic map(
                N => 1
            )
            port map(
                sel => to_slv(pc_branch), -- Select between ALU result and PC increment
                datain => PC_branch_mux_in, -- Placeholder for ALU result input
                dataout => PC_in_sig -- Output not used in this example
            );
            PC_branch_mux_in(0) <= PC_in_sig;
            PC_branch_mux_in(1) <= ALU_res; 

    
        

end architecture Structural;