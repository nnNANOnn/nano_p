----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240043A
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_Register_Bank - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

entity TB_Register_Bank is
end TB_Register_Bank;

architecture Behavioral of TB_Register_Bank is
    component Register_Bank is
        Port ( Reg_En : in register_address; Write_En, Res, Clk : in STD_LOGIC; Data : in data_bus; Data_Buses : out data_buses);
    end component;
    signal Reg_En : register_address; signal Write_En, Res, Clk : STD_LOGIC := '0'; signal Data : data_bus; signal Data_Buses : data_buses;
begin
    UUT: Register_Bank port map( Reg_En => Reg_En, Write_En => Write_En, Res => Res, Clk => Clk, Data => Data, Data_Buses => Data_Buses );
    
    process begin Clk <= '0'; wait for 10 ns; Clk <= '1'; wait for 10 ns; end process;
    
    process
    begin
        -- Init Reset to clear state
        Res <= '1'; wait for 20 ns; Res <= '0'; wait for 20 ns;
        
        -- Index Number: 240043A
        -- Binary Representation: 0011 1010 1001 1010 1011
        
        -- TC1: Reg_En=bits(2..0), Write_En=bit(3), Data=bits(7..4)
        Reg_En <= "011"; Write_En <= '1'; Data <= "1010";
        wait for 40 ns;
        
        -- TC2: Reg_En=bits(6..4), Write_En=bit(7), Data=bits(11..8)
        Reg_En <= "010"; Write_En <= '1'; Data <= "1001";
        wait for 40 ns;
        
        -- TC3: Reg_En=bits(10..8), Write_En=bit(11), Data=bits(15..12)
        Reg_En <= "001"; Write_En <= '1'; Data <= "1010";
        wait for 40 ns;
        
        -- TC4: Reg_En=bits(14..12), Write_En=bit(15), Data=bits(19..16)
        Reg_En <= "010"; Write_En <= '1'; Data <= "0011";
        wait for 40 ns;
        
        -- TC5: Reg_En=bits(18..16), Write_En=bit(19), Data=bits(3..0)
        Reg_En <= "011"; Write_En <= '0'; Data <= "1011";
        wait for 40 ns;
        
        wait;
    end process;
end Behavioral;