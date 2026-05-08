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

-- ---- Custom assembly program: Straight-line sum 1+2+3 -> R7 ----
    --
    --  addr  asm              machine code (binary)         comment
    --   0    MOVI R7, 1       10 111 000 0001               R7 <- 1
    --   1    MOVI R5, 2       10 101 000 0010               R5 <- 2
    --   2    MOVI R4, 3       10 100 000 0011               R4 <- 3
    --   3    ADD  R7, R5      00 111 101 0000               R7 <- R7 + R5 (R7 becomes 3)
    --   4    ADD  R7, R4      00 111 100 0000               R7 <- R7 + R4 (R7 becomes 6)
    --   5    JZR  R0, 5       11 000 000 0101               Halt (jump to self)
    --   6    JZR  R0, 6       11 000 000 0110               Safety halt
    --   7    JZR  R0, 7       11 000 000 0111               Safety halt
    --
constant ROM_CONTENTS : rom_type := (
        0 => "101110000001",   -- MOVI R7, 1
        1 => "101010000010",   -- MOVI R5, 2
        2 => "101000000011",   -- MOVI R4, 3
        3 => "001111010000",   -- ADD  R7, R5
        4 => "001111000000",   -- ADD  R7, R4
        5 => "110000000101",   -- JZR  R0, 5  (Halt execution here)
        6 => "110000000110",   -- JZR  R0, 6   
        7 => "110000000111"    -- JZR  R0, 7   
    );

begin

    -- Combinational read: present the instruction at the current PC.
    I <= ROM_CONTENTS(to_integer(unsigned(ROM_address)));

end Behavioral;