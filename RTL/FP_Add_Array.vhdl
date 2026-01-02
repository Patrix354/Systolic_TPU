-------------------------------------------------------------------------------
-- Title      : FP_Add_Array
-- Project    : MAC Cell
-- File       : FP_Add_Array.vhdl
-- Author     : Laura Korycka
-- Description:
--   This module implements a fixed-point multi-input adder that reduces an
--   array of Q-format values into a single output value. Two architectural
--   variants are provided: a serial accumulator and a parallel reduction tree.
--   Both rely on FP_Add units performing synchronous fixed-point addition.
--
--   The serial architecture processes the input array element-by-element,
--   chaining FP_Add blocks so that each stage accumulates one additional input.
--   This approach minimizes resource usage at the cost of linear latency.
--
--   The parallel architecture employs FP_Add_Layer modules arranged in a
--   logarithmic-depth tree. Each layer halves the number of active operands
--   until only one result remains. This significantly reduces latency while
--   increasing hardware requirements.
--
-- Generics:
--   INTEGER_PART    - Number of integer bits in Q-format representation.
--   FRACTIONAL_PART - Number of fractional bits in Q-format representation.
--   INPUT_SIZE      - Number of input elements to be summed.
--
-- Ports:
--   i_clk  : Clock input; triggers synchronous additions.
--   i_rstn : Active-low reset; clears internal registers.
--   i_valid : Data valid signal; enables computation when high.
--   i_data : Input array of Q-format values.
--   o_data : Single Q-format output representing the accumulated sum.
--   o_ready: Ready signal output 
--
-- Notes:
--   - Both architectures rely on FP_Add as the basic fixed-point adder block.
--   - The parallel architecture assumes INPUT_SIZE is a power of two.
--   - QFormat and QFormat_Array types are defined in the package 'Types'.
-------------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.Types.all;

entity FP_Add_Array is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4;
        INPUT_SIZE      : integer := 16
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_valid : std_logic;
        i_data     : in QFormat_Array(INPUT_SIZE-1 downto 0)(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_data     : out QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_ready : out std_logic
    );
end entity FP_Add_Array;

architecture FP_Add_Array_serial_arch of FP_Add_Array is 

    component FP_Add is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_valid  : std_logic;
        i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_y     : out QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_ready : out std_logic
    );
    end component FP_Add;

    signal s_mid_results : QFormat_Array((INPUT_SIZE - 2) downto 0)(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
    signal s_ready : std_logic_vector((INPUT_SIZE-2) downto 0);
begin
    
    SERIAL_ARRAY_GEN: for i in (INPUT_SIZE-2) downto 0 generate

        FIRST_ADDER: if (i = (INPUT_SIZE-2)) generate
            FIRST_ADDER_INSTANCE: FP_Add
            generic map(
                INTEGER_PART => INTEGER_PART,
                FRACTIONAL_PART => FRACTIONAL_PART
            )
            port map(
                i_clk => i_clk,
                i_rstn => i_rstn,
                i_valid => i_valid,
                i_a => i_data(i),
                i_b => i_data(i+1),
                o_y => s_mid_results(i),
                o_ready => s_ready(i)
            );
        end generate FIRST_ADDER;

        NEXT_ADDERS: if (i /= (INPUT_SIZE-2)) generate
            NEXT_ADDER_INSTANCE: FP_Add
            generic map(
                INTEGER_PART => INTEGER_PART,
                FRACTIONAL_PART => FRACTIONAL_PART
            )
            port map(
                i_clk => i_clk,
                i_rstn => i_rstn,
                i_valid => s_ready(i+1),
                i_a => i_data(i),
                i_b => s_mid_results(i+1),
                o_y => s_mid_results(i),
                o_ready => s_ready(i)
            );
        end generate NEXT_ADDERS;

    end generate SERIAL_ARRAY_GEN;

    o_ready <= s_ready(0);
    o_data <= s_mid_results(0);

end architecture;

architecture FP_Add_Array_parallel_arch of FP_Add_Array is 

    constant C_LAYER_NUM : integer := integer(floor(log2(real(INPUT_SIZE))));
    signal s_mid_results : QFormat_Array(INPUT_SIZE - 2 downto 0)(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
    signal s_ready : std_logic_vector(C_LAYER_NUM downto 1);

    component FP_Add_Layer is
        generic (
            INTEGER_PART    : integer := 8;
            FRACTIONAL_PART : integer := 8;
            INPUT_SIZE      : integer := 16
        );
        port (
            i_clk   : in std_logic;
            i_rstn   : in std_logic;
            i_valid  : in std_logic;
            i_data     : in QFormat_Array(INPUT_SIZE - 1 downto 0)((INTEGER_PART + FRACTIONAL_PART - 1) downto 0);
            o_data     : out QFormat_Array((INPUT_SIZE / 2) - 1 downto 0)((INTEGER_PART + FRACTIONAL_PART - 1) downto 0);
            o_ready : out std_logic
        );
    end component FP_Add_Layer;

begin
    
    ARRAY_GEN: for i in C_LAYER_NUM downto 1 generate
        
        INPUT_LAYER: if (i = C_LAYER_NUM) generate 
            INPUT_LAYER_INSTANCE: FP_Add_Layer
            generic map(
                INTEGER_PART => INTEGER_PART,
                FRACTIONAL_PART => FRACTIONAL_PART,
                INPUT_SIZE => 2**i
            )
            port map(
                i_clk => i_clk,
                i_rstn => i_rstn,
                i_valid => i_valid,
                i_data => i_data,
                o_data => s_mid_results( (2**i - 2) downto (2**i - 2**(i-1) - 1) ),
                o_ready => s_ready(i)
            );
        end generate INPUT_LAYER;

        MIDDLE_LAYERS: if (i /= C_LAYER_NUM) generate
            MIDDLE_LAYER_INSTANCE: FP_Add_Layer
            generic map(
                INTEGER_PART => INTEGER_PART,
                FRACTIONAL_PART => FRACTIONAL_PART,
                INPUT_SIZE => 2**i
            )
            port map(
                i_clk => i_clk,
                i_rstn => i_rstn,
                i_valid => s_ready(i+1),
                i_data => s_mid_results( (2**(i+1) - 2) downto (2**(i+1) - 2**i - 1) ),
                o_data => s_mid_results( (2**i - 2) downto (2**i - 2**(i-1) - 1) ),
                o_ready => s_ready(i)
            );
        end generate MIDDLE_LAYERS;
        
     end generate ARRAY_GEN;

    o_ready <= s_ready(1);
    o_data <= s_mid_results(0);

end architecture FP_Add_Array_parallel_arch;