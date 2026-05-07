# Register Bank — `Register_Bank`, `Reg`, and decoders

> The 8 × 4-bit register file of the nanoprocessor, plus its support
> components (the generic N-bit register, the 2-to-4 decoder used inside
> the 3-to-8 decoder, and the 3-to-8 decoder itself).

---

## 1. Overview

The register bank holds the architectural state visible to the
programmer:

| Register | Role | Writable |
|---|---|---|
| `R0` | Constant zero. Required by `NEG` (so the ALU can compute `0 − R`) and by `JZR R0, d` (to make an unconditional jump). | **No** |
| `R1`..`R6` | General-purpose 4-bit registers. | Yes |
| `R7` | General-purpose, also wired to LD0..LD3 and the 7-segment display so the program's final result is visible. | Yes |

All 8 register outputs are exposed simultaneously on `Data_Buses`, so
the two 8-way 4-bit muxes downstream can read any pair without
arbitration.

---

## 2. `Register_Bank.vhd`

```vhdl
entity Register_Bank is
    Port (
        Reg_En     : in  register_address;   -- 3-bit destination select
        Write_En   : in  STD_LOGIC;          -- master write-enable from decoder
        Res        : in  STD_LOGIC;          -- async reset
        Clk        : in  STD_LOGIC;
        Data       : in  data_bus;           -- 4-bit value to write
        Data_Buses : out data_buses          -- all 8 register outputs
    );
end Register_Bank;
```

Internally:

* A 3-to-8 decoder takes `Reg_En` as its address and `Write_En` as its
  enable. When `Write_En = '0'`, every output of the decoder is `'0'`,
  so no `En` line in the bank is high and no register can latch. When
  `Write_En = '1'`, exactly one of the 8 outputs is high — the one
  corresponding to `Reg_En`.
* `R0` is hardwired: `Data_Buses(0) <= "0000";` — it has no
  flip-flops at all. Writes addressed to `R0` are silently discarded.
* `R1..R7` are seven instances of the generic `Reg N=4`, all sharing
  `Data`, `Res`, `Clk`. Their `En` lines come from the decoder.

### 2.1 What changed from the old version

The old `Register_Bank` had no `Write_En` port. Its internal decoder
was hardwired with `EN => '1'`, so the decoder *always* enabled some
register. That meant `JZR` could not be a no-op — every cycle, the
register at `Reg_En` would latch whatever was on the data bus.

This new version connects the decoder's `EN` to the new `Write_En`
input, which the top-level wires to the Instruction Decoder's
`reg_write_en`. Now:

* `MOVI`, `ADD`, `NEG` → `reg_write_en = '1'` → bank writes.
* `JZR` → `reg_write_en = '0'` → bank does **not** write.

### 2.2 Read-only R0 — implementation note

The simplest implementation is to drop the flip-flops entirely:

```vhdl
Data_Buses(0) <= "0000";
```

The previous version instead built a real register with `D = "0000"`
and `En = '1'`. Both approaches produce the same observable behaviour,
but the constant-driver form synthesises to **zero gates** (just a tie
to ground), saving four flip-flops.

---

## 3. `Reg.vhd` — the generic N-bit register

```vhdl
entity Reg is
    generic (N : integer := 4);
    Port (D, Q : ...; Res, En, Clk : in STD_LOGIC);
end Reg;
```

`Reg` is a thin wrapper around `N` `D_FF` instances using
`for-generate`. All flip-flops share the same `Res`, `En`, `Clk`.
`Qbar` of each `D_FF` is mapped to `open` because the bank does not
need it.

This entity is reused by **both** the register bank (with `N = 4`) and
the program counter (with `N = 3`).

---

## 4. `Decoder_3_to_8.vhd` — the 3-to-8 decoder

Built hierarchically from two `Decoder_2_to_4` instances, with the
high address bit `I(2)` selecting which of the two halves is enabled.

```
EN0 = (NOT I2) AND EN     -> enables the lower 4 outputs
EN1 = I2       AND EN     -> enables the upper 4 outputs
Y(3..0) = Decoder_2_to_4(I(1..0), EN0)
Y(7..4) = Decoder_2_to_4(I(1..0), EN1)
```

When `EN = '0'`, both halves are disabled and `Y(7..0) = "00000000"`.
This is exactly the behaviour the register bank's `Write_En` relies on.

| Port | Width | Description |
|---|---|---|
| `I` | 3 | input address |
| `EN` | 1 | enable, gates the entire output |
| `Y` | 8 | one-hot output (zero when `EN = '0'`) |

### 4.1 `Decoder_2_to_4.vhd` (helper)

Pure combinational decoder. Each output is the AND of one input pattern
with `EN`:

```
Y(0) = NOT I(0) AND NOT I(1) AND EN
Y(1) =     I(0) AND NOT I(1) AND EN
Y(2) = NOT I(0) AND     I(1) AND EN
Y(3) =     I(0) AND     I(1) AND EN
```

Used in two places: inside `Decoder_3_to_8`, and inside the 8-to-1 mux
(see `multiplexers.md`).

---

## 5. Tying it to the rest of the design

In `Nanoprocessor.vhd`:

```vhdl
rb_inst : entity work.Register_Bank
    port map (
        Reg_En     => reg_en_sel,     -- from instruction decoder
        Write_En   => reg_write_en,   -- gated by opcode
        Res        => Reset_Btn,
        Clk        => Slow_Clk,
        Data       => Data_Bus,       -- from data-bus mux
        Data_Buses => Reg_Outputs     -- to MUX_8_4 A and B + R7 to LEDs
    );
```

The eight outputs in `Reg_Outputs` feed both 8-way 4-bit muxes
simultaneously, so an instruction can read any two registers in one
cycle.

---

## 6. Verifying it

`sim/tb_Register_Bank.vhd` exercises the bank with:

1. Async reset zeroing all registers
2. A write to R0 (verifies it stays 0)
3. Writes to R1, R2, R3, R7 (verifies they latch)
4. Toggling `Write_En = '0'` (verifies that no register changes when
   write is disabled)

Run it as a behavioral simulation in Vivado and watch
`Data_Buses(0)..Data_Buses(7)` in the waveform viewer.
