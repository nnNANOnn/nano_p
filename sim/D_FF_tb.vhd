----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240043A
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_D_FF - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_D_FF is
end TB_D_FF;

architecture Behavioral of TB_D_FF is
    component D_FF is
        Port ( D, Res, Clk, En : in STD_LOGIC; Q, Qbar : out STD_LOGIC);
    end component;
    signal D, Res, Clk, En, Q, Qbar : STD_LOGIC := '0';
begin
    UUT: D_FF port map( D => D, Res => Res, Clk => Clk, En => En, Q => Q, Qbar => Qbar );
    
    process begin Clk <= '0'; wait for 10 ns; Clk <= '1'; wait for 10 ns; end process;
    
    process
    begin
        -- Index Number: 240043A
        -- Binary Representation: 0011 1010 1001 1010 1011
        
        -- TC1: D=bit(0), Res=bit(1), En=bit(2)
        D <= '1'; Res <= '1'; En <= '0';
        wait for 40 ns;
        
        -- TC2: D=bit(3), Res=bit(4), En=bit(5)
        D <= '1'; Res <= '0'; En <= '1';
        wait for 40 ns;
        
        -- TC3: D=bit(6), Res=bit(7), En=bit(8)
        D <= '0'; Res <= '1'; En <= '0';
        wait for 40 ns;
        
        -- TC4: D=bit(9), Res=bit(10), En=bit(11)
        D <= '1'; Res <= '0'; En <= '1';
        wait for 40 ns;
        
        -- TC5: D=bit(12), Res=bit(13), En=bit(14)
        D <= '0'; Res <= '1'; En <= '0';
        wait for 40 ns;
        
        wait;
    end process;
end Behavioral;