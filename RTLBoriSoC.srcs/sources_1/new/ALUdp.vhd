library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.MUX_types.all; -- Import the MUX package
--use WORK.MUX; -- Import the MUX component
--use WORK.signext; -- Import the sign extension component
--use WORK.zeroext; -- Import the zero extension component
--use WORK.SLLf.all; -- Import the SLL component
--use WORK.SRAf.all; -- Import the SRA component
--use WORK.adder; -- Import the adder component
--use WORK.XORf.all; -- Import the XOR component
--use WORK.ANDf.all; -- Import the AND component
--use WORK.ORf.all; -- Import the OR component
--use WORK.LUIf.all; -- Import the LUI component
--now we have to support all sorts of instructions
--that means we need a lot of stuff man
--how do we handle immediates, and also how do we mux it all
--in this file we prepare, but that also means we need to have some in flags, for example has imm, or is unsigned
--so that means ALU will perform sign/zero extension, that makes sense

entity ALUdp is
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
        branch: in std_logic -- flag to indicate if to use the address from the ALU or the PC increment
    );
end entity;

architecture RTL of ALUdp is
    signal op1: std_logic_vector(31 downto 0);
    signal op2: std_logic_vector(31 downto 0);
    signal adder_op1: std_logic_vector(31 downto 0);
    signal adder_op2: std_logic_vector(31 downto 0);
    --signal adder_op_sp: std_logic(31 downto 0);
    --signal adder_imm_sp: std_logic(31 downto 0);

    signal imm_extended: std_logic_vector(31 downto 0);
    signal imm12_signed : std_logic_vector(31 downto 0); -- 12 bit signed immediate
    signal imm12_unsigned : std_logic_vector(31 downto 0); -- 12 bit unsigned immediate
    signal imm20_signed : std_logic_vector(31 downto 0); -- 20 bit signed immediate
    signal imm20_upper : std_logic_vector(31 downto 0); -- upper 20 bits of an unsigned immediate
        
    signal adder_res: std_logic_vector(31 downto 0); -- result of the adder, this is not used in this ALU, but might be useful later
    signal sll_res: std_logic_vector(31 downto 0); -- result of the SLL operation, this is not used in this ALU, but might be useful later
    signal srl_res: std_logic_vector(31 downto 0); -- result of the SRL operation, this is not used in this ALU, but might be useful later
    signal sra_res: std_logic_vector(31 downto 0); -- result of the SRA operation, this is not used in this ALU, but might be useful later
    signal xor_res: std_logic_vector(31 downto 0); -- result of the XOR operation, this is not used in this ALU, but might be useful later
    signal and_res: std_logic_vector(31 downto 0); -- result of the AND operation, this is not used in this ALU, but might be useful later
    signal or_res: std_logic_vector(31 downto 0); -- result of the OR operation, this is not used in this ALU, but might be useful later

    signal cmp_LT : std_logic;
    signal cmp_EQ : std_logic;
    signal cmp_GE : std_logic; --this should be assigned as not (less or equal)
    signal cmp_NE : std_logic; --also assigned, look at end of arch
    signal cmp_LTU : std_logic;
    signal cmp_GEU : std_logic;

    signal branch_ext: std_logic;


    component MUX is
    generic (
        N : natural -- 2 bits → 4 elements
       
    );
    port (
        sel     : in std_logic_vector(N-1 downto 0); -- N-bit select
        datain  : in vector_array(0 to 2**N - 1);
        dataout : out std_logic_vector(31 downto 0) --32 bit hardcoded because it might not recognize and syntehsize types well otherwise
    );
    end component;

    component MUX1 is
        generic (
            N : natural;  -- 2 bits → 4 elements
        );
        port (
            sel     : in std_logic_vector(N-1 downto 0); -- N-bit select
            datain  : in std_logic_vector(0 to 2**N-1);
            dataout : out std_logic --32 bit hardcoded because it might not recognize and syntehsize types well otherwise
        );
    end component;

    component signext is
        generic (
            w: integer --should be specified later
        );
        port (
            imm : in std_logic_vector(w-1 downto 0); -- immediate input
            imm_extended : out std_logic_vector(31 downto 0) -- signed extended output
        );
    end component;
    
   component zeroext is
        generic (
            w: integer -- should be specified later
        );
        port (
            imm : in std_logic_vector(w-1 downto 0); -- w-bit immediate input
            imm_extended : out std_logic_vector(31 downto 0) -- 32-bit zero-extended output
        );
    end component;

    component SLLf is
        port (
            a : in std_logic_vector(31 downto 0);
            shamt : in std_logic_vector(4 downto 0);
            outp : out std_logic_vector(31 downto 0)
        );
    end component;

    component SRAf is
        port (
            a : in std_logic_vector(31 downto 0);
            shamt : in std_logic_vector(4 downto 0);
            outp : out std_logic_vector(31 downto 0)
        );
    end component; 

    component SRLf is
        port (
            a : in std_logic_vector(31 downto 0);
            shamt : in std_logic_vector(4 downto 0);
            outp : out std_logic_vector(31 downto 0)
        );
    end component;

    component XORf is
        port (
            a : in std_logic_vector(31 downto 0);
            b : in std_logic_vector(31 downto 0);
            outp : out std_logic_vector(31 downto 0)
        );
    end component;

    component ANDf is
        port (
            a : in std_logic_vector(31 downto 0);
            b : in std_logic_vector(31 downto 0);
            outp : out std_logic_vector(31 downto 0)
        );
    end component;

    component ORf is
        port (
            a : in std_logic_vector(31 downto 0);
            b : in std_logic_vector(31 downto 0);
            outp : out std_logic_vector(31 downto 0)
        );
    end component;




   component adder is
        port (
            a : in std_logic_vector(31 downto 0);
            b : in std_logic_vector(31 downto 0);
            sum : out std_logic_vector(31 downto 0);
            subtr : in std_logic -- flag to indicate addition or subtraction
        );
    end component;

    
    component cmp is
        port(
            a : in std_logic_vector(31 downto 0),
            b : in std_logic_vector(31 downto 0),
            EQ : out std_logic;
            LT : out std_logic;
        );
    end component;


    component cmpU is
        port(
            a : in std_logic_vector(31 downto 0),
            b : in std_logic_vector(31 downto 0),
            LTU : out std_logic;
        );
    end component;

    begin

    mux_res: MUX
        generic map (
            N => 3 -- 3 bits → 8 elements
        )
        port map (
            sel => op(2 downto 0), -- 3-bit select for the operation
            --the idea is for 010 SLT and 011 SLTU should go to two different comparisons, but in the end they do have something that makes sense
            --OP type : ADD         SLL     SLT         SLTU        XOR         SRL     SRA     OR      AND this is 1 to 1 with the funct3, one less lut
            --OPIMMSAME
            --BRANCH   BEQ BNE BLT BGE BLTU BGEU
            datain => (adder_res , sll_res, branch_ext ,branch_ext ,xor_res, srl_res, sra_res, or_res, and_res), --TODO: CHECK THE ORDER, also the last value is for SLT/U
            dataout => result -- output to op1
        );
    
    --00 12 bit signed
    --01 23 bit unsigned
    --10 20 bit signed
    --11 upper 20 bit unsigned, an implicit shift that needs to be done before the actuall ALU for speed
    mux_imm : MUX
        generic map (
            N => 2
        )
        port map (
            sel => imm_sel, -- if unsigned_flag is set, select r2, else select r1
            datain => (imm12_signed, imm12_unsigned, imm20_signed, imm20_upper), --TODO: CHECK THE ORDER
            dataout => imm_extended
        );
    
    signext12_inst : signext
        generic map (
            w => 12 -- 12-bit immediate
        )
        port map (
            imm => imm(11 downto 0), -- take the lower 12 bits for sign extension
            imm_extended => imm12_signed -- output to op1
        );
    signext20_inst : signext
        generic map (
            w => 20 -- 20-bit immediate
        )
        port map (
            imm => imm(19 downto 0), -- take the lower 20 bits for sign extension
            imm_extended => imm20_signed -- output to op1
        );
    
    zeroext12_inst : zeroext
        generic map (
            w => 12 -- 12-bit immediate
        )
        port map (
            imm => imm(11 downto 0), -- take the lower 12 bits for zero extension
            imm_extended => imm12_unsigned -- output to op1
        );

    zeroextbranch_inst : zeroext
        generic map(
            w => 1
        );
        port map (
            imm => branch,
            imm_extended => branch_ext
        );
    
    

    --This is an integerated process for zero extending the upper 20 bits of the immediate, wasn't worth it m
    process(imm) is
    
    begin
        -- Zero extend the 20-bit immediate to 32 bits
        imm20_upper <= imm(19 downto 0) & X"000"; --TODO: Check for order
    end process;
    

    --this mux chooses between regular and and speical adder op-s 
    adder_op_sp_mux_inst: MUX
        generic map (
            N := 1

        );
        port map(
            sel => adder_sp_sel,
            datain => (op1, adder_op_sp),
            dataout => adder_op1;
        );

    adder_imm_sp_inst: MUX
        generic map (
            N := 1

        );
        port map(
            sel => adder_sp_sel,
            datain => (op2, adder_imm_sp),
            dataout => adder_op2;
        );
    

    
    adder_inst : adder
        port map (
            a => adder_op1,
            b => adder_op2,
            sum => adder_res, 
            subtr => subtr --fill this signal
        );
    
    cmp_inst: cmp
        port map (
            a => op1,
            b => op2,
            EQ => cmp_EQ,
            LT => cmp_LT
        );    
    
    cmpU_inst: cmp
        port map (
            a => op1,
            b => op2,
            LTU => cmp_LTU
        ); 
    
    branch_mux: MUX1 --this is also used for SLT[U]
        generic map( 
            N:=3
        );
        port map(
            sel => funct3,
            datain => (cmp_EQ,cmp_NE,cmp_LT,cmp_LTU,,cmp_LT,cmp_GE,cmp_LTU,cmp_BGEU), -- WARNING: This implentation makes it impossible to track bugs with branch and SLT[U]
            dataout => branch
        );



   

    SLLf_inst: SLLf
        port map (
            a => op1,
            shamt => op2(4 downto 0), -- assuming r2 contains the shift amount
            outp => sll_res
        );
    
    SRAf_inst: SRAf
        port map (
            a => op1,
            shamt => op2(4 downto 0), -- assuming r2 contains the shift amount
            outp => sra_res
        );
    
    SRLf_inst: SLLf -- SRL is just a left shift with the bits filled with 0
        port map (
            a => op1,
            shamt => op2(4 downto 0), -- assuming r2 contains the shift amount
            outp => srl_res
        );
    
    XORf_inst: XORf
        port map (
            a => op1,
            b => op2,
            outp => xor_res
        );
    ANDf_inst: ANDf
        port map (
            a => op1,
            b => op2,
            outp => and_res
        );
    ORf_inst: ORf
        port map (
            a => op1,
            b => op2,
            outp => or_res
        );
    
    
    cmp_GE <= not(cmp_EQ or cmp_LT);
    cmp_NE <= not cmp_EQ;
    cmp_GEU <= not(cmp_EQ or cmp_LTU);
            

end architecture RTL;