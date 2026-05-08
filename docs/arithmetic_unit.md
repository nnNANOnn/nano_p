# Arithmetic Unit — Adders, ALU, and the D Flip-Flop

> Covers every component under `src/arithmetic_unit/`:
> Half Adder, Full Adder, 4-bit Ripple Carry Adder, 3-bit Ripple Carry
> Adder, the 4-bit Add/Sub ALU, and the D Flip-Flop primitive.

---

## 1. Half Adder (`HA.vhd`)

The smallest building block. Adds two single bits.

```
S = A XOR B
C = A AND B
```

| Port | Width | Direction |
|---|---|---|
| `A`, `B` | 1 | in |
| `S` (sum) | 1 | out |
| `C` (carry) | 1 | out |

Cost: 1 XOR + 1 AND.

---

## 2. Full Adder (`FA.vhd`)

Built from two half-adders plus an OR gate.

```
HA_0 : (A, B)        -> S0, C0
HA_1 : (S0, C_in)    -> S , C1
C_out = C0 OR C1
```

Truth-table identity: `S = A XOR B XOR C_in`,
`C_out = AB + (A XOR B)·C_in`. The two-HA decomposition realises this
in 2 XORs, 2 ANDs, and 1 OR (5 gates).

| Port | Width | Direction |
|---|---|---|
| `A`, `B`, `C_in` | 1 | in |
| `S`, `C_out` | 1 | out |

---

## 3. 4-bit Ripple Carry Adder (`RCA_4.vhd`)

Four FAs cascaded by their carry chain. Used by the ALU.

```
FA_0 : (A0, B0, C_in)   -> S0, c1
FA_1 : (A1, B1, c1)     -> S1, c2
FA_2 : (A2, B2, c2)     -> S2, c3
FA_3 : (A3, B3, c3)     -> S3, c_out
```

The exposed `C_in_last` output is the carry **into** the MSB FA; the
ALU XORs it with `C_out` to detect signed overflow.

| Port | Width | Description |
|---|---|---|
| `A`, `B` | 4 | operands |
| `C_in` | 1 | initial carry (also the subtract bit in the ALU) |
| `S` | 4 | sum |
| `C_out` | 1 | carry out of the MSB |
| `C_in_last` | 1 | carry into the MSB (used for overflow detection) |

---

## 4. 3-bit Ripple Carry Adder (`Adder_3bits.vhd`)

Identical structure with three FAs. Used as the **PC incrementer**:
`PC + 1` is computed by hard-wiring `B = "001"` and `C_in = '0'`.

| Port | Width | Description |
|---|---|---|
| `A`, `B` | 3 | operands |
| `C_in` | 1 | initial carry |
| `S` | 3 | sum |
| `C_out` | 1 | carry out (left `open` in PC_Inc — wraps around at 7→0) |

---

## 5. 4-bit Add/Sub Unit — the ALU (`AddSub_4.vhd`)

The arithmetic core of the nanoprocessor.

```
B' = B XOR (CTRL,CTRL,CTRL,CTRL)        -- conditional invert
S  = RCA_4(A, B', C_in = CTRL)
```

When `CTRL = 0`: `B' = B`, `C_in = 0`, result = `A + B`.
When `CTRL = 1`: `B' = ~B`, `C_in = 1`, result = `A + ~B + 1 = A − B`.

### 5.1 Flags

`Zero` is `'1'` whenever `S = "0000"`. The Instruction Decoder also has
its own zero detector for `JZR`, but the ALU's flag is exposed for
direct connection to LD14.

`OverFlow` is the standard signed-overflow indicator
`carry_into_MSB XOR carry_out_of_MSB`.

### 5.2 Why the operand polarity matters

The lab specifies `NEG R: R ← −R`. To compute that with a single ALU
that does `A − B`, the decoder routes `A = 0, B = R` and asserts
`CTRL = 1`. The ALU then produces `0 − R = −R`. If the decoder
mistakenly put `R` on `A` and `0` on `B`, the ALU would compute
`R − 0 = R` (the identity) — that bug is one of the most common
nanoprocessor failures, so this design pins down the polarity in both
this README and `instruction_decoder.md`.

### 5.3 Bug fixes from the original file

The previous version of `AddSub_4.vhd` contained `[cite:1]` markers in
three places (left over from a documentation paste). Those are not valid
VHDL and prevented compilation. The fixed file removes them and uses
clean, structural assignments.

| Port | Width | Description |
|---|---|---|
| `A_AS`, `B_AS` | 4 | operands |
| `CTRL` | 1 | `'0'` add, `'1'` subtract |
| `S_AS` | 4 | result |
| `Zero` | 1 | `'1'` if `S_AS = 0000` |
| `OverFlow` | 1 | signed-overflow flag |

---

## 6. D Flip-Flop (`D_FF.vhd`)

Single-bit storage element with synchronous load and *asynchronous-style*
reset (active high). The reset is sampled on the rising clock edge, so
in synthesis it is technically a synchronous reset.

```vhdl
process (Clk) begin
    if rising_edge(Clk) then
        if Res = '1' then
            Q <= '0';  Qbar <= '1';
        elsif En = '1' then
            Q <= D;    Qbar <= not D;
        end if;
    end if;
end process;
```

This is the *only* primitive in the project that holds state. Every
register in the bank, every bit of the PC, and every counter tap in the
clock divider is built from this same flip-flop.

| Port | Width | Description |
|---|---|---|
| `D` | 1 | data input |
| `Res` | 1 | reset (active high) |
| `Clk` | 1 | clock |
| `En` | 1 | clock-enable (load only when high) |
| `Q`, `Qbar` | 1 | true and inverted output |

