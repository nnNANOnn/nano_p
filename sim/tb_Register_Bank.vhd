----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/29/2026 09:53:10 PM
-- Design Name: 
-- Module Name: tb_Register_Bank - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

entity tb_Register_Bank is
end tb_Register_Bank;

architecture Behavioral of tb_Register_Bank is

    component Register_Bank
        Port (
            Reg_En     : in  register_address;
            Res        : in  STD_LOGIC;
            Clk        : in  STD_LOGIC;
            Data       : in  data_bus;
            Data_Buses : out data_buses
        );
    end component;

    signal Reg_En     : register_address := "000";
    signal Res        : STD_LOGIC := '0';
    signal Clk        : STD_LOGIC := '0';
    signal Data       : data_bus := (others => '0');
    signal Data_Buses : data_buses;

begin

    UUT : Register_Bank
        port map (
            Reg_En     => Reg_En,
            Res        => Res,
            Clk        => Clk,
            Data       => Data,
            Data_Buses => Data_Buses
        );

    -- Clock generation
    process
    begin
        while true loop
            Clk <= '0';
            wait for 10 ns;
            Clk <= '1';
            wait for 10 ns;
        end loop;
    end process;

    -- Stimulus process
    process
    begin
        -- Reset all registers
        Res <= '1';
        wait for 25 ns;
        Res <= '0';
        
         -- try to Write 0011 to R0
               Reg_En <= "000";
               Data   <= "0011";
               wait for 20 ns;

        -- Write 0011 to R1
        Reg_En <= "001";
        Data   <= "0011";
        wait for 20 ns;

        -- Write 0101 to R2
        Reg_En <= "010";
        Data   <= "0101";
        wait for 20 ns;

        -- Write 1010 to R3
        Reg_En <= "011";
        Data   <= "1010";
        wait for 20 ns;

        -- Write 1111 to R7
        Reg_En <= "111";
        Data   <= "1111";
        wait for 20 ns;

        -- Attempt to write to R0 (should remain 0000)
        Reg_En <= "000";
        Data   <= "1100";
        wait for 20 ns;

        wait;
    end process;

end Behavioral;
