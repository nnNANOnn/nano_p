----------------------------------------------------------------------------------
-- Module : PC_Inc
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- 3-bit incrementer used to compute PC + 1 every cycle.  Re-uses the
-- 3-bit Ripple Carry Adder (RCA_3) by hard-wiring B = "001" and C_in = '0'.
-- The C_out of RCA_3 is intentionally left open: a 3-bit PC simply wraps
-- around at "111" + 1 = "000", which is fine since address 7 is the
-- last legal instruction slot.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.adders.all;
use work.buses.all;

entity PC_Inc is
    Port (
        A_in  : in  instruction_address;
        A_out : out instruction_address
    );
end PC_Inc;

architecture Behavioral of PC_Inc is
begin

    Add : RCA_3
        port map (
            A     => A_in,
            B     => "001",
            C_in  => '0',
            S     => A_out,
            C_out => open
        );

end Behavioral;
