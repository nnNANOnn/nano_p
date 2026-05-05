library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

-- 8-Way 4-Bit Multiplexer
-- Selects one of eight 4-bit register outputs and routes it to Y.
-- Internally built from four Mux_8_to_1 units (one per bit plane).
entity MUX_8_4 is
    Port (
        S  : in  std_logic_vector(2 downto 0); -- 3-bit select
        D  : in  buses_8_4;                    -- 8 x 4-bit input bundle
        EN : in  std_logic;                    -- active-high enable
        Y  : out std_logic_vector(3 downto 0) -- 4-bit selected output
    );
end MUX_8_4;

architecture Behavioral of MUX_8_4 is

    -- Transposed view: Mux_In(bit)(source) groups all sources for one bit plane
    signal Mux_In : buses_4_8;
    signal Y_int  : std_logic_vector(3 downto 0);

begin

    -- Generate one Mux_8_to_1 for each of the 4 bit positions
    gen_mux : for i in 0 to 3 generate

        -- Transpose: collect bit-i from every one of the 8 inputs into a single 8-bit word
        Mux_In(i) <= D(7)(i) & D(6)(i) & D(5)(i) & D(4)(i)
                   & D(3)(i) & D(2)(i) & D(1)(i) & D(0)(i);

        mux_inst : entity work.Mux_8_to_1
            port map (
                S  => S,
                D  => Mux_In(i),
                EN => EN,
                Y  => Y_int(i)
            );

    end generate gen_mux;

    Y <= Y_int;

end Behavioral;
