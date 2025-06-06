This is a README FILE, for now it will contain bugs and ideas

For GENERAL SYNTHEIS: vivado -mode batch -source run_project.tcl
For SINGLE FILE SYNTESIS: vivado -mode batch -source synth_single_file.tcl

ALU design desicions
    -all inputs are first sign extended then muxed for un/signed and imm
    -instr to ALU op corespondence
     LUI - ADD
AUIPC - ADD- PC involved
JAL - ADD
JALR -ADD
BEQ - ADD
BNE-ADd
BLT-ADd
BGE-ADd
BLTU-ADd
BGEU-ADd
LB-ADD
LH-ADD
LW-ADD
LBU-ADD
LHU-ADD
SB-ADD
SH-ADD
SW-ADD
ADDI-ADD
SLTI-CMP.
SLTIU-cmp
XORI-XOR
ORI-OR
ANDI-AND
SLLI-resp. shift
SRLI-resp. shift
SRAI-resp. shift
ADD-ADD
SUB-ADD
SLL-SLL
SLT-CMP.j
SLTU-cmp
XOR-XOR
SRL
SRA
OR
AND 
This is nice, we have exactly 8 ALU units
    -ADD
    -OR
    -AND
    -XOR
    -SLL
    -SRL
    -SRA
    -CMP, this has another type of output tho, i guess 3 lines if greater less or equal, this also needs to follow the unsigned bitthing 
We also need to consider LUI, which is just a passthrough, but we can implement that with ADD in the ALU and then x0 for one operand

For the op2 we have 4 options in total, also counting shamt which is a special case
    -rs2
    -unsigned imm12
    -signed imm12
    -unsigned imm20 which go into the upper bits
    -signed imm20 that makes
This makes 5 things that need to muxed, not ideal, so we just do one mux for register and then 4 for all other

Now the biggest problem are the branch instructions, they take 2 cycles to
    -one for condition check
    -another for the branching
Solutions:
    -actually do 2 cycles
    -do a separate increment circuit for the PC, add the other address with the adder in parallel, but that would require 3 inputs,
    

Potential optimisation, the unsigned part of imm_sel signal could AND-ed with the MSB of an immedate to produce the immediate