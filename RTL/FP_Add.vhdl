-------------------------------------------------------------------------------
-- Title      : FP_Add
-- Project    : MAC Cell
-- File       : FP_Add.vhdl
-- Author     : Laura Korycka
-- Description: 
--   This module implements a synchronous fixed-point adder operating in Q-format.
--   Both operands are represented as signed fixed-point numbers with a configurable
--   number of integer and fractional bits. The addition is performed on the rising
--   edge of the clock. When reset is active (i_rstn = '0'), the output is cleared.
--
-- Generics:
--   INTEGER_PART    - Number of integer bits in Q-format representation.
--   FRACTIONAL_PART - Number of fractional bits in Q-format representation.
--
-- Ports:
--   i_clk  : Clock input; addition occurs on rising edge.
--   i_rstn : Active-low reset; clears the output register.
--   i_a    : First operand (QFormat type).
--   i_b    : Second operand (QFormat type).
--   o_y    : Output sum (QFormat type).
--
-- Notes:
--   The QFormat type is defined as a subtype of 'signed' 
--
-- Revision history:
--   31-10-2025 : Initial version
--   11-11-2025 : Edited output length (output carry is ommited)
-------------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Types.all; 

entity FP_Add is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;

        i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);

        o_y     : out QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0)
    );
end entity;

architecture FP_Add_arch of FP_Add is 
    signal s_y  : QFormat(INTEGER_PART + FRACTIONAL_PART downto 0);
begin
    
    o_y <= s_y(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);

    process(i_clk) begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                s_y <= (others => '0');
            else
                s_y <= resize(i_a, INTEGER_PART + FRACTIONAL_PART + 1) + resize(i_b, INTEGER_PART + FRACTIONAL_PART + 1);
            end if;
        end if;

    end process;

end architecture;