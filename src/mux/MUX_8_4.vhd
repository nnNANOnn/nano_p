----------------------------------------------------------------------------------
-- Module : Mux_8_4
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- 8-way 4-bit multiplexer: selects one of eight 4-bit register-bank
-- outputs and forwards it as a 4-bit word.  Built from four 8-to-1
-- single-bit muxes (one per bit-plane), exactly as the lab handout
-- suggests.
--
-- Inputs:
--   D : the 8 register outputs (data_buses, indexed [0..7])
--   S : 3-bit select (which register to read)
--   EN: enable; when '0', the output is forced to "0000"
-- Output:
--   Y : the 4-bit selected word
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

entity Mux_8_4 is
    Port (
        S  : in  STD_LOGIC_VECTOR(2 downto 0);
        D  : in  data_buses;
        EN : in  STD_LOGIC;
        Y  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end Mux_8_4;

architecture Behavioral of Mux_8_4 is

    -- Bit-plane view: Mux_In(b) collects bit b from every one of the 8
    -- register words.  Each plane drives one Mux_8_1.
    signal Mux_In : buses_4_8;
    signal Y_int  : STD_LOGIC_VECTOR(3 downto 0);

begin

    -- Generate one Mux_8_1 for each of the 4 bit-planes.
    gen_mux : for b in 0 to 3 generate

        -- Transpose: gather bit b from each of the 8 register outputs.
        Mux_In(b) <= D(7)(b) & D(6)(b) & D(5)(b) & D(4)(b)
                   & D(3)(b) & D(2)(b) & D(1)(b) & D(0)(b);

        mux_inst : entity work.Mux_8_1
            port map (
                S  => S,
                D  => Mux_In(b),
                EN => EN,
                Y  => Y_int(b)
            );

    end generate gen_mux;

    Y <= Y_int;

end Behavioral;
