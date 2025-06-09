--this is the next tle
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


library WORK;
use work.MUX_types.all; -- Import the MUX types package
use WORK.mem_pack.all; -- Import the memory package

entity cpu is
    generic (
        SIMULATION : boolean := false
    );
    port(
        clk: in std_logic;
        rst: in std_logic;
        addrout: out std_logic_vector(31 downto 0); -- Address output for memory
        dataout: out std_logic_vector(31 downto 0); -- Data output for memory
        datain: in std_logic_vector(31 downto 0);   -- Data input for memory
        instrin: in std_logic_vector(31 downto 0); -- Instruction input, can be used for simulation
        addrPC: out std_logic_vector(31 downto 0) -- 
        -- synthesis translate_off
        ;
        sim_instr: out std_logic_vector(31 downto 0) := (others => '0');
        reg_sim: out vector_array(0 to 31) := (others => (others => '0')); -- Simulation interface for registers
        PC_sim : out std_logic_vector(31 downto 0) := (others => '0') -- Simulation interface for Program Counter
        -- synthesis translate_on
    );
end entity;


architecture Structural of cpu is

    signal instr: std_logic_vector(31 downto 0) := (others => '0');
    signal r1: std_logic_vector(31 downto 0) := (others => '0');
    signal r2: std_logic_vector(31 downto 0) := (others => '0');
    signal adder_r1_sp: std_logic_vector(31 downto 0) := (others => '0');
    signal adder_sp_sel: std_logic := '0';
    signal imm: std_logic_vector(19 downto 0) := (others => '0'); --we are gonna use the same bus for all imms, the biggest one is 20 bits, also we need to sign extend it
    signal imm_sel: std_logic_vector(1 downto 0) := (others => '0'); -- selector for immediate type, 00 for 12-bit signed, 01 for 12-bit unsigned, 10 for 20-bit signed, 11 for upper 20 bits unsigned, IMPORTANT: LSB is the sign selector(0 for signed 1 for signed)
    signal funct3: std_logic_vector(2 downto 0) := (others => '0'); -- Function code for the instruction
    signal pc_branch: std_logic := '0';
    signal instr_branch: std_logic := '0';
    signal funct7: std_logic_vector(6 downto 0) := (others => '0'); -- Function code for the instruction

    signal PC_sig: std_logic_vector(31 downto 0) := (others => '0'); -- Program Counter signal
    signal PC_in_sig: std_logic_vector(31 downto 0) := (others => '0'); -- Program Counter input signal
    signal PC_inc_sig: std_logic_vector(31 downto 0) := (others => '0'); -- Incremented Program Counter signal
    signal op2_sel: std_logic := '0'; -- ALU second operand selector
    --signal branch_sel: std_logic_vector(2 downto 0); -- Branch selector
    signal rs1_sel: std_logic_vector(4 downto 0) := (others => '0'); -- Register source 1 selection
    signal rs2_sel: std_logic_vector(4 downto 0) := (others => '0'); -- Register source 2 selection
    signal rd_sel: std_logic_vector(4 downto 0) := (others => '0'); -- Register destination selection 

    signal ALU_res: std_logic_vector(31 downto 0) := (others => '0'); -- ALU result signal
    signal adder_res: std_logic_vector(31 downto 0) := (others => '0'); -- ALU adder result signal, not used in this example
    signal PC_branch_mux_in: vector_array(0 to 1) := (others => (others => '0'));

    signal regs_in_sel: std_logic_vector(1 downto 0) := (others => '0'); -- this chooses between ALU_res, INC(PC), memory, and buffer
    signal regs_in_sig: std_logic_vector(31 downto 0) := (others => '0'); -- Register input signal
    signal regs_sp_out_sig: std_logic_vector(31 downto 0) := (others => '0'); -- Stack pointer output signal, not used in this example
    signal regs_in_mux_in: vector_array(0 to 3) := (others => (others => '0')); -- Input for the register input multiplexer

    signal AUIPC_or_branch_in: vector_array(0 to 1) := (others => (others => '0')); -- Input for the AUIPC or branch multiplexer
    signal AUIPC_or_branch_sel: std_logic ; -- Selector for AUIPC or branch operation
    signal r1_or_PC: std_logic_vector(31 downto 0) := (others => '0'); -- Register 1 or Program Counter selection signal

    signal mem_addrout_mux_in: vector_array(0 to 1) := (others => (others => '0')); -- Input for the memory address output multiplexer



    --signal mem_dataout: std_logic_vector(31 downto 0) := (others => '0'); -- Memory data output signal
    --signal mem_addrout: std_logic_vector(31 downto 0) := (others => '0'); -- Memory address output signal
    --signal mem_en: std_logic := '0'; --TODO: Change this when writing the write buffer
    --signal mem_datain: std_logic_vector(31 downto 0) := (others => '0'); -- Memory data input signal
    component ALUdp is
        port (
            r1 : in std_logic_vector(31 downto 0);
            r2 : in std_logic_vector(31 downto 0);
            adder_r1_sp: in std_logic_vector(31 downto 0);
            adder_sp_sel: in std_logic;
            imm : in std_logic_vector(19 downto 0); --we are gonna use the same bus for all imms, the biggest one is 20 bits, also we need to sign extend it
            imm_sel: in std_logic_vector(1 downto 0); -- selector for immediate type, 00 for 12-bit signed, 01 for 12-bit unsigned, 10 for 20-bit signed, 11 for upper 20 bits unsigned, IMPORTANT: LSB is the sign selector(0 for signed 1 for signed)
            op : in std_logic_vector(8 downto 0); -- operation selector
            result : out std_logic_vector(31 downto 0);
            adder_res : out std_logic_vector(31 downto 0); -- ALU adder result signal, not used in this example
            subtr : in std_logic; -- flag to indicate if the operatioon is a subtraction, this might be poor design
            branch: out std_logic; -- flag to indicate if to use the address from the ALU or the PC increment
            funct3: in std_logic_vector(2 downto 0); -- Function code for the instruction
            op2_sel: in std_logic
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
        --branch_sel: in std_logic_vector(2 downto 0); -- Branch selector
        funct3: out std_logic_vector(2 downto 0); -- Function code for the instruction
        regs_in_sel: out std_logic_vector(1 downto 0); -- this chooses between ALU_res, INC(PC), memory, and buffer
        AUIPC_or_branch_sel: out std_logic -- Selector for AUIPC or branch operation
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

    component REGS is
        port(
            clk: in std_logic;
            rst: in std_logic;
            en: in std_logic;
            sel1: in std_logic_vector(4 downto 0);
            sel2: in std_logic_vector(4 downto 0);
            sel3: in std_logic_vector(4 downto 0);
            selin: in std_logic_vector(4 downto 0); 
            datain: in std_logic_vector(31 downto 0);
            dataout1: out std_logic_vector(31 downto 0);
            dataout2: out std_logic_vector(31 downto 0);
            dataout3: out std_logic_vector(31 downto 0)
            -- synthesis translate_off
            ;
            reg_sim: out vector_array(0 to 31) -- Simulation interface for registers
            -- synthesis translate_on
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
                r1 => r1_or_PC,
                r2 => r2,
                adder_r1_sp => regs_sp_out_sig, -- Stack pointer output, not used in this example
                adder_sp_sel => adder_sp_sel,
                imm => imm,
                imm_sel => imm_sel,
                op => (others => '0'), -- Placeholder for operation selector
                adder_res => adder_res,
                result => ALU_res, -- Output not used in this example
                subtr => funct7(5), --TODO: check this 
                branch => instr_branch, 
                funct3 => funct3, -- Connect to appropriate signals
                op2_sel => op2_sel -- Connect to appropriate signals
                --branch_sel => branch_sel -- Connect to branch selector
            );

        --------------------REGS--------------------
        regs_inst: REGS
            port map(
                clk => clk,
                rst => rst,
                en => '1',--TODO: Figure out what to do with this
                sel1 => rs1_sel, -- rs1 selection
                sel2 => rs2_sel, -- rs2 selection
                sel3 => "00000", -- WARNING: I dont really remember what this is for
                selin => rd_sel, -- Write select port
                datain => regs_in_sig, 
                dataout1 => r1, 
                dataout2 => r2, 
                dataout3 => regs_sp_out_sig -- Stack pointer output, not used in this example 
                -- synthesis translate_off
                ,
                reg_sim => reg_sim -- Simulation interface for registers
                -- synthesis translate_on
            );

        regs_in_mux: MUX
            generic map(
                N => 2 -- 2 inputs for the MUX
            )
            port map(
                sel => regs_in_sel, -- Select signal for the MUX
                datain => regs_in_mux_in, -- Placeholder for register inputs
                dataout => regs_in_sig -- Output not used in this example
            );
        regs_in_mux_in(0) <= ALU_res; -- ALU result input
        regs_in_mux_in(1) <= PC_inc_sig; -- Incremented PC input
        regs_in_mux_in(2) <= datain; -- Memory input
        regs_in_mux_in(3) <= (others => '0'); -- Buffer input, placeholder for future use

        AUIPC_or_branch: MUX
            generic map(
                N => 1 -- 1 input for the MUX
            )
            port map(
                sel => to_slv(AUIPC_or_branch_sel),
                datain => AUIPC_or_branch_in, -- Placeholder for AUIPC or branch input
                dataout => r1_or_PC -- Output not used in this example
            );
        AUIPC_or_branch_in(1) <= PC_sig; -- Connect to the PC signal
        AUIPC_or_branch_in(0) <= r1; -- Connect to the ALU result signal


        -------------------CTRL---------------------
        instr_reg_inst: reg
            generic map(
                w => 32,
                rising => true
            )
            port map(
                rst => rst,
                clk => clk,
                en => '1', --This should be fine, because we take an instruction every clock cycle
                datain => instrin,
                dataout => instr 
            );
        instr_decoder_inst: instr_dec
            port map(
                reg_wen => open, -- Connect to appropriate signals
                buffer_wen => open,
                instr_wen => open,
                PC_wen => open,
                funct3 => funct3, -- Connect to ALU result selector
                adder_sp_sel => adder_sp_sel, -- Connect to adder
                imm_sel => imm_sel, -- Connect to immediate selection
                op2_sel => op2_sel, -- Connect to ALU second operand selector
                rs1_sel => rs1_sel, -- Connect to register source 1 selection
                rs2_sel => rs2_sel, -- Connect to register source 2 selection
                rd_sel => rd_sel, -- Connect to register destination selection
                funct7 => funct7,
                imm => imm, -- Connect to immediate signal
                branch_in => instr_branch, -- Connect to instruction branch signal
                branch_out => pc_branch, -- Connect to PC branch signal
                instr => instr, -- Connect the instruction input
                --branch_sel => branch_sel, -- Connect to branch selector
                regs_in_sel => regs_in_sel, -- Connect to register input selection
                AUIPC_or_branch_sel => AUIPC_or_branch_sel -- Connect to AUIPC or branch selector
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
                dataout => PC_inc_sig -- Output not used in this example
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
            PC_branch_mux_in(0) <= PC_inc_sig; -- Incremented PC input
            PC_branch_mux_in(1) <= adder_res; 
        
        --------------------MEM--------------------
        
        addrPC <= PC_sig; -- Connect the Program Counter to the memory address input
       
        



        -------------------- Simulation-only instruction trace output --------------------
        -- synthesis translate_off
        sim_trace: if SIMULATION generate
            process(instr)
            begin
                
                    sim_instr <= instr;
                
            end process;
            process(PC_sig)
            begin
                PC_sim <= PC_sig; -- Output the current value of the Program Counter
            end process;

        end generate;
        -- synthesis translate_on
        

end architecture Structural;