# nano_p — 4-bit Nanoprocessor

A 4-bit, 4-instruction nanoprocessor implemented in VHDL for the
Digilent Basys 3 (Artix-7) board. Built for **CS1050 — Computer
Organization and Digital Design**, Lab 9-10.

## Quick start

1. Open the project in Vivado 2025.1 (or compatible).
2. Add every file under `packages/`, `src/`, `constraints/`, `sim/`
   to the project.
3. Set `Nanoprocessor` (in `src/Nanoprocessor.vhd`) as the synthesis top.
4. Run synthesis → implementation → generate bitstream → program the
   board.
5. Press **BTNC** to reset; the LEDs (LD0..LD3) and the right-most
   7-segment digit step through partial sums of `1 + 2 + 3` and stop
   at `0110` (=6).

For simulation: open `sim/Nanoprocessor_tb.vhd` and run a behavioural
simulation. The testbench already overrides `DIV_LIMIT` to `5` so the
program finishes in ~1.6 µs, and ends with an `assert` confirming
`R7 = 0110` (= 6).

## Documentation

Component-level docs live in `docs/`:

| File | Covers |
|---|---|
| [`nanoprocessor.md`](docs/nanoprocessor.md) | **Top-level integration** — start here |
| [`vivado_setup.md`](docs/vivado_setup.md) | **How to create the Vivado project** from this repo |
| [`testing.md`](docs/testing.md) | **How to test every component** (testbenches + hardware) |
| [`instruction_decoder.md`](docs/instruction_decoder.md) | The control unit |
| [`arithmetic_unit.md`](docs/arithmetic_unit.md) | HA, FA, RCAs, ALU, D_FF |
| [`program_counter.md`](docs/program_counter.md) | PC and PC_Inc |
| [`register_bank.md`](docs/register_bank.md) | The 8 × 4-bit register file |
| [`multiplexers.md`](docs/multiplexers.md) | All four mux modules |
| [`program_rom.md`](docs/program_rom.md) | The instruction memory and the Step-4 program |
| [`clock_and_io.md`](docs/clock_and_io.md) | Clock divider, 7-seg driver, Basys 3 pinout |

## ISA

| Mnemonic | Effect |
|---|---|
| `MOVI R, d` | `R ← d` (4-bit immediate) |
| `ADD Ra, Rb` | `Ra ← Ra + Rb` |
| `NEG R` | `R ← −R` (2's complement) |
| `JZR R, d` | if `R == 0` then `PC ← d` else `PC ← PC + 1` |

8 registers (R0..R7), R0 hardwired to `0000`. PC is 3 bits. Program ROM
holds 8 × 12-bit machine words.

## File layout

```
nano_p/
├── packages/
│   ├── buses.vhd            -- subtypes for D, I, M, R buses
│   └── adders.vhd           -- component declarations for the ALU primitives
├── src/
│   ├── Nanoprocessor.vhd    -- TOP LEVEL
│   ├── arithmetic_unit/     -- HA, FA, RCAs, ALU, D_FF, PC, PC_Inc
│   ├── register_bank/       -- Reg, decoders, Register_Bank
│   ├── mux/                 -- 8-to-1, 8-way 4-bit, 2-way 3-bit, 2-way 4-bit
│   ├── program_rom/         -- Program_Rom
│   ├── instruction_decoder/ -- the decoder
│   └── io/                  -- clock divider, 7-seg driver
├── constraints/Basys3.xdc   -- pin assignments
├── sim/                     -- testbenches
└── docs/                    -- component documentation
```
