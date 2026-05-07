----------------------------------------------------------------------------------
-- Package : buses
-- Project : Nanoprocessor (Lab 9-10, CS1050)
--
-- Centralised type definitions for every internal bus and bundle in the
-- nanoprocessor.  Using subtypes (rather than raw std_logic_vector
-- everywhere) makes port signatures self-documenting and lets the compiler
-- catch width mismatches.
--
-- Bus naming follows the lab handout:
--   D = data bus      (4 bits)
--   I = instruction   (12 bits)
--   M = memory addr   (3 bits, the PC value)
--   R = register addr (3 bits, the register-bank select)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package buses is

    ------------------------------------------------------------------
    -- Single-wire bundles
    ------------------------------------------------------------------
    subtype data_bus            is STD_LOGIC_VECTOR(3  downto 0);   -- D bus
    subtype instruction_bus     is STD_LOGIC_VECTOR(11 downto 0);   -- I bus
    subtype register_address    is STD_LOGIC_VECTOR(2  downto 0);   -- R bus
    subtype instruction_address is STD_LOGIC_VECTOR(2  downto 0);   -- M bus
    subtype jump_address        is STD_LOGIC_VECTOR(2  downto 0);   -- 3-bit jump field

    ------------------------------------------------------------------
    -- Aggregate bundles
    --
    -- data_buses  : all eight register outputs, indexed [0..7].
    --               This is what the Register Bank emits and what the
    --               two 8-way 4-bit muxes consume.
    --
    -- buses_4_8   : the *transposed* view used inside the 8-way 4-bit
    --               mux: 4 bit-planes of 8 sources each.  Each
    --               Mux_8_to_1 instance gets one of these planes.
    ------------------------------------------------------------------
    type data_buses is array (0 to 7) of data_bus;
    type buses_4_8  is array (0 to 3) of STD_LOGIC_VECTOR(7 downto 0);

end package buses;

package body buses is
end package body buses;
