----------------------------------------------------------------------------------
-- Module : RCA_4  (4-bit Ripple Carry Adder)
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- Four FAs cascaded by their carry chain.  Used by the 4-bit Add/Sub ALU.
-- C_in_last (the carry into the MSB FA) is exposed so the ALU can XOR
-- it with C_out to detect signed overflow.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.adders.all;

entity RCA_4 is
    Port (
        A         : in  STD_LOGIC_VECTOR(3 downto 0);
        B         : in  STD_LOGIC_VECTOR(3 downto 0);
        C_in      : in  STD_LOGIC;
        S         : out STD_LOGIC_VECTOR(3 downto 0);
        C_out     : out STD_LOGIC;
        C_in_last : out STD_LOGIC
    );
end RCA_4;

architecture Behavioral of RCA_4 is
    signal Carry_In  : STD_LOGIC_VECTOR(3 downto 0);
    signal Carry_Out : STD_LOGIC_VECTOR(3 downto 0);
begin

    Carry_In(0) <= C_in;

    FAs : for i in 0 to 3 generate
        FA_inst : FA
            port map (
                A     => A(i),
                B     => B(i),
                C_in  => Carry_In(i),
                S     => S(i),
                C_out => Carry_Out(i)
            );

        gen_chain : if i < 3 generate
            Carry_In(i+1) <= Carry_Out(i);
        end generate gen_chain;
    end generate FAs;

    C_out     <= Carry_Out(3);
    C_in_last <= Carry_In(3);

end Behavioral;
