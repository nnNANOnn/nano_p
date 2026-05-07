----------------------------------------------------------------------------------
-- Module : Nanoprocessor (TOP LEVEL)
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- This is the top-level entity that wires together every component of
-- the 4-bit nanoprocessor described in Fig. 1 of the lab handout.
--
--                  +------------- Program ROM (8 x 12) -------------+
--                  |                       |                         |
--                  |                       v  I (12)                 |
--          +-------+--------+   +------------------------+           |
--          | 2-way 3-bit Mux|<--| Instruction Decoder    |           |
--          |  (PC source)   |   +------------------------+           |
--          +----------------+         |   |   |   |                  |
--                 ^                   |   |   |   |                  |
--                 |  PC+1   jump_addr |   |   |   |                  |
--          +-------------+   +--------+   |   |   |                  |
--          | 3-bit Adder |   | reg_en |   | mux_a_sel  mux_b_sel     |
--          +-------------+   |  sel   |   |     |          |         |
--                 ^          | wr_en  |   |     v          v         |
--                 |          +--------+   | 8-way 4-bit  8-way 4-bit |
--          +-------------+        |       |   Mux A         Mux B    |
--          |     PC      +--------+       |     |             |      |
--          +-------------+                |     |             |      |
--                 ^                       |     +-> reg_check |      |
--                 |                       |     v             v      |
--                 |                       |   +-----------------+    |
--                 |                       |   | 4-bit Add/Sub U |    |
--                 |                       |   +-----------------+    |
--                 |                       |     |     |     |        |
--                 |                       |     v     v     v        |
--                 |                       |   ALU  Zero Overflow      |
--                 |                       |     |                     |
--                 |  load_sel             |     v                     |
--                 |    +------------------|   +-------+               |
--                 |    | 2-way 4-bit Mux  |<-+| imm_v |               |
--                 |    +-------+----------+   +-------+               |
--                 |            |                                       |
--                 |            v  Data Bus (4)                         |
--                 |    +-----------------+                             |
--                 +----| Register Bank 8 |---> 8 x 4-bit Data_Buses ---+
--                      +-----------------+
--
-- Outputs to board:
--   Result_LED  = R7 value          -> LD0..LD3
--   Zero_LED    = ALU's Zero flag    -> LD14
--   Carry_LED   = ALU's OverFlow flag-> LD15
--   Cathodes/Anodes -> 7-segment display showing R7
--
-- Inputs from board:
--   Clk_100MHz  = the Basys 3 100 MHz clock
--   Reset_Btn   = a pushbutton -- resets PC and Register Bank
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

entity Nanoprocessor is
    generic (
        -- Slow-clock divider.  Default 100_000_000 -> 2-second period at
        -- 100 MHz, suitable for hardware.  Testbenches should override
        -- this with a small value (e.g. 5) to make simulation tractable.
        DIV_LIMIT : integer := 100_000_000
    );
    Port (
        -- Board inputs
        Clk_100MHz : in  STD_LOGIC;
        Reset_Btn  : in  STD_LOGIC;

        -- Board outputs
        Result_LED : out STD_LOGIC_VECTOR(3 downto 0);   -- LD0..LD3 (R7)
        Zero_LED   : out STD_LOGIC;                       -- LD14
        Carry_LED  : out STD_LOGIC;                       -- LD15
        Cathodes   : out STD_LOGIC_VECTOR(6 downto 0);   -- 7-seg segments
        Anodes     : out STD_LOGIC_VECTOR(3 downto 0)    -- 7-seg digit selects
    );
end Nanoprocessor;

