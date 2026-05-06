----------------------------------------------------------------------------------
-- Module : instruction_decoder
-- Project: Nanoprocessor (Lab 9-10, CS1050)
-- Role   : "Brain Surgeon" - the control unit of the 4-bit nanoprocessor
--
-- The decoder takes the 12-bit instruction fetched from Program ROM and a
-- 4-bit "register-check" value (the value of the register selected on
-- mux_a, used by JZR), and produces every control signal the datapath
-- needs in one combinational sweep.
--
-- Instruction format (Table 1 of the lab):
--   MOVI R,d   : 1 0 R R R 0 0 0 d d d d        opcode = 10
--   ADD  Ra,Rb : 0 0 Ra Ra Ra Rb Rb Rb 0 0 0 0  opcode = 00
--   NEG  R     : 0 1 R R R 0 0 0 0 0 0 0        opcode = 01
--   JZR  R,d   : 1 1 R R R 0 0 0 0 d d d        opcode = 11
--
-- All control outputs are derived from instruction(11..10) (opcode) plus
-- a few raw instruction bits, so the whole module is pure combinational
-- logic with NO process and NO latches.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity instruction_decoder is
    Port (
        -- ---- Inputs ----
        instruction   : in  STD_LOGIC_VECTOR (11 downto 0);  -- from Program ROM
        reg_check_val : in  STD_LOGIC_VECTOR (3 downto 0);   -- value on mux_a output (used by JZR)

        -- ---- Outputs to the datapath ----
        reg_en_sel    : out STD_LOGIC_VECTOR (2 downto 0);   -- target register address (3-to-8 dec input)
        reg_write_en  : out STD_LOGIC;                        -- master write-enable for register bank
        load_sel      : out STD_LOGIC;                        -- 2-way 4-bit data-bus mux: '1'=immediate, '0'=ALU
        imm_val       : out STD_LOGIC_VECTOR (3 downto 0);   -- immediate value for MOVI
        mux_a_sel     : out STD_LOGIC_VECTOR (2 downto 0);   -- 8-way 4-bit mux A select (ALU left input)
        mux_b_sel     : out STD_LOGIC_VECTOR (2 downto 0);   -- 8-way 4-bit mux B select (ALU right input)
        add_sub_sel   : out STD_LOGIC;                        -- ALU op: '0'=add, '1'=subtract
        jump_flag     : out STD_LOGIC;                        -- '1' => PC <- jump_addr, else PC <- PC+1
        jump_addr     : out STD_LOGIC_VECTOR (2 downto 0)    -- jump target (low 3 bits of d)
    );
end instruction_decoder;

architecture Dataflow of instruction_decoder is

    -- Convenient alias for the opcode
    alias  op1     : STD_LOGIC is instruction(11);
    alias  op0     : STD_LOGIC is instruction(10);

    -- One-hot decode of the four opcodes (cost: 4 AND2, 2 NOT)
    signal is_ADD  : STD_LOGIC;   -- opcode = 00
    signal is_NEG  : STD_LOGIC;   -- opcode = 01
    signal is_MOVI : STD_LOGIC;   -- opcode = 10
    signal is_JZR  : STD_LOGIC;   -- opcode = 11

    -- Zero detector for reg_check_val (cost: 1 NOR4)
    signal r_is_zero : STD_LOGIC;

