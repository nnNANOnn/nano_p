----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/29/2026 09:39:00 PM
-- Design Name: 
-- Module Name: Register_Bank - Behavioral
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

entity Register_Bank is
    Port (
        Reg_En     : in  register_address;
        Res        : in  STD_LOGIC;
        Clk        : in  STD_LOGIC;
        Data       : in  data_bus;
        Data_Buses : out data_buses
    );
end Register_Bank;

architecture Behavioral of Register_Bank is

    component Reg
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
    end component;

    component Decoder_3_to_8
        Port (
            I  : in  STD_LOGIC_VECTOR(2 downto 0);
            EN : in  STD_LOGIC;
            Y  : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    signal Reg_Sel : STD_LOGIC_VECTOR(7 downto 0);

begin

    Decoder_3_to_8_0 : Decoder_3_to_8
        port map(
            I  => Reg_En,
            EN => '1',
            Y  => Reg_Sel
        );

    -- R0: Constant zero register
    reg_inst0 : Reg
        generic map(
            N => 4
        )
        port map(
            D   => "0000",
            Res => Res,
            En  => '1',
            Clk => Clk,
            Q   => Data_Buses(0)
        );

    -- R1 to R7: Writable registers
    registers : for i in 1 to 7 generate
        reg_inst : Reg
            generic map(
                N => 4
            )
            port map(
                D   => Data,
                Res => Res,
                En  => Reg_Sel(i),
                Clk => Clk,
                Q   => Data_Buses(i)
            );
    end generate registers;

end Behavioral;