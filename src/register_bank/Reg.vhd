----------------------------------------------------------------------------------
-- Module : Reg
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- Generic N-bit register built from N D flip-flops (one per bit).
-- All flip-flops share the same Clk, En and Res lines.  Used both for
-- the 4-bit registers in the Register Bank (N=4) and for the 3-bit
-- Program Counter (N=3).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Reg is
    generic (
        N : integer := 4
    );
    Port (
        D   : in  STD_LOGIC_VECTOR(N-1 downto 0);
        Res : in  STD_LOGIC;
        En  : in  STD_LOGIC;
        Clk : in  STD_LOGIC;
        Q   : out STD_LOGIC_VECTOR(N-1 downto 0)
    );
end Reg;

architecture Behavioral of Reg is
begin

    -- Direct entity instantiation (no component declaration needed).
    -- Qbar of each D_FF is left open because the register output only
    -- needs Q.
    gen_ff : for i in 0 to N-1 generate
        D_FF_Inst : entity work.D_FF
            port map (
                D    => D(i),
                Res  => Res,
                Clk  => Clk,
                En   => En,
                Q    => Q(i),
                Qbar => open
            );
    end generate gen_ff;

end Behavioral;
