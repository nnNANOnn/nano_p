----------------------------------------------------------------------------------
-- Module : Add_Sub_4_bit
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- 4-bit two's-complement add/subtract unit built around RCA_4.
--   CTRL = '0' -> S = A + B
--   CTRL = '1' -> S = A - B    (B is XOR-inverted and C_in is forced to 1)
--
-- Flags:
--   Zero     : asserted when the 4-bit result is "0000"
--   OverFlow : signed overflow detector (XOR of carry-into-MSB and carry-out)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.adders.all;

entity Add_Sub_4_bit is
    Port (
        A_AS     : in  STD_LOGIC_VECTOR(3 downto 0);
        B_AS     : in  STD_LOGIC_VECTOR(3 downto 0);
        CTRL     : in  STD_LOGIC;                       -- '0'=add, '1'=subtract
        S_AS     : out STD_LOGIC_VECTOR(3 downto 0);
        Zero     : out STD_LOGIC;
        OverFlow : out STD_LOGIC
    );
end Add_Sub_4_bit;

architecture Behavioral of Add_Sub_4_bit is

    signal B_inter        : STD_LOGIC_VECTOR(3 downto 0);
    signal S_inter        : STD_LOGIC_VECTOR(3 downto 0);
    signal C_out_final    : STD_LOGIC;
    signal C_in_last_bit  : STD_LOGIC;

begin

    -- Conditional invert of B: when subtracting, B becomes ~B and CTRL feeds
    -- in as the LSB carry, so A + ~B + 1 = A - B.
    B_inter <= B_AS xor (CTRL & CTRL & CTRL & CTRL);

    RCA_4_0 : RCA_4
        port map (
            A         => A_AS,
            B         => B_inter,
            C_in      => CTRL,
            S         => S_inter,
            C_out     => C_out_final,
            C_in_last => C_in_last_bit
        );

    -- Signed-overflow flag: set when carry into and out of the MSB differ.
    OverFlow <= C_in_last_bit xor C_out_final;

    -- Zero flag: high when every result bit is zero.
    Zero <= '1' when S_inter = "0000" else '0';

    S_AS <= S_inter;

end Behavioral;
