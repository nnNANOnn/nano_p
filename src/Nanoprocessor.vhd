library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

entity Nanoprocessor is
    generic ( DIV_LIMIT : integer := 100_000_000 );
    Port (
        Clk_100MHz : in  STD_LOGIC;
        Reset_Btn  : in  STD_LOGIC;
        Result_LED : out STD_LOGIC_VECTOR(3 downto 0);
        Zero_LED   : out STD_LOGIC;
        Carry_LED  : out STD_LOGIC;
        Cathodes   : out STD_LOGIC_VECTOR(6 downto 0);
        Anodes     : out STD_LOGIC_VECTOR(3 downto 0)
    );
end Nanoprocessor;

architecture Structural of Nanoprocessor is
    signal Slow_Clk      : STD_LOGIC;
    signal PC_curr       : instruction_address;
    signal PC_next       : instruction_address;
    signal PC_plus1      : instruction_address;
    signal I_bus         : instruction_bus;
    signal reg_en_sel    : STD_LOGIC_VECTOR(2 downto 0);
    signal reg_write_en  : STD_LOGIC;
    signal load_sel      : STD_LOGIC;
    signal imm_val       : STD_LOGIC_VECTOR(3 downto 0);
    signal mux_a_sel     : STD_LOGIC_VECTOR(2 downto 0);
    signal mux_b_sel     : STD_LOGIC_VECTOR(2 downto 0);
    signal add_sub_sel   : STD_LOGIC;
    signal jump_flag     : STD_LOGIC;
    signal jump_addr     : STD_LOGIC_VECTOR(2 downto 0);
    signal Data_Bus      : data_bus;
    signal Reg_Outputs   : data_buses;
    signal Mux_A_out     : STD_LOGIC_VECTOR(3 downto 0);
    signal Mux_B_out     : STD_LOGIC_VECTOR(3 downto 0);
    signal ALU_result    : STD_LOGIC_VECTOR(3 downto 0);
    signal ALU_zero      : STD_LOGIC;
    signal ALU_overflow  : STD_LOGIC;
    signal ALU_carry     : STD_LOGIC; -- NEW SIGNAL
begin
    clk_div : entity work.Clock_Divider
        generic map ( DIV_LIMIT => DIV_LIMIT )
        port map (Clk_in => Clk_100MHz, Res => Reset_Btn, Slow_Clk => Slow_Clk);

    pc_inst : entity work.PC
        port map (A => PC_next, Res => Reset_Btn, Clk => Slow_Clk, M => PC_curr);

    pc_inc_inst : entity work.PC_Inc
        port map (A_in => PC_curr, A_out => PC_plus1);

    pc_src_mux : entity work.Mux_2_3
        port map (S => jump_flag, D0 => PC_plus1, D1 => jump_addr, Y => PC_next);

    rom_inst : entity work.Program_ROM
        port map (ROM_address => PC_curr, I => I_bus);

    -- UPDATED ENTITY NAME
    dec_inst : entity work.Instruction_Decoder 
        port map (
            instruction => I_bus, reg_check_val => Mux_A_out, reg_en_sel => reg_en_sel,
            reg_write_en => reg_write_en, load_sel => load_sel, imm_val => imm_val,
            mux_a_sel => mux_a_sel, mux_b_sel => mux_b_sel, add_sub_sel => add_sub_sel,
            jump_flag => jump_flag, jump_addr => jump_addr
        );

    rb_inst : entity work.Register_Bank
        port map (
            Reg_En => reg_en_sel, Write_En => reg_write_en, Res => Reset_Btn,
            Clk => Slow_Clk, Data => Data_Bus, Data_Buses => Reg_Outputs
        );

    -- UPDATED ENTITY NAME
    mux_a : entity work.Mux_8_4
        port map (S => mux_a_sel, D => Reg_Outputs, EN => '1', Y => Mux_A_out);

    -- UPDATED ENTITY NAME
    mux_b : entity work.Mux_8_4
        port map (S => mux_b_sel, D => Reg_Outputs, EN => '1', Y => Mux_B_out);

    alu : entity work.Add_Sub_4_bit
        port map (
            A_AS => Mux_A_out, B_AS => Mux_B_out, CTRL => add_sub_sel,
            S_AS => ALU_result, Zero => ALU_zero, OverFlow => ALU_overflow,
            Carry_Out => ALU_carry -- NEW MAPPING
        );

    data_mux : entity work.Mux_2_4
        port map (S => load_sel, D0 => ALU_result, D1 => imm_val, Y => Data_Bus);

    Result_LED <= Reg_Outputs(7);
    Zero_LED   <= ALU_zero;
    Carry_LED  <= ALU_carry; -- MODIFIED: Now represents true Carry

    seven_seg : entity work.Seven_Seg_Driver
        port map (Value => Reg_Outputs(7), Cathodes => Cathodes, Anodes => Anodes);
end Structural;