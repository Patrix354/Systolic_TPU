-------------------------------------------------------------------------------
-- Title      : FP_Extender
-- Project    : MAC Cell / Neural Network Accelerator
-- File       : FP_Extender.vhdl
-- Author     : Laura Korycka
-- Description:
--   This module implements a combinational fixed-point sign extender.
--   It converts an input fixed-point value represented in a narrower
--   Q-format into a wider Q-format while preserving the numeric value.
--   The conversion is performed by sign extension of the integer part
--   and zero-padding of the fractional part.
--
-- Generics:
--   IN_INTEGER_PART     - Number of integer bits in the input Q-format.
--   IN_FRACTIONAL_PART  - Number of fractional bits in the input Q-format.
--   OUT_INTEGER_PART    - Number of integer bits in the output Q-format.
--   OUT_FRACTIONAL_PART - Number of fractional bits in the output Q-format.
--
-- Ports:
--   i_data : Input fixed-point value in input Q-format
--            Q(IN_INTEGER_PART.IN_FRACTIONAL_PART).
--   o_data : Output fixed-point value in output Q-format
--            Q(OUT_INTEGER_PART.OUT_FRACTIONAL_PART).
--
-- Notes:
--   - The QFormat type is defined as a subtype of 'signed'.
--   - The most significant bit of the input word is used as the sign bit.
--   - For positive numbers, the integer extension is filled with zeros.
--   - For negative numbers, the integer extension is filled with ones
--     (two’s complement sign extension).
--   - The fractional part is always extended with zeros, effectively
--     increasing resolution without changing the represented value.
--   - The module is fully combinational and does not require a clock or reset.
--
-- Revision history:
--   30-11-2025 : Initial version
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Types.all;

entity FP_Extender is
    generic (
        IN_INTEGER_PART    : integer := 4;
        IN_FRACTIONAL_PART : integer := 4;
        OUT_INTEGER_PART   : integer := 8;
        OUT_FRACTIONAL_PART: integer := 8
        );
    port (
        i_data : in QFormat((IN_INTEGER_PART+IN_FRACTIONAL_PART-1) downto 0);
        o_data : out QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0)
    );
end entity FP_Extender;

architecture FP_Extender_arch of FP_Extender is

    constant s_fractional_zeros : std_logic_vector((OUT_FRACTIONAL_PART - IN_FRACTIONAL_PART - 1) downto 0) := 
    (others => '0'); 
    constant s_integer_zeros : std_logic_vector((OUT_INTEGER_PART - IN_INTEGER_PART - 1) downto 0) := 
    (others => '0'); 
    constant s_integer_ones : std_logic_vector((OUT_INTEGER_PART - IN_INTEGER_PART - 1) downto 0) := 
    (others => '1'); 
    
begin

    o_data <= QFormat(s_integer_zeros & std_logic_vector(i_data) & s_fractional_zeros) when 
    i_data(IN_INTEGER_PART+IN_FRACTIONAL_PART-1)='0' else
    QFormat(s_integer_ones & std_logic_vector(i_data) & s_fractional_zeros);

end architecture FP_Extender_arch;