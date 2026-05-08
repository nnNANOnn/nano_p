----------------------------------------------------------------------------------
-- Module : Mux_8_to_1
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- Single-bit 8-to-1 multiplexer built from a 3-to-8 decoder.
--   * decoded(7..0) is the one-hot mask for S, gated by EN.
--   * Each data line is masked with its decoder bit, then OR-reduced.
--   * When EN = '0', decoded is all-zero, so Y = '0'.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Mux_8_1 is
    Port (
        S  : in  STD_LOGIC_VECTOR(2 downto 0);
        D  : in  STD_LOGIC_VECTOR(7 downto 0);
        EN : in  STD_LOGIC;
        Y  : out STD_LOGIC
    );
end Mux_8_1;

architecture Behavioral of Mux_8_1 is
    signal decoded : STD_LOGIC_VECTOR(7 downto 0);
    signal masked  : STD_LOGIC_VECTOR(7 downto 0);
begin

    dec : entity work.Decoder_3_to_8
        port map (I => S, EN => EN, Y => decoded);

    masked <= D and decoded;

    Y <= ((masked(0) or masked(1)) or (masked(2) or masked(3)))
      or ((masked(4) or masked(5)) or (masked(6) or masked(7)));

end Behavioral;
