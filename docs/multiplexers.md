# Multiplexers — the four mux modules

> Everything under `src/mux/`: the 8-to-1 single-bit mux, the 8-way
> 4-bit mux (used twice as the ALU operand selectors), and the two
> 2-way muxes added in this revision.

---

## 1. Why three sizes?

Fig. 1 of the lab handout shows three different multiplexer shapes:

| Use | Shape | File |
|---|---|---|
| Pick PC+1 vs jump address (PC-source mux) | 2-way 3-bit | `Mux_2_3.vhd` |
| Pick ALU output vs immediate (data-bus mux) | 2-way 4-bit | `Mux_2_4.vhd` |
| Pick one of 8 register values for ALU operand A or B | 8-way 4-bit | `MUX_8_4.vhd` |

The `MUX_8_4` is itself built from four single-bit `Mux_8_to_1`s.

---

## 2. `Mux_8_to_1.vhd` — single-bit 8-to-1

Implementation is decoder-based (cheap and uniform):

```
decoded(7..0) = Decoder_3_to_8(S, EN)        -- one-hot mask, gated by EN
masked(i)     = D(i) AND decoded(i)          -- mask each data line
Y             = OR-reduction of masked(7..0) -- combine
```

When `EN = '0'`, `decoded` is all zeros, so all `masked` bits are
zero, so `Y = '0'`. That is the standard "tri-state-equivalent" behaviour
the lab handout describes.

| Port | Width | Description |
|---|---|---|
| `S` | 3 | select |
| `D` | 8 | 8 single-bit data inputs |
| `EN` | 1 | enable; output forced to 0 when low |
| `Y` | 1 | selected (and AND-gated) bit |

---

## 3. `MUX_8_4.vhd` — 8-way 4-bit

Built as **four parallel `Mux_8_to_1` instances**, one per bit-plane.
The trick is to *transpose* the 8 input words: rather than feeding each
mux a sliced word, we collect bit `b` from every input into a single
8-wide vector and hand that to the bit-`b` mux.

```vhdl
gen_mux : for b in 0 to 3 generate
    Mux_In(b) <= D(7)(b) & D(6)(b) & D(5)(b) & D(4)(b)
               & D(3)(b) & D(2)(b) & D(1)(b) & D(0)(b);

    mux_inst : entity work.Mux_8_to_1
        port map (S => S, D => Mux_In(b), EN => EN, Y => Y_int(b));
end generate;
```

| Port | Width | Description |
|---|---|---|
| `S` | 3 | which of the 8 sources to forward |
| `D` | `data_buses` (8 × 4 bits) | the 8 register outputs |
| `EN` | 1 | gates the entire 4-bit output |
| `Y` | 4 | selected register value |

### 3.1 What changed from the old version

The old `MUX_8_4` referenced types `buses_8_4` and `buses_4_8` that
were not defined in `packages/buses.vhd`. The fix renames `buses_8_4`
to the already-defined `data_buses` (same underlying type), and adds
`buses_4_8` to the package as the bit-plane bundle. The mux now
compiles standalone.

---

## 4. `Mux_2_3.vhd` — 2-way 3-bit (PC-source mux) — NEW

This was missing from the old project. It is the small mux at the
bottom of Fig. 1 that picks between PC+1 (from the 3-bit adder) and a
jump target (from the instruction decoder).

```vhdl
not_S <= not S;
gen_bit : for i in 0 to 2 generate
    Y(i) <= (D0(i) and not_S) or (D1(i) and S);
end generate;
```

| `S` | Output |
|---|---|
| `'0'` | `Y = D0`  (PC + 1, normal sequential flow) |
| `'1'` | `Y = D1`  (jump address from `JZR`) |

Cost: 3 × (2 AND + 1 OR) + 1 shared NOT = 9 gates + 1 NOT.

---

## 5. `Mux_2_4.vhd` — 2-way 4-bit (data-bus mux) — NEW

Also missing from the old project. This is the **"Immediate value Mux"**
labelled in Fig. 1, sitting on the Data Bus.

```vhdl
not_S <= not S;
gen_bit : for i in 0 to 3 generate
    Y(i) <= (D0(i) and not_S) or (D1(i) and S);
end generate;
```

| `S` | Output |
|---|---|
| `'0'` | `Y = D0`  (ALU output — for `ADD` and `NEG`) |
| `'1'` | `Y = D1`  (immediate — for `MOVI`) |

`S` comes from the decoder's `load_sel` line.

Cost: 4 × (2 AND + 1 OR) + 1 shared NOT = 12 gates + 1 NOT.

### 5.1 Why dataflow style?

Both 2-way muxes are written in dataflow style (a `for-generate` over
boolean equations) rather than as `with-select` or a process. This makes
the gate count audible from a glance — useful for the "least-gate-count"
extra-credit category in Step 5 of the lab.

---

## 6. Why no tri-state buffer alternative?

The lab handout offers tri-state buffers as an alternative to the
8-way muxes. We deliberately stick with the decoder-and-AND-OR approach
because:

* Xilinx 7-series fabric (the Basys 3's Artix-7) has *no* internal
  tri-state buffers. Vivado would synthesise tri-states into a mux
  anyway, hiding the design intent.
* Decoder + AND-mask + OR-reduce is the same primitive at every layer
  of the design (the same shape gives us the 3-to-8 decoder, the
  8-to-1 mux, and the register-bank gating), so there's only one
  pattern to reason about.

---

## 7. Connection summary

| Mux instance | Width | Where it sits |
|---|---|---|
| `Mux_8_4` "A" | 8-way 4-bit | Picks ALU operand A from the 8 register outputs |
| `Mux_8_4` "B" | 8-way 4-bit | Picks ALU operand B from the 8 register outputs |
| `Mux_2_4` (data-bus) | 2-way 4-bit | Picks ALU output vs immediate for the Data Bus |
| `Mux_2_3` (PC-source) | 2-way 3-bit | Picks PC+1 vs jump target for the next PC |
