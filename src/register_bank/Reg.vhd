----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/28/2026 09:02:30 AM
-- Design Name: 
-- Module Name: Reg - Behavioral
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


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Reg is
    generic(
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

    component D_FF
        Port (
            D   : in STD_LOGIC;
            Res : in STD_LOGIC;
            En  : in STD_LOGIC;
            Clk : in STD_LOGIC;
            Q   : out STD_LOGIC
        );
    end component;

begin

    gen_ff: for i in 0 to N-1 generate
        D_FF_Inst: D_FF
            port map(
                D   => D(i),
                Res => Res,
                En  => En,
                Clk => Clk,
                Q   => Q(i)
            );
    end generate;

end Behavioral;