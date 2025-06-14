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
        addrPC: out std_logic_vector(31 downto 0);
        mem_wen: out std_logic -- Memory write enable signal
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

    --signal buffer_wen_sig: std_logic := '0'; -- Memory write enable signal
    signal mem_regs_datain_sig : std_logic_vector(31 downto 0) := (others => '0'); -- Memory data input signal
    signal mem_datain_mux_in: vector_array(0 to 7) := (others => (others => '0')); -- Input for the memory data input multiplexer

    signal RW_op: std_logic := '0'; -- Read/Write operation signal, set to '1' for write operations
    signal R_sig: std_logic := '0'; -- Read signal, not used in this example
    signal W_sig: std_logic := '0'; -- Write signal, not used in this example
    signal B_sig: std_logic := '0'; -- Branch signal, not used in this example
    signal J_sig: std_logic := '0'; -- Jump signal, not used in this example

    -----------------ENABLE SIGNALS------------------
    signal buffer_wen: std_logic := '0'; -- Write buffer enable signal
    signal regs_wen: std_logic := '0'; -- Register write enable signal
    signal instr_wen: std_logic := '0'; -- Instruction write enable signal
    signal PC_wen: std_logic := '0'; -- Program Counter write enable signal
    signal write_buffer_en: std_logic := '0'; -- Write buffer enable signal for write operation

    signal mem_wen_FSM: std_logic := '0'; -- Memory write enable signal for FSM
    signal decoded_en_sig: std_logic := '0'; -- Decoded enable signal for write operation
    signal decoded_reg_in: std_logic_vector(55 downto 0) := (others => '0'); -- 56 bits
    signal decoded_reg_out: std_logic_vector(55 downto 0) := (others => '0'); -- 56 bits



    component FSM is
        port (
            clk: in std_logic;
            rst: in std_logic;
            RW_op: in std_logic; -- Read/Write operation signal
            mem_en: out std_logic; -- Memory enable signal for write operation
            reg_en: out std_logic; -- Register enable signal for write operation
            decoded_en: out std_logic; -- Decoded enable signal for write operation
            PC_en: out std_logic; -- PC enable signal for write operation
            instr_en: out std_logic; -- Instruction enable signal for write operation
            write_buffer_en: out std_logic -- Write buffer enable signal for write operation
        );
    end component;
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
            --reg_wen: out std_logic; --we dont need this because we will write 0 to 0 so we are fine
            --instr_wen: out std_logic; --comes from the fsm
            --PC_wen: out std_logic; --comes from the fsm
            --buffer_wen : out std_logic; -- does not exist anymore, we will write to memory directly
            funct3: out std_logic_vector(2 downto 0);
            adder_sp_sel: out std_logic;
            imm_sel: out std_logic_vector(1 downto 0);
            op2_sel: out std_logic;
            rs1_sel: out std_logic_vector(4 downto 0);
            rs2_sel: out std_logic_vector(4 downto 0);
            rd_sel: out std_logic_vector(4 downto 0);
            funct7: out std_logic_vector(6 downto 0);
            imm: out std_logic_vector(19 downto 0);
            branch_out: out std_logic;
            --branch_sel: in std_logic_vector(2 downto 0); -- Branch selectoro
            regs_in_sel: out std_logic_vector(1 downto 0); -- this chooses between ALU_res, INC(PC), memory, and buffer
            AUIPC_or_branch_sel: out std_logic;
            R : out std_logic; -- Read operation signal
            W : out std_logic; -- Write operation signal
            B : out std_logic; -- Branch operation signal
            J : out std_logic; -- Jump operation signal // 57 total bits, this encoding is very bad information density baddd
            instr: in std_logic_vector(31 downto 0) -- Input instruction
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
    component signext is
        generic(
            w: natural -- Width of the input to sign-extend
        );
        port(
            imm: in std_logic_vector(w-1 downto 0); -- Input immediate value
            imm_extended: out std_logic_vector(31 downto 0) -- Sign-extended output
        );
    end component;
    component zeroext is
        generic(
            w: natural -- Width of the input to zero-extend
        );
        port(
            imm: in std_logic_vector(w-1 downto 0); -- Input immediate value
            imm_extended: out std_logic_vector(31 downto 0) -- Zero-extended output
        );
    end component;
    begin
        
       
        --------------------ALU--------------------
        ALUdp_inst: ALUdp
            port map(
                r1 => r1_or_PC,
                r2 => r2,
                adder_r1_sp => PC_sig, -- TODO: Merge this with AUIPC 
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
                en => regs_wen,--TODO: Figure out what to do with this
                sel1 => rs1_sel, -- rs1 selection
                sel2 => rs2_sel, -- rs2 selection
                sel3 => "00000",
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
        regs_in_mux_in(2) <= mem_regs_datain_sig; -- Should be replaced with mux between memory and buffer
        regs_in_mux_in(3) <= (others => '0'); -- SHOULD ALWAYS BE 0 for the BRANCH isntr

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
         FSM_inst: FSM
            port map(
                clk => clk,
                rst => rst,
                RW_op => RW_op, -- Read/Write operation signal, set to '1' for write operations
                mem_en => mem_wen_FSM, -- Memory enable signal for write operation
                reg_en => regs_wen, -- Register enable signal for write operation
                decoded_en => decoded_en_sig, -- Decoded enable signal for write operation
                PC_en => PC_wen, -- PC enable signal for write operation
                instr_en => instr_wen -- Instruction enable signal for write operation
            );

        instr_reg_inst: reg
            generic map(
                w => 32,
                rising => true
            )
            port map(
                rst => rst,
                clk => clk,
                en => instr_wen, --This should be fine, because we take an instruction every clock cycle
                datain => instrin,
                dataout => instr 
            );
        instr_decoder_inst: instr_dec
            port map(
                instr => instr,
                rd_sel              => decoded_reg_in(4 downto 0),
                rs1_sel             => decoded_reg_in(9 downto 5),
                rs2_sel             => decoded_reg_in(14 downto 10),
                op2_sel             => decoded_reg_in(15),
                imm_sel             => decoded_reg_in(17 downto 16),
                adder_sp_sel        => decoded_reg_in(18),
                imm                 => decoded_reg_in(38 downto 19),
                funct3              => decoded_reg_in(41 downto 39),
                funct7              => decoded_reg_in(48 downto 42), -- 7 bits
                AUIPC_or_branch_sel => decoded_reg_in(49),
                R                   => decoded_reg_in(50),
                W                   => decoded_reg_in(51),
                B                   => decoded_reg_in(52),
                J                   => decoded_reg_in(53),
                regs_in_sel         => decoded_reg_in(55 downto 54)
            );
        process(B_sig,J_sig, instr_branch)
        begin
            PC_branch <= (instr_branch and B_sig) or J_sig; -- Set PC_branch to true if branch or jump instruction
        end process;

        decoded_reg_inst: reg
            generic map(
                w => 56, -- 56 bits
                rising => true
            )
            port map(
                rst => rst,
                clk => clk,
                en => decoded_en_sig,
                datain => decoded_reg_in,
                dataout => decoded_reg_out
            );
        -- decoded_reg_in(4 downto 0) <= rd_sel; -- Register destination selection
        -- decoded_reg_in(9 downto 5) <= rs1_sel; -- Register source 1 selection
        -- decoded_reg_in(14 downto 10) <= rs2_sel; -- Register source 2 selection
        -- decoded_reg_in(16) <= op2_sel; -- ALU second operand selector
        -- decoded_reg_in(18 downto 17) <= imm_sel; -- Immediate selection
        -- decoded_reg_in(19) <= adder_sp_sel; -- Adder selection
        -- decoded_reg_in(39 downto 20) <= imm; -- Immediate signal
        -- decoded_reg_in(42 downto 40) <= funct3; -- ALU result selector
        -- decoded_reg_in(48 downto 43) <= funct7; -- Function code for the instruction
        -- decoded_reg_in(49) <= AUIPC_or_branch_sel; -- AUIPC or branch selector
        -- decoded_reg_in(50) <= R_sig; -- Read signal, not used in this example
        -- decoded_reg_in(51) <= W_sig; -- Write signal, not used in this example
        -- decoded_reg_in(52) <= B_sig; -- Branch signal, not used in this example
        -- decoded_reg_in(53) <= J_sig; -- Jump signal, not used in this example
        rd_sel              <= decoded_reg_out(4 downto 0);
        rs1_sel             <= decoded_reg_out(9 downto 5);
        rs2_sel             <= decoded_reg_out(14 downto 10);
        op2_sel             <= decoded_reg_out(15);
        imm_sel             <= decoded_reg_out(17 downto 16);
        adder_sp_sel        <= decoded_reg_out(18);
        imm                 <= decoded_reg_out(38 downto 19);
        funct3              <= decoded_reg_out(41 downto 39);
        funct7              <= decoded_reg_out(48 downto 42); -- 7 bits
        AUIPC_or_branch_sel <= decoded_reg_out(49);
        R_sig               <= decoded_reg_out(50);
        W_sig               <= decoded_reg_out(51);
        B_sig               <= decoded_reg_out(52);
        J_sig               <= decoded_reg_out(53);
        regs_in_sel         <= decoded_reg_out(55 downto 54);

        
        PC_inst: reg
            generic map(
                w => 32,
                rising => true
            )
            port map(
                rst => rst,
                clk => clk,
                en => PC_wen, -- Enable the PC register
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
        -- buffer_reg_inst: reg
        --     generic map(
        --         w => 32,
        --         rising => true
        --     )
        --     port map(
        --         rst => rst,
        --         clk => clk,
        --         en => buffer_wen_sig, -- Enable the buffer register
        --         datain => r2,
        --         dataout => dataout
        --     );
        -- buffer_addr_reg_inst: reg
        --     generic map(
        --         w => 32,
        --         rising => true
        --     )
        --     port map(
        --         rst => rst,
        --         clk => clk,
        --         en => buffer_wen_sig, -- Enable the buffer address register
        --         datain => adder_res, 
        --         dataout => addrout
        --     );

        --TODO: SLICE DATAIN TO SUPPORT MISSALIGNED LOADS
        mem_datain_mux: MUX
            generic map(
                N => 3 -- 1 input for the MUX
            )
            port map(
                sel => funct3, -- Select signal for the MUX
                datain => mem_datain_mux_in, -- Placeholder for memory address output
                dataout =>  mem_regs_datain_sig-- Output not used in this example
            );
       
        --a process to control memory writing, special sequential element
        
        mem_byte_signext_inst: signext
            generic map(
                w => 8 -- Width of the byte to sign-extend
            )
            port map(
                imm => datain(7 downto 0),
                imm_extended => mem_datain_mux_in(0) -- Sign-extended output
            );
        mem_half_signext_inst: signext
            generic map(
                w => 16 -- Width of the half-word to sign-extend
            )
            port map(
                imm => datain(15 downto 0),
                imm_extended => mem_datain_mux_in(1) -- Sign-extended output
            );
        mem_datain_mux_in(2) <= datain; -- this is for LOAD WORD

        mem_byte_zeroext_inst: zeroext
            generic map(
                w => 8 -- Width of the byte to zero-extend
            )
            port map(
                imm => datain(7 downto 0),
                imm_extended => mem_datain_mux_in(4) -- Zero-extended output
            );
        mem_half_zeroext_inst: zeroext
            generic map(
                w => 16 -- Width of the half-word to zero-extend
            )
            port map(
                imm => datain(15 downto 0),
                imm_extended => mem_datain_mux_in(5) -- Zero-extended output
            );

        -- process(clk)
        -- begin
        --     if falling_edge(clk) then
        --         mem_wen <= buffer_wen_sig; -- Memory write enable signal
        --     end if;
        -- end process;
        process(PC_in_sig, adder_res, r2,R_sig ,W_sig, mem_wen_FSM)
            begin
            addrPC <= PC_in_sig; --we connect the combinatorial PC input so that we avoid race conditions, it is ready at the end of execture phase
            addrout <= adder_res; -- Connect the memory address output to the ALU adder result
            dataout <= r2; --TODO: Check this hardwiring
            RW_op <= R_sig or W_sig; -- Read/Write operation signal, set to '1' for write operations
            mem_wen <= mem_wen_FSM and W_sig; -- Memory write enable signal, controlled by FSM and write operation signal
        end process;
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