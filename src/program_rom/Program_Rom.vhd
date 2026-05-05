library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.buses.all;

-- Program ROM — 16 x 12-bit read-only memory
-- Holds the fixed instruction sequence fetched by the PC each clock cycle.
-- Address width: 4 bits  → 16 locations  (0x0 .. 0xF)
-- Data    width: 12 bits → one instruction word per address
--
-- Instruction encoding (from instruction decoder):
--   [11:9] opcode  [8:6] Rd  [5:3] Ra  [2:0] immediate / Rb
--
-- Current program: adds integers 1 to 3, then halts.
-- Addresses 8-15 are reserved for the Multiplication extension.

entity Program_ROM is
    Port (
        ROM_address : in  std_logic_vector(3 downto 0); -- 4-bit PC address (16 locations)
        I           : out instruction_bus               -- 12-bit instruction out
    );
end Program_ROM;

architecture Behavioral of Program_ROM is

    -- Define a 16-entry ROM type, each entry 12 bits wide
    type rom_type is array (0 to 15) of std_logic_vector(11 downto 0);

    -- ── Instruction memory contents ──────────────────────────────────
    -- Encoding: [11:9]=opcode  [8:6]=Rd  [5:3]=Ra  [2:0]=imm/Rb
    --
    --  Opcode table (3 bits):
    --    000 = ADD Rd, Ra
    --    001 = NEG Rd          (two's complement negate)
    --    010 = NEG Rd
    --    011 = (reserved)
    --    100 = MOVI Rd, imm    (load 3-bit immediate)
    --    101 = MOVI Rd, imm
    --    110 = JZR Ra, imm     (jump if zero)
    --    111 = (reserved / MUL for extra credit)
    -- ─────────────────────────────────────────────────────────────────
    constant ROM_CONTENTS : rom_type := (
        -- ── Core program: add 1+2+3 → result in R7 ──────────────────
        0  => "101110000011",  -- MOVI R7, 3   : R7 = 3 (loop counter)
        1  => "100010000001",  -- MOVI R1, 1   : R1 = 1
        2  => "010010000000",  -- NEG  R1       : R1 = -R1 (make it negative for subtraction loop)
        3  => "100100000011",  -- MOVI R2, 3   : R2 = 3
        4  => "000100010000",  -- ADD  R2, R1  : R2 = R2 + R1
        5  => "001110100000",  -- ADD  R7, R2  : R7 = R7 + R2  (accumulate)
        6  => "110100000110",  -- JZR  R2, 6   : if R2==0 jump to addr 6 (halt here)
        7  => "110000000100",  -- JZR  R0, 4   : R0 is always 0 → unconditional jump to addr 4

        -- ── Reserved: Multiplication extension (extra credit) ────────
        -- MUL algorithm: repeated addition
        --   R3 = multiplicand, R4 = multiplier (loop counter), R5 = product accumulator
        8  => "000000000000",  -- NOP / placeholder — MUL entry point
        9  => "000000000000",  -- NOP / placeholder
        10 => "000000000000",  -- NOP / placeholder
        11 => "000000000000",  -- NOP / placeholder
        12 => "000000000000",  -- NOP / placeholder
        13 => "000000000000",  -- NOP / placeholder
        14 => "000000000000",  -- NOP / placeholder
        15 => "000000000000"   -- NOP / placeholder
    );

begin

    -- Combinational read: output the instruction at the given address
    I <= ROM_CONTENTS(to_integer(unsigned(ROM_address)));

end Behavioral;
