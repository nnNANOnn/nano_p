# Clock Divider and I/O — `Clock_Divider`, `Seven_Seg_Driver`, Basys 3 pinout

> The glue between the nanoprocessor's bus-level signals and the
> physical Basys 3 board. Covers the slow-clock generator, the
> 7-segment display driver, and the constraint file.

---

## 1. Why we need a slow clock

The Basys 3 ships with a 100 MHz crystal oscillator. If we drove the
PC and Register Bank with that, an entire 8-instruction program would
finish in ~80 ns — invisible to a human.

Step 5 of the lab handout says: *"reduce the clock rate such that it
ticks every 2 or 3 seconds"*. That is what `Clock_Divider` does.

---

## 2. `Clock_Divider.vhd`

```vhdl
entity Clock_Divider is
    generic ( DIV_LIMIT : integer := 100_000_000 );
    Port (
        Clk_in   : in  STD_LOGIC;
        Res      : in  STD_LOGIC;
        Slow_Clk : out STD_LOGIC
    );
end Clock_Divider;
```

A 28-bit counter ticks up every input cycle. When the count reaches
`DIV_LIMIT - 1`, the counter resets and an internal `toggle` flip-flop
inverts. `Slow_Clk` follows `toggle`.

```
slow_clock_period = 2 * DIV_LIMIT * clk_in_period
                  = 2 * 100_000_000 * 10 ns
                  = 2 seconds
```

To get a 3-second period, set `DIV_LIMIT = 150_000_000`. The 28-bit
counter is wide enough for any value up to ~268 M (i.e. periods up
to ~5.4 sec at 100 MHz).

### 2.1 Reset behaviour

`Res` is asynchronous. When asserted, the counter and toggle both
clear to 0, so the slow clock immediately goes low and stays there
until reset is released. This guarantees the PC and bank see a clean
reset pulse before their first rising edge.

### 2.2 Simulation tip

`Nanoprocessor_tb.vhd` already overrides the DUT's `DIV_LIMIT`
generic to `5`, so the slow clock cycles every 100 ns of simulation
time and the Step-4 program finishes in ~1.6 µs.  Hardware synthesis
uses the default `DIV_LIMIT = 100_000_000` automatically — no manual
action.

---

## 3. `Seven_Seg_Driver.vhd`

Drives a single digit of the Basys 3 4-digit common-anode 7-segment
display.

```vhdl
entity Seven_Seg_Driver is
    Port (
        Value    : in  STD_LOGIC_VECTOR(3 downto 0);
        Cathodes : out STD_LOGIC_VECTOR(6 downto 0);
        Anodes   : out STD_LOGIC_VECTOR(3 downto 0)
    );
end Seven_Seg_Driver;
```

`Anodes` are wired to `"1110"`, lighting up only AN0 (the rightmost
digit). The other three digits stay dark. The cathodes are driven by
a hex-to-segment lookup; segment-on means `'0'` (active low).

| `Value` | digit |
|---|---|
| `0000` | `0` |
| `0001` | `1` |
| `0010` | `2` |
| ... | ... |
| `1111` | `F` |

For the Step-4 program, the final value of R7 is `0110` = `6`, which
displays as the digit `6`.

### 3.1 Why a single digit is enough

The result register is 4 bits, so its full range fits in a single hex
digit. If you extend the design to wider results, swap this driver for
a multiplexed 4-digit version (toggle one `Anodes` bit per millisecond
and update `Cathodes` to match) — the same underlying lookup table.

---

## 4. Output wiring (Step 5 of the lab)

In `Nanoprocessor.vhd`:

```vhdl
Result_LED <= Reg_Outputs(7);              -- R7 → LD0..LD3
Zero_LED   <= ALU_zero;                    -- LD14
Carry_LED  <= ALU_overflow;                -- LD15

seven_seg : entity work.Seven_Seg_Driver
    port map (
        Value    => Reg_Outputs(7),
        Cathodes => Cathodes,
        Anodes   => Anodes
    );
```

Step 5 in the lab handout asked specifically for: result on LD0..LD3
and on the 7-segment display, zero flag on LD14, carry flag on LD15.

> The lab calls LD15 "carry". Strictly speaking, the ALU's
> `OverFlow` output is the *signed* overflow flag (carry-into-MSB XOR
> carry-out-of-MSB) — for a 2's-complement processor, this is the
> right indicator of an arithmetic problem. We connect it to LD15.

---

## 5. `constraints/Basys3.xdc` — pin assignments

The constraint file maps every top-level port to a physical pin and
declares the input clock:

| Top-level port | Basys 3 net | Pin |
|---|---|---|
| `Clk_100MHz` | system clock | W5 |
| `Reset_Btn` | BTNC (centre) | U18 |
| `Result_LED[0..3]` | LD0..LD3 | U16, E19, U19, V19 |
| `Zero_LED` | LD14 | P1 |
| `Carry_LED` | LD15 | L1 |
| `Cathodes[6..0]` | CA, CB, CC, CD, CE, CF, CG | W7, W6, U8, V8, U5, V5, U7 |
| `Anodes[0..3]` | AN0..AN3 | U2, U4, V4, W4 |

Vivado will synthesise and implement against these pin assignments,
producing a `.bit` file you can program into the Basys 3 over USB.

### 5.1 Why `IOSTANDARD LVCMOS33`?

The Basys 3 is a 3.3 V CMOS board across the user-facing banks.
`LVCMOS33` matches that, and is the standard chosen by Digilent's
official master XDC.

---

## 6. End-to-end flow on the board

1. Power up the Basys 3 → `Clk_100MHz` runs at 100 MHz.
2. Press **BTNC** → `Reset_Btn = '1'` for as long as you hold it.
   * The clock divider's counter clears.
   * The PC clears to `000`.
   * Every register in the bank clears to `0000`.
3. Release BTNC → roughly 1 second later (`DIV_LIMIT = 100M`),
   `Slow_Clk` rises for the first time. The PC steps to `001`,
   the first instruction (`MOVI R7, 0`) executes, and R7 latches
   to `0000` (no visible change yet).
4. Each subsequent slow-clock tick advances the program by one
   instruction, so the LEDs update every second.
5. Around tick 12, R7 reaches `0110` and the program parks itself
   at address 6 in the self-loop. R7 stays at `6` forever.

Press BTNC again to restart from scratch.
