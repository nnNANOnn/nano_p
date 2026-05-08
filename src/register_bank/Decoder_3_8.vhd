----------------------------------------------------------------------------------
-- Module : Decoder_3_8
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- 3-to-8 one-hot decoder with active-high enable, built hierarchically
-- from two Decoder_2_to_4 instances:
--   * I(2) selects which half is enabled.
--   * I(1..0) addresses within the chosen half.
--   * EN gates the whole structure -- when EN='0', Y = "00000000".
--
-- This last property is what the register bank's master Write_En relies
-- on: with Write_En = '0' the 3-to-8 decoder asserts no register's En
-- line, so no register can latch (used by JZR).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Decoder_3_8 is
    Port (
        I  : in  STD_LOGIC_VECTOR(2 downto 0);
        EN : in  STD_LOGIC;
        Y  : out STD_LOGIC_VECTOR(7 downto 0)
    );
end Decoder_3_8;

architecture Behavioral of Decoder_3_8 is
    signal Y_lo, Y_hi : STD_LOGIC_VECTOR(3 downto 0);
    signal EN_lo, EN_hi : STD_LOGIC;
begin

    EN_lo <= (not I(2)) and EN;
    EN_hi <=      I(2)  and EN;

    dec_lo : entity work.Decoder_2_to_4
        port map (I => I(1 downto 0), EN => EN_lo, Y => Y_lo);

    dec_hi : entity work.Decoder_2_to_4
        port map (I => I(1 downto 0), EN => EN_hi, Y => Y_hi);

    Y(3 downto 0) <= Y_lo;
    Y(7 downto 4) <= Y_hi;

end Behavioral;
