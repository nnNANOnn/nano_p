----------------------------------------------------------------------------------
-- Module : HA  (Half Adder)
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
--   S = A XOR B
--   C = A AND B
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity HA is
    Port (
        A : in  STD_LOGIC;
        B : in  STD_LOGIC;
        S : out STD_LOGIC;
        C : out STD_LOGIC
    );
end HA;

architecture Behavioral of HA is
begin
    S <= A xor B;
    C <= A and B;
end Behavioral;
