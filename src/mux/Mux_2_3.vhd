----------------------------------------------------------------------------------
-- Module : Mux_2_3
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- 2-way 3-bit multiplexer.  Used as the PC-source mux:
--   S = '0'  ->  Y = D0   (PC + 1, normal sequential flow)
--   S = '1'  ->  Y = D1   (jump_addr from the instruction decoder)
--
-- Implementation: per-bit  Y = (D0 AND NOT S) OR (D1 AND S).
-- Three identical 1-bit muxes generated in a loop.  Total cost:
--   3 * (2 AND2 + 1 OR2) + 1 shared NOT  =  9 gates + 1 NOT.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Mux_2_3 is
    Port (
        S  : in  STD_LOGIC;
        D0 : in  STD_LOGIC_VECTOR(2 downto 0);
        D1 : in  STD_LOGIC_VECTOR(2 downto 0);
        Y  : out STD_LOGIC_VECTOR(2 downto 0)
    );
end Mux_2_3;

architecture Dataflow of Mux_2_3 is
    signal not_S : STD_LOGIC;
begin

    not_S <= not S;

    gen_bit : for i in 0 to 2 generate
        Y(i) <= (D0(i) and not_S) or (D1(i) and S);
    end generate gen_bit;

end Dataflow;
