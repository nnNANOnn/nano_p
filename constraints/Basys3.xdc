## ----------------------------------------------------------------------------
## Basys 3 Pin Constraints for the Nanoprocessor (Lab 9-10, CS1050)
##
## Top-level entity expected: Nanoprocessor
##   ports: Clk_100MHz, Reset_Btn,
##          Result_LED(3:0), Zero_LED, Carry_LED,
##          Cathodes(6:0), Anodes(3:0)
##
## Pin assignments are taken from the official Basys 3 master XDC.
## ----------------------------------------------------------------------------

## Clock signal: 100 MHz oscillator on pin W5
set_property PACKAGE_PIN W5  [get_ports Clk_100MHz]
    set_property IOSTANDARD LVCMOS33 [get_ports Clk_100MHz]
    create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports Clk_100MHz]

## Reset push-button: BTNC (centre push-button, pin U18)
set_property PACKAGE_PIN U18 [get_ports Reset_Btn]
    set_property IOSTANDARD LVCMOS33 [get_ports Reset_Btn]

## R7 -> LD0..LD3
set_property PACKAGE_PIN U16 [get_ports {Result_LED[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Result_LED[0]}]
set_property PACKAGE_PIN E19 [get_ports {Result_LED[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Result_LED[1]}]
set_property PACKAGE_PIN U19 [get_ports {Result_LED[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Result_LED[2]}]
set_property PACKAGE_PIN V19 [get_ports {Result_LED[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Result_LED[3]}]

## Zero flag -> LD14 (pin P1)
set_property PACKAGE_PIN P1  [get_ports Zero_LED]
    set_property IOSTANDARD LVCMOS33 [get_ports Zero_LED]

## Carry / Overflow flag -> LD15 (pin L1)
set_property PACKAGE_PIN L1  [get_ports Carry_LED]
    set_property IOSTANDARD LVCMOS33 [get_ports Carry_LED]

## 7-segment display segments (active low)
##  Cathodes(6) = a, ... , Cathodes(0) = g
set_property PACKAGE_PIN W7  [get_ports {Cathodes[6]}]   ;# CA
    set_property IOSTANDARD LVCMOS33 [get_ports {Cathodes[6]}]
set_property PACKAGE_PIN W6  [get_ports {Cathodes[5]}]   ;# CB
    set_property IOSTANDARD LVCMOS33 [get_ports {Cathodes[5]}]
set_property PACKAGE_PIN U8  [get_ports {Cathodes[4]}]   ;# CC
    set_property IOSTANDARD LVCMOS33 [get_ports {Cathodes[4]}]
set_property PACKAGE_PIN V8  [get_ports {Cathodes[3]}]   ;# CD
    set_property IOSTANDARD LVCMOS33 [get_ports {Cathodes[3]}]
set_property PACKAGE_PIN U5  [get_ports {Cathodes[2]}]   ;# CE
    set_property IOSTANDARD LVCMOS33 [get_ports {Cathodes[2]}]
set_property PACKAGE_PIN V5  [get_ports {Cathodes[1]}]   ;# CF
    set_property IOSTANDARD LVCMOS33 [get_ports {Cathodes[1]}]
set_property PACKAGE_PIN U7  [get_ports {Cathodes[0]}]   ;# CG
    set_property IOSTANDARD LVCMOS33 [get_ports {Cathodes[0]}]

## 7-segment display digit selects (active low)
set_property PACKAGE_PIN U2  [get_ports {Anodes[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Anodes[0]}]
set_property PACKAGE_PIN U4  [get_ports {Anodes[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Anodes[1]}]
set_property PACKAGE_PIN V4  [get_ports {Anodes[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Anodes[2]}]
set_property PACKAGE_PIN W4  [get_ports {Anodes[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Anodes[3]}]

## Configuration voltage and bitstream options
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
