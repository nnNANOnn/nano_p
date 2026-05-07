----------------------------------------------------------------------------------
-- Testbench: tb_Register_Bank
-- Updated to drive the new Write_En port.  Demonstrates that:
--   * R0 is read-only and stays at "0000" no matter what is written
--   * R1..R7 latch only when Write_En = '1' AND Reg_En selects them
--   * Async reset zeroes R1..R7
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

entity tb_Register_Bank is
end tb_Register_Bank;

architecture Behavioral of tb_Register_Bank is

    signal Reg_En     : register_address := "000";
    signal Write_En   : STD_LOGIC := '0';
    signal Res        : STD_LOGIC := '0';
    signal Clk        : STD_LOGIC := '0';
    signal Data       : data_bus := (others => '0');
    signal Data_Buses : data_buses;

begin

    UUT : entity work.Register_Bank
        port map (
            Reg_En     => Reg_En,
            Write_En   => Write_En,
            Res        => Res,
            Clk        => Clk,
            Data       => Data,
            Data_Buses => Data_Buses
        );

    -- 50 MHz simulation clock
    clk_gen : process
    begin
        Clk <= '0';
        wait for 10 ns;
        Clk <= '1';
        wait for 10 ns;
    end process;

    stim : process
    begin
        -- Reset everything
        Res <= '1';
        wait for 25 ns;
        Res <= '0';

        -- Try to write 0011 to R0 (should be silently ignored: R0 is read-only)
        Reg_En   <= "000";
        Data     <= "0011";
        Write_En <= '1';
        wait for 20 ns;

        -- Write 0011 to R1
        Reg_En   <= "001";
        Data     <= "0011";
        Write_En <= '1';
        wait for 20 ns;

        -- Write 0101 to R2
        Reg_En   <= "010";
        Data     <= "0101";
        Write_En <= '1';
        wait for 20 ns;

        -- Write 1010 to R3
        Reg_En   <= "011";
        Data     <= "1010";
        Write_En <= '1';
        wait for 20 ns;

        -- Write 1111 to R7
        Reg_En   <= "111";
        Data     <= "1111";
        Write_En <= '1';
        wait for 20 ns;

        -- With Write_En = '0', no register should change
        Reg_En   <= "001";
        Data     <= "0000";
        Write_En <= '0';
        wait for 20 ns;

        wait;
    end process;

end Behavioral;
