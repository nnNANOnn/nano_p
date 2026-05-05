library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 8-to-1 single-bit multiplexer
-- Uses a 3-to-8 decoder internally: the selected data line is ANDed
-- with its decoder output, then all 8 results are OR-reduced to Y.
entity Mux_8_to_1 is
    Port (
        S  : in  std_logic_vector(2 downto 0); -- 3-bit select (chooses 1 of 8)
        D  : in  std_logic_vector(7 downto 0); -- 8 single-bit data inputs
        EN : in  std_logic;                     -- active-high enable
        Y  : out std_logic                      -- selected data bit
    );
end Mux_8_to_1;

architecture Behavioral of Mux_8_to_1 is

    signal decoded : std_logic_vector(7 downto 0); -- one-hot decoder output
    signal masked  : std_logic_vector(7 downto 0); -- D AND decoded

begin

    -- Instantiate the 3-to-8 decoder that already lives in src/register_bank/
    dec : entity work.Decoder_3_to_8
        port map (
            I  => S,
            EN => EN,
            Y  => decoded
        );

    -- Mask each data bit with its enable line from the decoder
    masked <= D AND decoded;

    -- OR-reduce: only the selected (unmasked) bit survives
    Y <= ((masked(0) OR masked(1)) OR (masked(2) OR masked(3)))
      OR ((masked(4) OR masked(5)) OR (masked(6) OR masked(7)));

end Behavioral;