architecture Structural of Nanoprocessor is

    ------------------------------------------------------------------
    -- Internal signals (matching the lab's bus names where possible)
    ------------------------------------------------------------------

    -- Slow clock fed to the synchronous elements
    signal Slow_Clk      : STD_LOGIC;

    -- Program-counter signals
    signal PC_curr       : instruction_address;          -- M bus: current PC
    signal PC_next       : instruction_address;          -- output of PC-source mux
    signal PC_plus1      : instruction_address;          -- PC + 1 from 3-bit adder

    -- Instruction memory bus
    signal I_bus         : instruction_bus;

    -- Decoder outputs
    signal reg_en_sel    : STD_LOGIC_VECTOR(2 downto 0);
    signal reg_write_en  : STD_LOGIC;
    signal load_sel      : STD_LOGIC;
    signal imm_val       : STD_LOGIC_VECTOR(3 downto 0);
    signal mux_a_sel     : STD_LOGIC_VECTOR(2 downto 0);
    signal mux_b_sel     : STD_LOGIC_VECTOR(2 downto 0);
    signal add_sub_sel   : STD_LOGIC;
    signal jump_flag     : STD_LOGIC;
    signal jump_addr     : STD_LOGIC_VECTOR(2 downto 0);

    -- Register-bank signals
    signal Data_Bus      : data_bus;          -- D bus, the value being written
    signal Reg_Outputs   : data_buses;        -- all 8 register outputs

    -- ALU operand and result signals
    signal Mux_A_out     : STD_LOGIC_VECTOR(3 downto 0);
    signal Mux_B_out     : STD_LOGIC_VECTOR(3 downto 0);
    signal ALU_result    : STD_LOGIC_VECTOR(3 downto 0);
    signal ALU_zero      : STD_LOGIC;
    signal ALU_overflow  : STD_LOGIC;

begin

    ------------------------------------------------------------------
    -- 1) Slow clock generator
    ------------------------------------------------------------------
    clk_div : entity work.Clock_Divider
        generic map ( DIV_LIMIT => DIV_LIMIT )
        port map (
            Clk_in   => Clk_100MHz,
            Res      => Reset_Btn,
            Slow_Clk => Slow_Clk
        );

    ------------------------------------------------------------------
    -- 2) Program Counter (sequential)
    ------------------------------------------------------------------
    pc_inst : entity work.PC
        port map (
            A   => PC_next,
            Res => Reset_Btn,
            Clk => Slow_Clk,
            M   => PC_curr
        );

    ------------------------------------------------------------------
    -- 3) PC+1 incrementer (combinational)
    ------------------------------------------------------------------
    pc_inc_inst : entity work.PC_Inc
        port map (
            A_in  => PC_curr,
            A_out => PC_plus1
        );

    ------------------------------------------------------------------
    -- 4) PC-source mux: selects PC+1 or jump target
    ------------------------------------------------------------------
    pc_src_mux : entity work.Mux_2_3
        port map (
            S  => jump_flag,
            D0 => PC_plus1,    -- jump_flag = 0 -> normal sequential
            D1 => jump_addr,   -- jump_flag = 1 -> taken branch
            Y  => PC_next
        );

    ------------------------------------------------------------------
    -- 5) Program ROM
    ------------------------------------------------------------------
    rom_inst : entity work.Program_ROM
        port map (
            ROM_address => PC_curr,
            I           => I_bus
        );

    ------------------------------------------------------------------
    -- 6) Instruction Decoder
    --    NOTE: "Register check for jump" feedback comes from Mux_A's
    --    output, exactly as shown in Fig. 1.
    ------------------------------------------------------------------
    dec_inst : entity work.instruction_decoder
        port map (
            instruction   => I_bus,
            reg_check_val => Mux_A_out,
            reg_en_sel    => reg_en_sel,
            reg_write_en  => reg_write_en,
            load_sel      => load_sel,
            imm_val       => imm_val,
            mux_a_sel     => mux_a_sel,
            mux_b_sel     => mux_b_sel,
            add_sub_sel   => add_sub_sel,
            jump_flag     => jump_flag,
            jump_addr     => jump_addr
        );

    ------------------------------------------------------------------
    -- 7) Register Bank
    ------------------------------------------------------------------
    rb_inst : entity work.Register_Bank
        port map (
            Reg_En     => reg_en_sel,
            Write_En   => reg_write_en,
            Res        => Reset_Btn,
            Clk        => Slow_Clk,
            Data       => Data_Bus,
            Data_Buses => Reg_Outputs
        );

    ------------------------------------------------------------------
    -- 8) Operand muxes for the ALU (the two 8-way 4-bit muxes)
    ------------------------------------------------------------------
    mux_a : entity work.MUX_8_4
        port map (
            S  => mux_a_sel,
            D  => Reg_Outputs,
            EN => '1',
            Y  => Mux_A_out
        );

    mux_b : entity work.MUX_8_4
        port map (
            S  => mux_b_sel,
            D  => Reg_Outputs,
            EN => '1',
            Y  => Mux_B_out
        );

    ------------------------------------------------------------------
    -- 9) 4-bit Add/Sub Unit (the ALU)
    ------------------------------------------------------------------
    alu : entity work.Add_Sub_4_bit
        port map (
            A_AS     => Mux_A_out,
            B_AS     => Mux_B_out,
            CTRL     => add_sub_sel,
            S_AS     => ALU_result,
            Zero     => ALU_zero,
            OverFlow => ALU_overflow
        );

    ------------------------------------------------------------------
    -- 10) Data-bus mux (the "Immediate value Mux")
    --     load_sel = 0 -> ALU result    (ADD, NEG)
    --     load_sel = 1 -> immediate     (MOVI)
    ------------------------------------------------------------------
    data_mux : entity work.Mux_2_4
        port map (
            S  => load_sel,
            D0 => ALU_result,
            D1 => imm_val,
            Y  => Data_Bus
        );

    ------------------------------------------------------------------
    -- 11) Output wiring (Step 5 of the lab)
    --
    --   * R7  -> LD0..LD3 + 7-segment display
    --   * Zero flag      -> LD14
    --   * Overflow flag  -> LD15
    ------------------------------------------------------------------
    Result_LED <= Reg_Outputs(7);
    Zero_LED   <= ALU_zero;
    Carry_LED  <= ALU_overflow;

    seven_seg : entity work.Seven_Seg_Driver
        port map (
            Value    => Reg_Outputs(7),
            Cathodes => Cathodes,
            Anodes   => Anodes
        );

end Structural;
