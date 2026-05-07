----------------------------------------------------------------------------------
-- Module : Mux_2_4
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- 2-way 4-bit multiplexer.  This is the "Immediate value Mux" sitting
-- on the Data Bus in Fig. 1 of the lab:
--   S = '0'  ->  Y = D0   (ALU output, used by ADD and NEG)
--   S = '1'  ->  Y = D1   (immediate value from the instruction)
--
-- Implementation: per-bit  Y = (D0 AND NOT S) OR (D1 AND S).
-- Total cost: 4 * (2 AND2 + 1 OR2) + 1 shared NOT = 12 gates + 1 NOT.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Mux_2_4 is
    Port (
        S  : in  STD_LOGIC;
        D0 : in  STD_LOGIC_VECTOR(3 downto 0);
        D1 : in  STD_LOGIC_VECTOR(3 downto 0);
        Y  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end Mux_2_4;

architecture Dataflow of Mux_2_4 is
    signal not_S : STD_LOGIC;
begin

    not_S <= not S;

    gen_bit : for i in 0 to 3 generate
        Y(i) <= (D0(i) and not_S) or (D1(i) and S);
    end generate gen_bit;

end Dataflow;
