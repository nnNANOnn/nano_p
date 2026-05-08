----------------------------------------------------------------------------------
-- Module : Program_ROM
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- 8 x 12-bit instruction memory.  The 3-bit Program Counter selects one
-- of 8 hard-coded machine words and presents it on the Instruction Bus
-- I(11..0).
--
-- Instruction encoding (Table 1 of the lab):
--   MOVI R, d   : 1 0 R R R 0 0 0 d d d d        (opcode = 10)
--   ADD  Ra, Rb : 0 0 Ra Ra Ra Rb Rb Rb 0 0 0 0  (opcode = 00)
--   NEG  R      : 0 1 R R R 0 0 0 0 0 0 0        (opcode = 01)
--   JZR  R, d   : 1 1 R R R 0 0 0 0 d d d        (opcode = 11)
--
-- Program (Step 4 of the lab): compute 1 + 2 + 3 and leave the result
-- in R7.  Trace -- see docs/program_rom.md for the cycle-by-cycle proof.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.buses.all;

entity Program_ROM is
    Port (
        ROM_address : in  instruction_address;   -- 3-bit PC value (0..7)
        I           : out instruction_bus        -- 12-bit instruction word
    );
end Program_ROM;

architecture Behavioral of Program_ROM is

    type rom_type is array (0 to 7) of STD_LOGIC_VECTOR(11 downto 0);

    -- ---- Step-4 assembly program: sum 1..3 -> R7 ----
    --
    --  addr  asm              machine code (binary)         comment
    --   0    MOVI R7, 0       10 111 000 0000               sum := 0
    --   1    MOVI R1, 3       10 001 000 0011               ctr := 3
    --   2    MOVI R2, 1       10 010 000 0001               tmp := 1
    --   3    NEG  R2          01 010 000 0000               tmp := -1
    --   4    ADD  R7, R1      00 111 001 0000               sum += ctr
    --   5    ADD  R1, R2      00 001 010 0000               ctr -= 1
    --   6    JZR  R1, 6       11 001 000 0110               if ctr=0 halt
    --   7    JZR  R0, 4       11 000 000 0100               unconditional jump to 4
    --
    constant ROM_CONTENTS : rom_type := (
        0 => "101110000000",   -- MOVI R7, 0
        1 => "100010000011",   -- MOVI R1, 3
        2 => "100100000001",   -- MOVI R2, 1
        3 => "010100000000",   -- NEG  R2
        4 => "001110010000",   -- ADD  R7, R1
        5 => "000010100000",   -- ADD  R1, R2
        6 => "110010000110",   -- JZR  R1, 6   (halt: jump to self if R1=0)
        7 => "110000000100"    -- JZR  R0, 4   (R0=0 always -> unconditional)
    );

begin

    -- Combinational read: present the instruction at the current PC.
    I <= ROM_CONTENTS(to_integer(unsigned(ROM_address)));

end Behavioral;
