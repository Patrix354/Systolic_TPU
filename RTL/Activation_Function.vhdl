-------------------------------------------------------------------------------
-- Title      : Activation_Function (ReLU)
-- Project    : Neural Network Accelerator
-- File       : Activation_Function.vhdl
-- Author     : Laura Korycka
-- Description: 
--   This module implements a synchronous Rectified Linear Unit (ReLU) activation
--   function for signed fixed-point data. The ReLU operation sets all negative
--   input values to zero while passing non-negative values unchanged.
--   The computation is performed on the rising edge of the clock and is gated
--   by a valid input signal. When reset is active (i_rstn = '0'), the output
--   register is cleared.
--
-- Generics:
--   DATA_WIDTH - Bit width of the signed input and output data.
--
-- Ports:
--   i_clk   : Clock input; ReLU operation is evaluated on the rising edge.
--   i_rstn  : Active-low reset; clears the internal register and output.
--   i_data  : Signed input data.
--   i_valid : Data valid signal; enables computation when high.
--   o_data  : Signed output data after ReLU activation.
--
-- Notes:
--   The ReLU function is defined as:
--     ReLU(x) = max(0, x)
--   This implementation uses the most significant bit of the signed input
--   to detect negative values.
--
-- Revision history:
--   30-11-2025 : Initial version
-------------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Types.all; 

entity Activation_Function is
    generic (
        DATA_WIDTH : integer := 8
    );
    port (
        i_clk       : in  std_logic;
        i_rstn       : in  std_logic;
        i_data   : in  signed(DATA_WIDTH - 1 downto 0);
        i_valid  : in  std_logic;
        o_data  : out signed(DATA_WIDTH - 1 downto 0);
        o_ready : out std_logic
    );
end entity Activation_Function;

architecture ReLU of Activation_Function is
    signal s_data  : signed(DATA_WIDTH - 1 downto 0);
begin
    process(i_clk) begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                s_data <= (others => '0');
                o_ready <= '0';
            else
                if i_valid = '1' then
                    if i_data(DATA_WIDTH - 1) = '1' then
                        s_data <= (others => '0');
                        o_ready <= '1';
                    else
                        s_data <= i_data;
                        o_ready <= '1';
                    end if;
                else
                    o_ready <= '0';
                    s_data <= s_data;
                end if;
            end if;
        end if;
    end process;

    o_data <= s_data;

end architecture ReLU;