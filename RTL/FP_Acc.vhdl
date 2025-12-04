-------------------------------------------------------------------------------
-- Title      : FP_Acc
-- Project    : MAC Cell / Neural Network Accelerator
-- File       : FP_Acc.vhdl
-- Author     : Laura Korycka
-- Description:
--   This module implements a synchronous fixed-point accumulator. Incoming
--   operands in a configurable input Q-format are sign-extended to the wider
--   output Q-format by the FP_Extender and then accumulated using a
--   synchronous fixed-point adder (FP_Add). The accumulation is gated by an
--   enable signal (i_en). When the zero signal (i_zero) is asserted the
--   accumulator input is replaced with zero, effectively clearing the
--   accumulated value on the next addition. The accumulator and its outputs
--   are synchronous to the clock; when active-low reset (i_rstn = '0') is
--   asserted, the output is cleared to zero.
--
-- Generics:
--   IN_INTEGER_PART     - Number of integer bits in the input Q-format.
--   IN_FRACTIONAL_PART  - Number of fractional bits in the input Q-format.
--   OUT_INTEGER_PART    - Number of integer bits in the internal/output Q-format.
--   OUT_FRACTIONAL_PART - Number of fractional bits in the internal/output Q-format.
--
-- Ports:
--   i_clk  : Clock input; accumulation and synchronous add occur on rising edge.
--   i_rstn : Active-low reset; clears internal registers and output.
--   i_en   : Accumulate enable; when '1' the previous accumulator value is
--            fed to the adder (allows accumulation). When '0' accumulation is
--            inhibited (adder receives zero as the previous value).
--   i_zero : Zero input qualifier; when '1' the extended input is replaced by
--            zero for the current accumulation (used to clear or mask input).
--   i_data : Input operand in input QFormat(IN_INTEGER_PART+IN_FRACTIONAL_PART).
--   o_data : Accumulated output in output QFormat(OUT_INTEGER_PART+OUT_FRACTIONAL_PART).
--
-- Notes:
--   - The QFormat type is defined as a subtype of 'signed' and represents
--     fixed-point numbers in Q(INTEGER_PART.FRACTIONAL_PART) format.
--   - Input data is sign-extended to the output width by the FP_Extender
--     component (s_ext_data) before being supplied to the adder.
--   - The adder component FP_Add (ACC_SUM_CELL) performs the synchronous
--     addition and registers the result in s_acc_data which drives o_data.
--   - Internal signals:
--       s_ext_data : Extended input in output Q-format.
--       s_acc_data : Current accumulator value (registered).
--       s_a        : Adder operand A (either extended input or zero).
--       s_b        : Adder operand B (either previous accumulator or zero).
--   - Reset behavior: when i_rstn = '0', o_data and internal control signals
--     are driven to zero.
--
-- Revision history:
--   30-11-2025 : Initial version
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Types.all;

entity FP_Acc is
    generic (
        IN_INTEGER_PART    : integer := 4;
        IN_FRACTIONAL_PART : integer := 4;
        OUT_INTEGER_PART   : integer := 8;
        OUT_FRACTIONAL_PART: integer := 8
    );
    port (
        i_clk  : in std_logic;
        i_rstn  : in std_logic;
        i_en   : in std_logic;
        i_zero : in std_logic;
        i_data : in QFormat((IN_INTEGER_PART+IN_FRACTIONAL_PART-1) downto 0);
        o_data : out QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0)
    );
end entity FP_Acc;

architecture FP_Acc_arch of FP_Acc is

    signal s_ext_data   : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
    signal s_acc_data   : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
    signal s_a      : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
    signal s_b      : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
    signal s_en     : std_logic;
    signal s_zero   : std_logic;

    component FP_Add is
        generic (
            INTEGER_PART    : integer := OUT_INTEGER_PART;
            FRACTIONAL_PART : integer := OUT_FRACTIONAL_PART
        );
        port (
            i_clk   : in std_logic;
            i_rstn   : in std_logic;
            i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
            i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
            o_y     : out QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0)
        );
    end component;

    component FP_Extender is
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
    end component;

begin

    s_en <= i_en when i_rstn = '1' else '0';
    s_zero <= i_zero when i_rstn = '1' else '0';
    o_data <= s_acc_data when i_rstn = '1' else (others => '0');
    s_a <= s_ext_data when s_zero = '0' else (others => '0');
    s_b <= s_acc_data when s_en = '1' else (others => '0');

    ACC_SUM_CELL: FP_Add
         generic map(
             INTEGER_PART => OUT_INTEGER_PART,
             FRACTIONAL_PART => OUT_FRACTIONAL_PART
         )
         port map(
             i_clk => i_clk,
             i_rstn => i_rstn,
             i_a => s_a,
             i_b => s_b,
             o_y => s_acc_data
         );

    SIGNED_EXT: FP_Extender 
        generic map(
            IN_INTEGER_PART    => IN_INTEGER_PART,
            IN_FRACTIONAL_PART => IN_FRACTIONAL_PART,
            OUT_INTEGER_PART    => OUT_INTEGER_PART,
            OUT_FRACTIONAL_PART => OUT_FRACTIONAL_PART
        )
        port map(
            i_data => i_data,
            o_data => s_ext_data

        );

end architecture FP_Acc_arch;