begin

    ------------------------------------------------------------------
    -- 1) Opcode one-hot decode
    ------------------------------------------------------------------
    is_ADD  <= (not op1) and (not op0);   -- 00
    is_NEG  <= (not op1) and      op0;    -- 01
    is_MOVI <=      op1  and (not op0);   -- 10
    is_JZR  <=      op1  and      op0;    -- 11

    ------------------------------------------------------------------
    -- 2) Pass-through fields (these are PURE WIRES - 0 gates)
    --    For every writing instruction (MOVI/ADD/NEG) the destination
    --    register is encoded in I(9..7).  For JZR, reg_write_en=0 so
    --    the value of reg_en_sel is don't-care and we just pass I(9..7)
    --    on, saving the muxes.
    ------------------------------------------------------------------
    reg_en_sel <= instruction(9 downto 7);   -- destination register
    imm_val    <= instruction(3 downto 0);   -- d field for MOVI
    jump_addr  <= instruction(2 downto 0);   -- d field for JZR (low 3 bits)

    ------------------------------------------------------------------
    -- 3) Single-bit control signals
    ------------------------------------------------------------------

    -- Write-enable: HIGH for MOVI / ADD / NEG, LOW only for JZR.
    --   reg_write_en = NOT(is_JZR) = NOT(op1 AND op0) = NAND(op1,op0)
    -- Cost: 1 NAND2.
    reg_write_en <= not is_JZR;

    -- Data-bus mux: choose the immediate field on a MOVI, otherwise
    -- choose the ALU output.  Cost: same gate as is_MOVI (no extra cost).
    load_sel <= is_MOVI;

    -- ALU operation: subtract for NEG, otherwise add.
    -- For JZR we run an ADD (0 + R) so the ALU output equals R; this
    -- value isn't written, but the zero-check uses it harmlessly.
    -- Cost: same gate as is_NEG (no extra cost).
    add_sub_sel <= is_NEG;

    ------------------------------------------------------------------
    -- 4) ALU operand selects (8-way 4-bit mux A and mux B)
    --
    -- Truth table (X = don't care):
    --   Op    mux_a_sel       mux_b_sel       Why
    --   ADD   I(9..7) = Ra    I(6..4) = Rb    Ra + Rb
    --   NEG   "000"   = R0    I(9..7) = R     0 - R = -R   (R0 hardwired to 0)
    --   MOVI  X                X               write path goes through immediate, ALU result discarded
    --   JZR   I(9..7) = R     "000"  = R0     0 + R = R, then check zero
    --
    -- Optimisation:
    --   * For MOVI bits 6..4 are always "000" by the instruction format,
    --     so leaving mux_b_sel = I(6..4) on MOVI naturally gives "000".
    --   * For JZR bits 6..4 are also always "000" by the format, so the
    --     same wire delivers the desired R0 select on JZR for FREE.
    --   => mux_b_sel needs to be I(6..4) for ADD/MOVI/JZR and I(9..7) for NEG only.
    --      That is a single 2-way 3-bit mux controlled by is_NEG.
    --
    --   * For mux_a we need I(9..7) on every opcode EXCEPT NEG, where we
    --     need "000".  That is a 3-bit AND with the inverted is_NEG line.
    ------------------------------------------------------------------

    -- mux_a_sel = I(9..7) AND NOT(is_NEG)   (per bit)
    -- Cost: 3 AND2 + 1 NOT (the NOT is shared across all three bits).
    mux_a_sel(2) <= instruction(9) and (not is_NEG);
    mux_a_sel(1) <= instruction(8) and (not is_NEG);
    mux_a_sel(0) <= instruction(7) and (not is_NEG);

    -- mux_b_sel = is_NEG ? I(9..7) : I(6..4)
    -- Cost: 3 * (2 AND2 + 1 OR2) = 9 gates (NOT(is_NEG) shared with above).
    mux_b_sel(2) <= (instruction(9) and is_NEG) or (instruction(6) and (not is_NEG));
    mux_b_sel(1) <= (instruction(8) and is_NEG) or (instruction(5) and (not is_NEG));
    mux_b_sel(0) <= (instruction(7) and is_NEG) or (instruction(4) and (not is_NEG));

    ------------------------------------------------------------------
    -- 5) Jump logic
    --
    -- jump_flag = is_JZR AND (reg_check_val == 0000)
    -- The 4-bit zero detector is a single 4-input NOR.
    -- Final AND merges it with is_JZR.   Cost: 1 NOR4 + 1 AND2.
    ------------------------------------------------------------------
    r_is_zero <= not (reg_check_val(3) or reg_check_val(2)
                   or reg_check_val(1) or reg_check_val(0));

    jump_flag <= is_JZR and r_is_zero;

end Dataflow;