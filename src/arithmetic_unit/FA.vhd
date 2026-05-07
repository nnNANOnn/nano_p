----------------------------------------------------------------------------------
-- Module : FA  (Full Adder)
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- Built from two Half Adders plus an OR for the carry-out:
--   S     = A XOR B XOR C_in
--   C_out = (A AND B) OR ((A XOR B) AND C_in)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.adders.HA;

entity FA is
    Port (
        A     : in  STD_LOGIC;
        B     : in  STD_LOGIC;
        C_in  : in  STD_LOGIC;
        S     : out STD_LOGIC;
        C_out : out STD_LOGIC
    );
end FA;

architecture Behavioral of FA is
    signal HA0_S, HA0_C, HA1_C : STD_LOGIC;
begin

    HA_0 : HA port map (A => A,     B => B,    S => HA0_S, C => HA0_C);
    HA_1 : HA port map (A => HA0_S, B => C_in, S => S,     C => HA1_C);

    C_out <= HA0_C or HA1_C;

end Behavioral;
