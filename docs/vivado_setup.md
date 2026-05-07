# Vivado Project Setup Guide — Nanoprocessor

> Step-by-step instructions for turning the `nano_p/` repository into a
> working Vivado project that synthesises, implements, and programs onto
> a Digilent Basys 3 board.

This guide assumes Vivado 2024.x or 2025.x. Older versions (≥ 2018.2)
will work but the menu names may differ slightly.

---

## Table of Contents

1. [Before you start](#1-before-you-start)
2. [Create the Vivado project](#2-create-the-vivado-project)
3. [Add the design sources](#3-add-the-design-sources)
4. [Add the simulation sources](#4-add-the-simulation-sources)
5. [Add the constraint file](#5-add-the-constraint-file)
6. [Set the top-level entity](#6-set-the-top-level-entity)
7. [Compile order](#7-compile-order)
8. [Run synthesis and implementation](#8-run-synthesis-and-implementation)
9. [Generate the bitstream](#9-generate-the-bitstream)
10. [Program the Basys 3 board](#10-program-the-basys-3-board)
11. [Common errors and fixes](#11-common-errors-and-fixes)
12. [Optional: Vivado project as a reproducible script](#12-optional-vivado-project-as-a-reproducible-script)

---

## 1. Before you start

You need:

* **Vivado** (Standard or Enterprise, free webpack edition is fine).
* **Digilent board files** installed — see Digilent's "Vivado Board
  Files for Digilent FPGAs" guide. These let you select "Basys 3" from
  the boards list rather than hand-typing the part number.
* The `nano_p/` repository checked out somewhere (the path must contain
  no spaces if you're on Windows, otherwise Vivado occasionally chokes).

You **don't** need:

* Any extra IP cores. Everything is plain VHDL.
* MicroBlaze or any soft processor IP. The nanoprocessor is the entire
  CPU.

Open Vivado before continuing.

---

## 2. Create the Vivado project

1. **File → Project → New…** (or click *Create Project* on the home
   screen).
2. Click **Next**.
3. **Project name**: `nano_p_vivado`. **Project location**: pick a
   folder *outside* the `nano_p/` repo — say `~/projects/`. The reason:
   Vivado will dump dozens of generated files; you don't want them
   polluting the repo.
4. **Next**. **Project type**: select *RTL Project*. **Untick** "Do not
   specify sources at this time" (you will add them shortly).
5. **Next**. **Add Sources**: just click **Next** here — we'll add
   sources after the project is created so we can preview the order.
6. **Next**. **Add Constraints**: same — skip and add later.
7. **Next**. **Default Part**:
   * Click the **Boards** tab.
   * Filter by *Basys3*. Select **Basys3** (vendor: digilentinc.com).
   * If Basys 3 is not in the list, install the Digilent board files
     and restart Vivado.
   * Alternative: under *Parts*, manually pick `xc7a35tcpg236-1`.
8. **Next** → **Finish**.

Vivado now opens an empty project with no sources.

---

## 3. Add the design sources

1. In the *Sources* pane (top-left), right-click **Design Sources** →
   **Add Sources…**.
2. Choose **Add or create design sources** → **Next**.
3. Click **Add Files…** and navigate to the `nano_p/` repo.
4. Add **every** file under these paths:

   ```
   packages/buses.vhd
   packages/adders.vhd

   src/arithmetic_unit/HA.vhd
   src/arithmetic_unit/FA.vhd
   src/arithmetic_unit/RCA_4.vhd
   src/arithmetic_unit/Adder_3bits.vhd
   src/arithmetic_unit/AddSub_4.vhd
   src/arithmetic_unit/D_FF.vhd
   src/arithmetic_unit/PC.vhd
   src/arithmetic_unit/PC_Inc.vhd

   src/register_bank/Reg.vhd
   src/register_bank/Decoder_2_to_4.vhd
   src/register_bank/Decoder_3_8.vhd
   src/register_bank/Register_Bank.vhd

   src/mux/Mux_8_to_1.vhd
   src/mux/MUX_8_4.vhd
   src/mux/Mux_2_3.vhd
   src/mux/Mux_2_4.vhd

   src/program_rom/Program_Rom.vhd
   src/instruction_decoder/instruction_decoder.vhd

   src/io/Clock_Divider.vhd
   src/io/Seven_Seg_Driver.vhd

   src/Nanoprocessor.vhd
   ```

5. **Untick** "Copy sources into project". You want Vivado to reference
   the repo files directly so your edits in a text editor are picked
   up the next time you re-synthesise.
6. **Tick** "Add sources from subdirectories" if it isn't ticked.
7. Click **Finish**.

After this, the *Hierarchy* view should show `Nanoprocessor` at the
top, with all 17 sub-entities expanded as children.

---

## 4. Add the simulation sources

1. In the *Sources* pane, right-click **Simulation Sources** → **Add
   Sources…**.
2. Choose **Add or create simulation sources** → **Next**.
3. Click **Add Files…** and add:

   ```
   sim/Nanoprocessor_tb.vhd
   sim/instruction_decoder_tb.vhd
   sim/tb_Register_Bank.vhd
   ```

4. **Untick** "Copy sources into project".
5. **Finish**.

You can add additional component-level testbenches later (see
`docs/testing.md`); the workflow is the same.

---

## 5. Add the constraint file

1. Right-click **Constraints** → **Add Sources…** → **Add or create
   constraints** → **Next**.
2. **Add Files…** → navigate to `constraints/Basys3.xdc`.
3. **Untick** "Copy constraints into project".
4. **Finish**.

After this, the *Constraints* tree should show `Basys3.xdc`. Vivado
will use it during synthesis and implementation to map your top-level
ports to physical pins.

---

## 6. Set the top-level entity

Vivado should auto-detect `Nanoprocessor` as the top because nothing
instantiates it. To verify or override:

1. In *Sources*, switch to the **Hierarchy** tab.
2. The top-level row should show **Nanoprocessor** in **bold**.
3. If it doesn't, right-click `Nanoprocessor.vhd` → **Set as Top**.

For each individual testbench you want to simulate, follow the same
flow under **Simulation Sources** (right-click the testbench →
**Set as Top**) before launching the sim.

---

## 7. Compile order

Vivado normally figures out the compile order from package and entity
references, but you can sanity-check or manually override it:

1. **Tools → Settings → General → Compile Order → Disable
   Automatic compile order**.
2. In *Sources*, switch to the **Compile Order** tab.
3. Drag files so they appear in this order (packages first):

   ```
   buses.vhd
   adders.vhd
   HA.vhd
   FA.vhd
   RCA_4.vhd
   Adder_3bits.vhd
   AddSub_4.vhd
   D_FF.vhd
   Reg.vhd
   Decoder_2_to_4.vhd
   Decoder_3_8.vhd
   Register_Bank.vhd
   PC.vhd
   PC_Inc.vhd
   Mux_8_to_1.vhd
   MUX_8_4.vhd
   Mux_2_3.vhd
   Mux_2_4.vhd
   Program_Rom.vhd
   instruction_decoder.vhd
   Clock_Divider.vhd
   Seven_Seg_Driver.vhd
   Nanoprocessor.vhd
   ```

4. Re-enable automatic compile order if you want; once you've laid it
   out manually, Vivado remembers.

For most projects automatic order is fine — only fall back to manual
mode if you hit a "library unit not found" error.

---

## 8. Run synthesis and implementation

1. In the *Flow Navigator* (left pane), click **Run Synthesis**.
   Vivado pops a job-config dialog; the defaults are fine. Click
   **OK**.
2. Wait. On a modern laptop, synthesis takes ~30 seconds.
3. When it finishes, a dialog asks what to do next. Choose **Run
   Implementation** → **OK**.
4. Implementation typically takes another ~30 seconds.
5. Watch the *Messages* panel at the bottom. Warnings are normal;
   *errors* are not. The two types of warning you can ignore:

   * "Output port `<x>` is unused" — typically `Qbar` of a D_FF or
     `C_out` of `RCA_3`. We deliberately leave them open.
   * "Unconnected pin `EN` of `Decoder_3_to_8` driven to constant" —
     not applicable in this design but Vivado prints similar messages
     for any always-true enable.

6. Errors usually mean a typo in a port-map or a missing source file.
   See [§11 Common errors](#11-common-errors-and-fixes).

After implementation, the *Project Summary* panel shows resource
utilisation. The full nanoprocessor uses **well under 1%** of the
Artix-7's LUTs and FFs — there is enormous headroom for extensions.

---

## 9. Generate the bitstream

1. *Flow Navigator* → **Generate Bitstream**. Vivado will (silently)
   re-run synthesis and implementation if anything is stale.
2. Wait. Bitstream generation takes ~30 seconds.
3. The output `.bit` file lives at:

   ```
   nano_p_vivado/nano_p_vivado.runs/impl_1/Nanoprocessor.bit
   ```

You're now ready to program the board.

---

## 10. Program the Basys 3 board

1. Connect the Basys 3 to your PC via USB.
2. Make sure the **JP1** jumper near the USB port is set to **JTAG**
   (not QSPI) — only then does Vivado see the FPGA directly.
3. Power the board on (slide the **PWR** switch).
4. *Flow Navigator* → **Open Hardware Manager** → **Open Target** →
   **Auto Connect**. Vivado should detect `xc7a35t_0`.
5. Right-click the device → **Program Device…**. The dialog
   pre-populates with the bitstream from §9. Click **Program**.
6. Within ~3 seconds, the board's "DONE" LED lights up.
7. Press **BTNC** once to reset the nanoprocessor. The slow clock
   starts; LED LD0..LD3 will step through partial sums and stop on
   `0110` (= 6). The right-most 7-segment digit shows `6`.

> **Persistence note**: programming over JTAG is volatile. Power-cycle
> the board and the FPGA goes blank. To make the bitstream survive
> power loss, generate a `.bin` file and write it to the board's QSPI
> flash; that's a separate Vivado flow ("Generate Memory Configuration
> File") and not required for this lab.

---

## 11. Common errors and fixes

| Error message | Cause | Fix |
|---|---|---|
| `Library unit "buses" not found` | Compile order is wrong (consumer compiled before package) | Switch to manual compile order; put `buses.vhd` first |
| `formal port "Qbar" has no actual` | A `D_FF` instance left `Qbar` truly unmapped | Map `Qbar => open` explicitly |
| `[Synth 8-2576] type of "I" is incompatible with std_logic_vector` | Vivado is using an old type from the package cache | *Tools → Settings → General → Refresh*, then re-synthesise |
| `value 8 is out of bounds (1 .. 7)` at `ROM_CONTENTS(...)` | Address bus is wider than ROM | Confirm `ROM_address` is 3 bits (it is, in this revision) |
| `port "Write_En" not found in design unit` | Old testbench still drives the previous Register_Bank without `Write_En` | Use the updated `tb_Register_Bank.vhd` shipped here |
| Bitstream generation fails with `place 30-574` | At least one top-level port has no XDC mapping | Check that every port in `Nanoprocessor.vhd` is in `Basys3.xdc` |
| Board behaviour: LEDs never change | DIV_LIMIT might still be set to a tiny value (sim leftover) | Confirm `DIV_LIMIT = 100_000_000` in `Nanoprocessor.vhd`; rebuild |
| Board behaviour: LEDs cycle once and freeze on garbage | Reset polarity inverted | Check `Reset_Btn` is mapped to BTNC (active high on Basys 3) |

---

## 12. Optional: Vivado project as a reproducible script

If you want to *not* check the Vivado `.xpr` file into git (it's
binary and notorious for merge conflicts), use this `create_project.tcl`
script instead. Save it at the repo root and source it from Vivado's
Tcl console.

```tcl
# create_project.tcl -- reproduces the Vivado project from sources
create_project -force nano_p_vivado ./nano_p_vivado -part xc7a35tcpg236-1
set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]

# Design sources
add_files -norecurse {
    packages/buses.vhd
    packages/adders.vhd
    src/arithmetic_unit/HA.vhd
    src/arithmetic_unit/FA.vhd
    src/arithmetic_unit/RCA_4.vhd
    src/arithmetic_unit/Adder_3bits.vhd
    src/arithmetic_unit/AddSub_4.vhd
    src/arithmetic_unit/D_FF.vhd
    src/arithmetic_unit/PC.vhd
    src/arithmetic_unit/PC_Inc.vhd
    src/register_bank/Reg.vhd
    src/register_bank/Decoder_2_to_4.vhd
    src/register_bank/Decoder_3_8.vhd
    src/register_bank/Register_Bank.vhd
    src/mux/Mux_8_to_1.vhd
    src/mux/MUX_8_4.vhd
    src/mux/Mux_2_3.vhd
    src/mux/Mux_2_4.vhd
    src/program_rom/Program_Rom.vhd
    src/instruction_decoder/instruction_decoder.vhd
    src/io/Clock_Divider.vhd
    src/io/Seven_Seg_Driver.vhd
    src/Nanoprocessor.vhd
}
set_property top Nanoprocessor [current_fileset]

# Simulation sources
add_files -fileset sim_1 -norecurse {
    sim/Nanoprocessor_tb.vhd
    sim/instruction_decoder_tb.vhd
    sim/tb_Register_Bank.vhd
}

# Constraints
add_files -fileset constrs_1 -norecurse constraints/Basys3.xdc

# Update compile order so packages come first
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Project created. Run 'launch_runs synth_1' to start synthesis."
```

To use it:

1. Open Vivado (no project loaded).
2. **Tools → Run Tcl Script…** → pick `create_project.tcl`.
3. The project is recreated from scratch in `./nano_p_vivado/`.

This script is a perfect companion to `git`: only the source files are
versioned, never the multi-megabyte Vivado run directories.

---

## 13. Where to go next

* For component-level and end-to-end testing methodology, see
  [`docs/testing.md`](testing.md).
* For the architecture and cycle-by-cycle datapath, see
  [`docs/nanoprocessor.md`](nanoprocessor.md).
* If you want to extend the ISA, the easiest entry points are
  `src/program_rom/Program_Rom.vhd` (to write a different program)
  and `src/instruction_decoder/instruction_decoder.vhd` (to add or
  modify opcodes). Both are pure combinational; a five-line edit ships
  a new instruction.
