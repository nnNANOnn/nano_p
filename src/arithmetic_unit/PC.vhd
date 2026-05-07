----------------------------------------------------------------------------------
-- Module : PC
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- 3-bit Program Counter.  On every rising clock edge it loads the next
-- address presented on A (chosen externally between PC+1 and a jump
-- target by the 2-way 3-bit PC-source mux).  An asynchronous reset is
-- routed to the same pushbutton that resets the Register Bank, so the
-- machine always starts at address "000".
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

entity PC is
    Port (
        A   : in  instruction_address;   -- next-PC (from 2-way 3-bit mux)
        Res : in  STD_LOGIC;             -- reset (active high)
        Clk : in  STD_LOGIC;
        M   : out instruction_address    -- current PC -> Program ROM address
    );
end PC;

architecture Behavioral of PC is
begin

    -- 3-bit register, always enabled, async reset to "000"
    Reg_0 : entity work.Reg
        generic map (N => 3)
        port map (
            D   => A,
            Res => Res,
            En  => '1',
            Clk => Clk,
            Q   => M
        );

end Behavioral;
