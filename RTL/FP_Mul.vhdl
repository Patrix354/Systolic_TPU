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
--   i_valid : Data valid signal; enables computation when high.
--   o_y   : Output product in extended Q-format with doubled bit width:
--           QFormat(2*(INTEGER_PART+FRACTIONAL_PART)).
--   o_ready : Ready signal output.
--
-- Notes:
--   - The QFormat type is defined as a subtype of 'signed'.
--   - The result width is doubled to preserve full multiplication precision.
--   - No rounding or saturation is applied to the output.
--   - The result is purely registered and updated every clock cycle when
--     reset is deasserted.
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
        i_valid     : in std_logic;
        i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_ready : out std_logic;
        o_y     : out QFormat( 2 * (INTEGER_PART + FRACTIONAL_PART) - 1 downto 0)
    );
end entity;

architecture FP_Mul_arch of FP_Mul is
    signal s_active : std_logic; 
    signal s_a : QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
    signal s_b : QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
    signal s_y : QFormat( 2 * (INTEGER_PART + FRACTIONAL_PART) - 1 downto 0);
begin
    
    o_y <= s_y;

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                s_y <= (others => '0');
                o_ready <= '0';
                s_a <= (others => '0');
                s_b <= (others => '0');
                s_active <= '0';
            else
                if i_valid = '1' then
                    s_a <= i_a;
                    s_b <= i_b;
                    s_active <= '1';
                else
                    s_a <= s_a;
                    s_b <= s_b;
                    s_active <= '0';
                end if;

                if s_active = '1' then
                    s_y <= s_a * s_b;
                    o_ready <= '1';
                else
                    s_y <= s_y;
                    o_ready <= '0';
                end if;

            end if;
        end if;

    end process;

end architecture;

architecture FP_Mul_serial of FP_Mul is 
    constant C_INPUT_BIT_LEN : natural := INTEGER_PART + FRACTIONAL_PART;
    constant C_OUTPUT_BIT_LEN : natural := 2 * (INTEGER_PART + FRACTIONAL_PART);

    signal s_en_pipe : std_logic_vector(C_INPUT_BIT_LEN - 1 downto 0);
    signal s_a_pipe : QFormat_Array(C_INPUT_BIT_LEN - 1 downto 0)(C_OUTPUT_BIT_LEN - 1 downto 0);
    signal s_b_pipe : QFormat_Array(C_INPUT_BIT_LEN - 1 downto 0)(C_OUTPUT_BIT_LEN - 1 downto 0);
begin

  process(i_clk)
  begin
    if rising_edge(i_clk) then
      if (i_rstn = '0') then

      else
        gen_shifts : for i in C_INPUT_BIT_LEN-1 downto 1 generate
        begin   
            s_b_pipe(i) <= s_b_pipe(i-1);
        end generate gen_shifts;      
      end if;
    end if;
    


  end process;

  
end architecture FP_Mul_serial;