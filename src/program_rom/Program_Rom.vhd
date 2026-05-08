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

    -- ---- Custom assembly program from image ----
    --
    --  addr  asm              machine code (binary)         comment
    --   0    MOVI R1, 10      10 001 000 1010               R1 <- 10
    --   1    MOVI R2, 1       10 010 000 0001               R2 <- 1
    --   2    NEG  R2          01 010 000 0000               R2 <- -R2
    --   3    ADD  R1, R2      00 001 010 0000               R1 <- R1 + R2
    --   4    JZR  R1, 7       11 001 000 0111               If R1 = 0 jump to line 7
    --   5    JZR  R0, 3       11 000 000 0011               If R0 = 0 jump to line 3 (Loop back)
    --   6    JZR  R0, 6       11 000 000 0110               Safety halt
    --   7    JZR  R0, 7       11 000 000 0111               Halt (Loop to self)
    --
    constant ROM_CONTENTS : rom_type := (
        0 => "100010001010",   -- MOVI R1, 10
        1 => "100100000001",   -- MOVI R2, 1
        2 => "010100000000",   -- NEG  R2
        3 => "000010100000",   -- ADD  R1, R2
        4 => "110010000111",   -- JZR  R1, 7
        5 => "110000000011",   -- JZR  R0, 3
        6 => "110000000110",   -- JZR  R0, 6   
        7 => "110000000111"    -- JZR  R0, 7   
    );

begin

    -- Combinational read: present the instruction at the current PC.
    I <= ROM_CONTENTS(to_integer(unsigned(ROM_address)));

end Behavioral;