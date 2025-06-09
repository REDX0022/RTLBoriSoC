library WORK;
use WORK.def_pack.all; 
use WORK.init_pack.all;
use WORK.IO_pack.all;
use WORK.mnemonic_pack.all;
use WORK.mem_pack.all;
use WORK.mem_pack.all;
use WORK.MUX_types.all;

library STD;
use STD.TEXTIO.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity testbench is

end entity;

architecture TB of testbench is

    constant trace_header: string := "OP    |RD|RS1 |IMM  | PC |   x0   |   x1   |   x2   |   x3   |   x4   |   x5   |   x6   |   x7   |   x8   |   x9   | x10   |   x11  |  x12   |   x13   |  x14   |   x15  |   x16  |   x17  |   x18  |   x19  |  x20   |   x21  |   x22  |   x23  |   x24  |   x25  |   x26  |   x27  |   x28  |   x29  |   x30  |   x31  |";
                               --     ADDI   x1 x0 001 @ 0000 00000000 00000001 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 
    
    signal mem_tb_in: ram_type;
    signal mem_tb_out: ram_type;
    signal instr_trace: instr_type;
    signal instr_trace_slv: std_logic_vector(31 downto 0);
    signal PC_trace: pc_type;
    signal PC_trace_slv: std_logic_vector(31 downto 0);
    signal regs_trace: regs_type;
    signal regs_trace_slv: vector_array(0 to 31);

   
    signal sim_init: bit := '0';

    signal mem_temp: mem_type;

    signal rst: std_logic := '1'; -- Reset signal
    signal clk: std_logic := '0'; -- Clock signal

    signal mem_init_SOC: std_logic := '0'; -- Memory initialization signal for SoC

    signal sim_dump_en: std_logic := '0'; -- Enable memory dump for simulation
    
    

    

    file trace_f : text open write_mode is trace_path;
    file dump_f  : text open write_mode is dump_path;
        component SOC is
            generic (
                SIMULATION : boolean := false
            );
            port (
                clk      : in std_logic := '0';  -- Clock signal
                rst      : in std_logic := '0'  -- Reset signal
                -- synthesis translate_off
                ;
                sim_init : in std_logic;     -- Simulation initialization signal
                sim_instr : out std_logic_vector(31 downto 0); -- Simulation instruction trace output
                sim_dump_en : in std_logic; -- Enable memory dump for simulation
                reg_sim  : out vector_array(0 to 31); -- Simulation interface for registers
                PC_sim  : out std_logic_vector(31 downto 0) -- Simulation output for PC
                -- synthesis translate_on
            );
        end component;
    begin
        

        UUT: SOC
        generic map (
            SIMULATION => true
        )
        port map (
            clk      => clk,
            rst      => rst,
            sim_init => mem_init_SOC, -- Simulation initialization signal
            sim_instr => instr_trace_slv, -- Simulation instruction trace output
            sim_dump_en => sim_dump_en, -- Enable memory dump for simulation
            reg_sim => regs_trace_slv, -- Simulation interface for registers
            PC_sim => PC_trace_slv -- Simulation output for PC
        );

        process 
        variable l:line;
        variable last_cycle_end : bit := '0'; --Might be depracated
        
        variable code: opcode_type;
        variable rd: reg_addr_type;
        variable rs1: reg_addr_type;
        variable rs2: reg_addr_type;
        variable funct3: funct3_type;
        variable funct7: funct7_type;
        variable imm110: bit_vector(11 downto 0); 
        variable imm115: bit_vector(6 downto 0);
        variable imm40: bit_vector(4 downto 0);
        variable imm40_I: bit_vector(4 downto 0);
        variable imm12: bit;
        variable imm105: bit_vector(5 downto 0);
        variable imm41: bit_vector(3 downto 0);
        variable imm11_B: bit;
        variable imm3112: bit_vector(19 downto 0);
        variable imm20: bit;
        variable imm101: bit_vector(9 downto 0);
        variable imm11J: bit;
        variable imm1912: bit_vector(7 downto 0);
        variable instrm: mnemonic_type;
        begin
            -- Initialize memory and SoC
            -- synthesis translate_off
            report "Initializing memory and SoC";
            
            --synthesis translate_on
            mem_init_SOC <= '1'; -- Set memory initialization signal
            rst <= '1';
            wait for 10 ns; -- Wait for reset to stabilize
            --mem_temp <= init_mem;
            --wait for 10 ns; -- Wait for memory initialization
            --mem_tb_out <= mem_to_ram(mem_temp); --in the def pack we need to convert the mem_type to ram_type
            --wait for 10 ns;
            mem_init_SOC <= '0'; -- Clear memory initialization signal
            rst <= '0'; -- Release reset
            wait for 10 ns;
            -- synthesis translate_off
            report "Memory and SoC initialized, SoC started"; 
            --synthesis translate_on
            -- Start the first instruction
            --Make the trace look nice
            write(l, trace_header);
            writeline(trace_f, l);
            test_loop: loop
                --Implement clock for HERE and start rising and falling edge
                clk <= '1';
                wait for 5 ns; -- Clock high time
                clk <= '0';
                wait for 5 ns; -- Clock low time
                --CPU done
                
                wait for 0 ns;
                wait for 0 ns;
                wait for 0 ns;
                wait for 0 ns;
                wait for 0 ns;
                wait for 0 ns;
                instr_trace <= to_bitvector(instr_trace_slv);
                regs_trace <= vector_array_to_regs(regs_trace_slv); 
                PC_trace <= slice_msb(to_bitvector(PC_trace_slv)(15 downto 0)+X"FFFC"); --PC is taken at the wrong time so we adjust it
                wait for 0 ns;
                wait for 0 ns;
                wait for 0 ns;
                wait for 0 ns;
                wait for 0 ns;
                wait for 0 ns;
                report "Instruction fetched: " & bitvec_to_bitstring(instr_trace);
                
                -- Now do your trace/logging
                code    := instr_trace(6 downto 0);
                rd      := instr_trace(11 downto 7);
                rs1     := instr_trace(19 downto 15);
                rs2     := instr_trace(24 downto 20);
                funct3  := instr_trace(14 downto 12);
                funct7  := instr_trace(31 downto 25);
                imm110  := instr_trace(31 downto 20);
                imm115  := instr_trace(31 downto 25);
                imm40   := instr_trace(11 downto 7);
                imm40_I := instr_trace(24  downto 20); --TODO: check the imm
                imm12   := instr_trace(31);
                imm105  := instr_trace(30 downto 25);
                imm41   := instr_trace(11 downto 8);
                imm11_B  := instr_trace(7);  -- exception naming
                imm3112 := instr_trace(31 downto 12);
                imm20   := instr_trace(31);
                imm101  := instr_trace(30 downto 21);
                imm11J  := instr_trace(20); -- exception naming
                imm1912 := instr_trace(19 downto 12);
                case code is
                    when OP =>
                        case funct3 is
                            when ADDf3 =>
                                case funct7 is
                                    when ADDf7 =>
                                        instrm := ADDm;
                                        -- Handle ADD instructions here
                                    when SUBf7 =>
                                        instrm := SUBm;
                                        -- Handle SUB instructions here
                                    when others =>
                                        --report "Unknown funct7 for ADD: " & bitvec_to_bitstring(instr_trace);
                                        exit test_loop; -- Exit the loop on unknown funct7

                                end case;
                                -- Handle ADD instructions here
                                
                            when SLTf3 =>
                                instrm := SLTm;
                                -- Handle SLT instructions here
                            when SLTUf3 =>
                                instrm := SLTUm;
                                -- Handle SLTU instructions here
                            when ANDf3 =>
                                instrm := ANDm;
                                -- Handle AND instructions here
                            when ORf3 =>
                                instrm := ORm;
                                -- Handle OR instructions here
                            when XORf3 =>
                                instrm := XORm;
                                -- Handle XOR instructions here
                            when SLLf3 =>
                                instrm := SLLm;
                                -- Handle SLL instructions here
                            when SRL_Af3 =>
                                if(instr_trace(30) = '1') then
                                    instrm := SRAm;
                                else 
                                    instrm := SRLm; 
                                    -- Handle SRL instructions here
                                end if;
                            when others =>
                                    ----report "Unknown funct3 for OP instruction fetched: " & bitvec_to_bitstring(instr_trace);
                                    exit test_loop; -- Exit the loop on unknown funct3
                        end case;
                        trace_R(instrm, rd, rs1, rs2, PC_trace, regs_trace, trace_f);

                    when OPIMM =>
                    case funct3 is
                        when ADDf3 =>
                                instrm := ADDIm;
                                -- Handle ADD instructions here
                            
                            when SLTf3 =>
                                instrm := SLTIm;
                                -- Handle SLTI instructions here
                            when SLTUf3 =>
                                instrm := SLTIUm;
                                -- Handle SLTIU instructions here
                            when ANDf3 =>
                                instrm := ANDIm;
                                -- Handle ANDI instructions here
                            when ORf3 =>
                                instrm := ORIm;
                                -- Handle ORI instructions here
                            when XORf3 =>
                                instrm := XORIm;
                                -- Handle XORI instructions here
                            when SLLf3 =>
                                instrm := SLLIm;
                                -- Handle SLLI instructions here
                            when SRL_Af3 =>
                                if(instr_trace(30) = '1') then
                                    instrm := SRAIm;
                                    imm110(10) := '0'; --make the immediate accurate since SRAI is alradin in the mnemonic
                                    --TODO: Better solution for line above
                                    -- Handle SRAI instructions here
                                else
                                    instrm := SRLIm; 
                                    -- Handle SRLI instructions here
                                end if;
                                
                                -- Handle SRLI instructions here
                            when others =>
                                report "Unknown OPIMM instruction fetched: " & bitvec_to_bitstring(instr_trace);
                                exit test_loop; -- Exit the loop on unknown funct3
                        -- Handle OPIMM instructions here
                        end case;
                        trace_I(instrm, rd, rs1, imm110, PC_trace,regs_trace,trace_f);
                    when LUI =>
                        ----report "LUI instruction fetched: " & bitvec_to_bitstring(instr_trace);
                        instrm := LUIm;
                        trace_U(instrm, rd, imm3112, PC_trace, regs_trace, trace_f);
                        -- Handle LUI instructions here
                    when AUIPC =>
                        ----report "AUIPC instruction fetched: " & bitvec_to_bitstring(instr_trace);
                        -- Handle AUIPC instructions here
                        instrm := AUIPCm;
                        trace_U(instrm, rd, imm3112, PC_trace, regs_trace, trace_f);
                    when JAL =>
                        ----report "JAL instruction fetched: " & bitvec_to_bitstring(instr_trace);
                        -- Handle JAL instructions here
                        instrm := JALm;
                        trace_U(instrm, rd, imm3112, PC_trace, regs_trace, trace_f); --this should be fine
                    when JALR =>
                        ----report "JALR instruction fetched: " & bitvec_to_bitstring(instr_trace);
                        -- Handle JALR instructions here
                        instrm := JALRm;
                        trace_I(instrm, rd, rs1, imm110, PC_trace, regs_trace, trace_f);
                    when BRANCH =>
                        case funct3 is
                            when BEQf3 =>
                                instrm := BEQm;
                                -- Handle BEQ instructions here
                            when BNEf3 =>
                                instrm := BNEm;
                                -- Hanle BNE instructions here
                            when BLTf3 =>
                                instrm := BLTm;
                                -- Handle BLT instructions here
                            when BGEf3 =>
                                instrm := BGEm;
                                -- Handle BGE instructions here
                            when BLTUf3 =>
                                instrm := BLTUm;
                                -- Handle BLTU instructions here
                            when BGEUf3 =>
                                instrm := BGEUm;
                                -- Handle BGEU instructions here
                            when others =>
                                report "Unknown funct3 for BRANCH instruction fetched: " & bitvec_to_bitstring(instr_trace);
                                exit test_loop; -- Exit the loop on unknown funct3
                        end case;
                        --report "VISIBLE";
                        --report "imm41: " & bitvec_to_bitstring(imm41);
                        trace_B(instrm,imm11_B,imm41, rs1, rs2,imm105,imm12 , PC_trace, regs_trace, trace_f);    
                    when LOAD =>
                        case funct3 is
                            when LBf3 =>
                                instrm := LBm;
                                -- Handle LB instructions here
                            when LBUf3 =>
                                instrm := LBUM;
                                -- Handle LBU instructions here
                            when LHf3 =>
                                instrm := LHm;
                                -- Handle LH instructions here
                            when LHUf3 =>
                                instrm := LHUIm;
                                -- Handle LHU instructions here
                            when LWf3 =>
                                instrm := LWm;
                                -- Handle LW instructions here
                            when others =>
                                report "Unknown funct3 for LOAD instruction fetched: " & bitvec_to_bitstring(instr_trace);
                                exit test_loop; -- Exit the loop on unknown funct3
                        end case;
                        trace_I(instrm, rd, rs1, imm110, PC_trace, regs_trace, trace_f);
                    when STORE =>
                        case funct3 is
                            when SBf3 =>
                                instrm := SBm;
                                -- Handle SB instructions here
                            when SHf3 =>
                                instrm := SHm;
                                -- Handle SH instructions here
                            when SWf3 =>
                                instrm := SWm;
                                -- Handle SW instructions here
                            when others =>
                                report "Unknown funct3 for STORE instruction fetched: " & bitvec_to_bitstring(instr_trace);
                                exit test_loop; -- Exit the loop on unknown funct3
                        end case;
                        trace_S(instrm,imm40, rs1, rs2, imm115, PC_trace, regs_trace, trace_f);                
                    when others =>
                        report "Unknown instruction fetched, exiting testbench: " & bitvec_to_bitstring(instr_trace);
                        exit test_loop; -- Exit the loop on unknown instruction
                    
                end case;
                report "Trace done";

                -- Trigger SoC to execute next instruction
               
            end loop;
            sim_dump_en <= '1';
            wait for 10 ns;

            --dump_memory(dump_path, ram_to_mem(mem_tb_in));
            file_close(trace_f);
            file_close(dump_f);            
            report "Testbench completed.";
            wait;
        end process;

end architecture;