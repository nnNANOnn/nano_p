----------------------------------------------------------------------------------
-- Module : Seven_Seg_Driver
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- Drives a single digit of the Basys 3 4-digit common-anode 7-segment
-- display so that R7 (the result register of the lab program) is
-- visible as a hex character (0..F).  The other three digits are
-- blanked.
--
-- Outputs:
--   Cathodes : segments {a,b,c,d,e,f,g}, active LOW
--   Anodes   : digit selects {AN3,AN2,AN1,AN0}, active LOW
--              "1110" lights up only AN0 (the rightmost digit).
--
-- The LUT below is the standard 7-segment encoding for hex 0..F on a
-- common-anode display (segment ON = '0').
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Seven_Seg_Driver is
    Port (
        Value    : in  STD_LOGIC_VECTOR(3 downto 0);   -- 4-bit value to display
        Cathodes : out STD_LOGIC_VECTOR(6 downto 0);   -- {a,b,c,d,e,f,g}
        Anodes   : out STD_LOGIC_VECTOR(3 downto 0)    -- digit-select, active low
    );
end Seven_Seg_Driver;

architecture Behavioral of Seven_Seg_Driver is
begin

    -- Light up only the right-most digit (AN0); blank the rest.
    Anodes <= "1110";

    -- Hex-to-segment lookup (active-low segments).
    with Value select
        Cathodes <= "0000001" when "0000",   -- 0
                    "1001111" when "0001",   -- 1
                    "0010010" when "0010",   -- 2
                    "0000110" when "0011",   -- 3
                    "1001100" when "0100",   -- 4
                    "0100100" when "0101",   -- 5
                    "0100000" when "0110",   -- 6
                    "0001111" when "0111",   -- 7
                    "0000000" when "1000",   -- 8
                    "0000100" when "1001",   -- 9
                    "0001000" when "1010",   -- A
                    "1100000" when "1011",   -- B
                    "0110001" when "1100",   -- C
                    "1000010" when "1101",   -- D
                    "0110000" when "1110",   -- E
                    "0111000" when "1111",   -- F
                    "1111111" when others;   -- blank

end Behavioral;
