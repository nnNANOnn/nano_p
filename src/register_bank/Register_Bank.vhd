----------------------------------------------------------------------------------
-- Module : Register_Bank
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- 8 x 4-bit register file.
--   * R0 is hardwired to "0000" (read-only zero register, required by
--     the NEG and JZR instructions).
--   * R1..R7 are writeable D-FF registers, all sharing the same Data
--     input and the same Reset line.
--   * Reg_En selects which register receives a write this cycle.
--   * Write_En is the master write enable produced by the Instruction
--     Decoder.  When Write_En = '0', the internal 3-to-8 decoder forces
--     all 8 of its outputs to zero, so no register's En line is asserted
--     and no register can latch.  This is what makes JZR a no-op for
--     the register file.
--
-- All 8 register outputs are exposed simultaneously on Data_Buses, so
-- that the two 8-way 4-bit muxes downstream can pick any pair without
-- needing read-port arbitration.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

entity Register_Bank is
    Port (
        Reg_En     : in  register_address;   -- which register to write (3 bits)
        Write_En   : in  STD_LOGIC;          -- master write-enable from decoder
        Res        : in  STD_LOGIC;          -- async reset (active high)
        Clk        : in  STD_LOGIC;
        Data       : in  data_bus;           -- 4-bit value to write
        Data_Buses : out data_buses          -- all 8 register outputs
    );
end Register_Bank;

architecture Behavioral of Register_Bank is

    -- One-hot enable lines from the 3-to-8 decoder.  When Write_En='0'
    -- all 8 outputs are forced to '0' by the decoder's EN input.
    signal Reg_Sel : STD_LOGIC_VECTOR(7 downto 0);

begin

    -- Address decoder: gates Reg_En through Write_En.
    Decoder : entity work.Decoder_3_to_8
        port map (
            I  => Reg_En,
            EN => Write_En,
            Y  => Reg_Sel
        );

    -- R0: hardwired to constant zero.  No flip-flops, no Reg_Sel(0)
    -- input -- writes are silently discarded.
    Data_Buses(0) <= "0000";

    -- R1..R7: real writeable registers.  Each one's En line is its
    -- corresponding bit of Reg_Sel, so exactly one (or zero) register
    -- latches per clock.
    registers : for i in 1 to 7 generate
        reg_inst : entity work.Reg
            generic map (
                N => 4
            )
            port map (
                D   => Data,
                Res => Res,
                En  => Reg_Sel(i),
                Clk => Clk,
                Q   => Data_Buses(i)
            );
    end generate registers;

end Behavioral;
