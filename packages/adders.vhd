----------------------------------------------------------------------------------
-- Package : Adders
-- Project : Nanoprocessor (Lab 9-10, CS1050)
--
-- Component declarations for the basic arithmetic primitives.  Anyone
-- who does `use work.adders.all;` gets convenient access to RCA_4,
-- RCA_3, FA, HA, and D_FF without needing to write component
-- declarations of their own.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package Adders is

    component RCA_4
        Port (
            A         : in  STD_LOGIC_VECTOR(3 downto 0);
            B         : in  STD_LOGIC_VECTOR(3 downto 0);
            C_in      : in  STD_LOGIC;
            S         : out STD_LOGIC_VECTOR(3 downto 0);
            C_out     : out STD_LOGIC;
            C_in_last : out STD_LOGIC
        );
    end component;

    component RCA_3
        Port (
            A     : in  STD_LOGIC_VECTOR(2 downto 0);
            B     : in  STD_LOGIC_VECTOR(2 downto 0);
            C_in  : in  STD_LOGIC;
            S     : out STD_LOGIC_VECTOR(2 downto 0);
            C_out : out STD_LOGIC
        );
    end component;

    component FA
        Port (
            A     : in  STD_LOGIC;
            B     : in  STD_LOGIC;
            C_in  : in  STD_LOGIC;
            S     : out STD_LOGIC;
            C_out : out STD_LOGIC
        );
    end component;

    component HA
        Port (
            A : in  STD_LOGIC;
            B : in  STD_LOGIC;
            S : out STD_LOGIC;
            C : out STD_LOGIC
        );
    end component;

    component D_FF
        Port (
            D    : in  STD_LOGIC;
            Res  : in  STD_LOGIC;
            Clk  : in  STD_LOGIC;
            En   : in  STD_LOGIC;
            Q    : out STD_LOGIC;
            Qbar : out STD_LOGIC
        );
    end component;

end package Adders;
