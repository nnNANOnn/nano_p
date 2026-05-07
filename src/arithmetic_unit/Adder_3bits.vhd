----------------------------------------------------------------------------------
-- Module : RCA_3  (3-bit Ripple Carry Adder)
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- Three FAs cascaded by their carry chain.  Used by PC_Inc to compute
-- PC + 1 (where B = "001", C_in = '0', and C_out is intentionally left
-- open so the PC wraps from 7 to 0).
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.adders.FA;

entity RCA_3 is
    Port (
        A     : in  STD_LOGIC_VECTOR(2 downto 0);
        B     : in  STD_LOGIC_VECTOR(2 downto 0);
        C_in  : in  STD_LOGIC;
        S     : out STD_LOGIC_VECTOR(2 downto 0);
        C_out : out STD_LOGIC
    );
end RCA_3;

architecture Behavioral of RCA_3 is
    signal Carry_In  : STD_LOGIC_VECTOR(2 downto 0);
    signal Carry_Out : STD_LOGIC_VECTOR(2 downto 0);
begin

    Carry_In(0) <= C_in;

    FAs : for i in 0 to 2 generate
        FA_inst : FA
            port map (
                A     => A(i),
                B     => B(i),
                C_in  => Carry_In(i),
                S     => S(i),
                C_out => Carry_Out(i)
            );

        gen_chain : if i < 2 generate
            Carry_In(i+1) <= Carry_Out(i);
        end generate gen_chain;
    end generate FAs;

    C_out <= Carry_Out(2);

end Behavioral;
