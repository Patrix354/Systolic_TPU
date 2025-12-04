-------------------------------------------------------------------------------
-- Title      : FP_Mul
-- Project    : MAC Cell / Neural Network Accelerator
-- File       : FP_Mul.vhdl
-- Author     : Laura Korycka
-- Description:
--   This module implements a synchronous fixed-point multiplier operating
--   on signed Q-format operands. The multiplication is performed on the
--   rising edge of the clock and the result is registered at the output.
--   When active-low reset (i_rstn = '0') is asserted, the output register
--   is cleared.
--
-- Generics:
--   INTEGER_PART    - Number of integer bits in the input Q-format.
--   FRACTIONAL_PART - Number of fractional bits in the input Q-format.
--
-- Ports:
--   i_clk : Clock input; multiplication occurs on the rising edge.
--   i_rstn: Active-low reset; clears the output register.
--   i_a   : First input operand in QFormat(INTEGER_PART+FRACTIONAL_PART).
--   i_b   : Second input operand in QFormat(INTEGER_PART+FRACTIONAL_PART).
--   o_y   : Output product in extended Q-format with doubled bit width:
--           QFormat(2*(INTEGER_PART+FRACTIONAL_PART)).
--
-- Notes:
--   - The QFormat type is defined as a subtype of 'signed'.
--   - The result width is doubled to preserve full multiplication precision.
--   - No rounding or saturation is applied to the output.
--   - The result is purely registered and updated every clock cycle when
--     reset is deasserted.
--
-- Revision history:
--   30-11-2025 : Initial version
-------------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Types.all;

entity FP_Mul is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;

        i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);

        o_y     : out QFormat( 2 * (INTEGER_PART + FRACTIONAL_PART) - 1 downto 0)
    );
end entity;

architecture FP_Mul_arch of FP_Mul is 
begin
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                o_y <= (others => '0');
            else
                o_y <= i_a * i_b;
            end if;
        end if;

    end process;

end architecture;