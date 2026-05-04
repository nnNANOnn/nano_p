----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/29/2026 09:43:12 PM
-- Design Name: 
-- Module Name: buses - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package buses is

    subtype data_bus is STD_LOGIC_VECTOR(3 downto 0);
    subtype register_address is STD_LOGIC_VECTOR(2 downto 0);
    type data_buses is array (0 to 7) of data_bus;

end package buses;

package body buses is
end package body buses;
