-------------------------------------------------------------------------------
-- Title      : FP_Extender_array
-- Project    : MAC Cell / Neural Network Accelerator
-- File       : FP_Extender_array.vhdl
-- Author     : Laura Korycka
-- Description:
--   This module implements a vectorized fixed-point sign-extension block.
--   It instantiates an array of FP_Extender components using a generate
--   statement, allowing parallel conversion of multiple fixed-point input
--   values from a narrower Q-format to a wider Q-format. Each input element
--   is independently extended and mapped to the corresponding output element.
--   The module operates purely combinationally.
--
-- Generics:
--   INPUT_SIZE          - Number of elements in the input and output arrays.
--   IN_INTEGER_PART     - Number of integer bits in the input Q-format.
--   IN_FRACTIONAL_PART  - Number of fractional bits in the input Q-format.
--   OUT_INTEGER_PART    - Number of integer bits in the output Q-format.
--   OUT_FRACTIONAL_PART - Number of fractional bits in the output Q-format.
--
-- Ports:
--   i_a : Input array of fixed-point values in input Q-format
--         QFormat_Array(INPUT_SIZE)(IN_INTEGER_PART+IN_FRACTIONAL_PART).
--   o_y : Output array of fixed-point values in output Q-format
--         QFormat_Array(INPUT_SIZE)(OUT_INTEGER_PART+OUT_FRACTIONAL_PART).
--
-- Notes:
--   - The QFormat_Array type is defined as an array of QFormat elements.
--   - Each array element is independently extended using a dedicated instance
--     of the FP_Extender component generated in a for-generate loop.
--   - The module is fully combinational and does not require a clock or reset.
--
-- Revision history:
--   30-11-2025 : Initial version
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Types.all;

entity FP_Extender_array is
    generic (
        INPUT_SIZE          : integer := 4;
        IN_INTEGER_PART    : integer := 4;
        IN_FRACTIONAL_PART : integer := 4;
        OUT_INTEGER_PART   : integer := 8;
        OUT_FRACTIONAL_PART: integer := 8
    );
    port (
        i_clk : in std_logic;
        i_rstn : in std_logic;
        i_data     : in QFormat_Array(INPUT_SIZE - 1 downto 0)(IN_INTEGER_PART + IN_FRACTIONAL_PART - 1 downto 0);
        i_valid : in std_logic;
        o_data     : out QFormat_Array(INPUT_SIZE - 1 downto 0)(OUT_INTEGER_PART + OUT_FRACTIONAL_PART - 1 downto 0);
        o_ready : out std_logic
    );
end entity FP_Extender_array;

architecture FP_Extender_array_arch of FP_Extender_array is

    component FP_Extender is
    generic (
        IN_INTEGER_PART    : integer := 4;
        IN_FRACTIONAL_PART : integer := 4;
        OUT_INTEGER_PART   : integer := 8;
        OUT_FRACTIONAL_PART: integer := 8
    );
    port (
        i_clk : in std_logic;
        i_rstn : in std_logic;
        i_data : in QFormat((IN_INTEGER_PART+IN_FRACTIONAL_PART-1) downto 0);
        i_valid : in std_logic;
        o_data : out QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
        o_ready : out std_logic
    );
    end component FP_Extender;


    signal s_ready : std_logic_vector(INPUT_SIZE - 1 downto 0);

begin
    EXTENDER_GEN : for i in 0 to INPUT_SIZE - 1 generate
        EXT_INST: FP_Extender 
        generic map (
            IN_INTEGER_PART     => IN_INTEGER_PART,
            IN_FRACTIONAL_PART  => IN_FRACTIONAL_PART,
            OUT_INTEGER_PART    => OUT_INTEGER_PART,
            OUT_FRACTIONAL_PART => OUT_FRACTIONAL_PART
        )
        port map (
            i_clk => i_clk,
            i_rstn => i_rstn,
            i_data => i_data(i),
            i_valid => i_valid,
            o_data => o_data(i),
            o_ready => s_ready(i)
        );
    end generate EXTENDER_GEN;
    
    o_ready <= s_ready(0);


end architecture FP_Extender_array_arch;