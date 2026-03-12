-------------------------------------------------------------------------------
-- Title      : FP_Mul
-- Project    : MAC Cell / Neural Network Accelerator
-- File       : FP_Mul.vhdl
-- Author     : Laura Korycka
-- Description:
--   This module implements a signed fixed-point multiplier for Q-format
--   operands. The entity provides two alternative architectures:
--
--   1) FP_Mul_arch
--      A sequential, synchronous multiplier. Input operands are sampled
--      when i_valid is asserted, and the multiplication result is registered
--      on the rising edge of the clock. The output is cleared when the
--      active-low reset (i_rstn = '0') is asserted.
--
--   2) FP_Mul_parallel
--      A parallel/pipelined shift-add multiplier architecture intended to
--      perform multiplication over multiple internal stages. The result is
--      produced in extended fixed-point format, preserving full precision.
--
-- Generics:
--   INTEGER_PART    - Number of integer bits in the input Q-format.
--   FRACTIONAL_PART - Number of fractional bits in the input Q-format.
--
-- Ports:
--   i_clk   - Clock input.
--   i_rstn  - Active-low synchronous reset.
--   i_valid - Input data valid signal.
--   i_a     - First signed input operand in Q-format:
--             Q(INTEGER_PART, FRACTIONAL_PART).
--   i_b     - Second signed input operand in Q-format:
--             Q(INTEGER_PART, FRACTIONAL_PART).
--   o_ready - Output ready/valid indication.
--   o_y     - Multiplication result in extended signed Q-format with
--             doubled bit width:
--             Q(2*INTEGER_PART, 2*FRACTIONAL_PART), stored on
--             2*(INTEGER_PART + FRACTIONAL_PART) bits.
--
-- Notes:
--   - QFormat is defined in work.Types as a subtype of signed.
--   - The output width is doubled to preserve the full multiplication result.
--   - No rounding, truncation, or saturation is applied.
--   - The exact timing/latency depends on the selected architecture.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
--use ieee.std_logic_arith.all;
--use ieee.numeric_bit.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.math_complex.all;
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

architecture FP_Mul_default of FP_Mul is
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

architecture FP_Mul_parallel of FP_Mul is 
    constant C_INPUT_BIT_LEN : natural := INTEGER_PART + FRACTIONAL_PART;
    constant C_OUTPUT_BIT_LEN : natural := 2 * (INTEGER_PART + FRACTIONAL_PART);
    constant C_IN_FRACTIONAL_PART : natural := FRACTIONAL_PART;
    constant C_IN_INTEGER_PART : natural := INTEGER_PART;
    constant C_OUT_FRACTIONAL_PART : natural := 2 * FRACTIONAL_PART;
    constant C_OUT_INTEGER_PART : natural := 2 * INTEGER_PART;
    
    constant C_LEADING_ZEROS : std_logic_vector((C_OUTPUT_BIT_LEN - C_INPUT_BIT_LEN - 1) downto 0) := 
    (others => '0'); 
    constant C_LEADING_ONES : std_logic_vector((C_OUTPUT_BIT_LEN - C_INPUT_BIT_LEN - 1) downto 0) := 
    (others => '1'); 

    signal s_en_pipe : std_logic_vector(C_INPUT_BIT_LEN - 1 downto 0);
    signal s_neg_pipe : std_logic_vector(C_INPUT_BIT_LEN - 1 downto 0);
    signal s_a_pipe : QFormat_Array(C_INPUT_BIT_LEN - 1 downto 0)(C_INPUT_BIT_LEN - 1 downto 0);
    signal s_b_pipe : QFormat_Array(C_INPUT_BIT_LEN - 1 downto 0)(C_OUTPUT_BIT_LEN - 1 downto 0);
    signal s_y_pipe : QFormat_Array(C_INPUT_BIT_LEN - 1 downto 0)(C_OUTPUT_BIT_LEN - 1 downto 0);

begin

  process(i_clk)
  begin
    if rising_edge(i_clk) then
      if (i_rstn = '0') then

        for i in C_INPUT_BIT_LEN-1 downto 0 loop
            s_b_pipe(i) <= (others => '0');
            s_a_pipe(i) <= (others => '0');
            s_y_pipe(i) <= (others => '0');
        end loop;
        s_en_pipe <= (others => '0');
        s_neg_pipe <= (others => '0');
      else

        if(i_a(C_INPUT_BIT_LEN - 1) = '1') then
            s_a_pipe(0) <= (not i_a) + '1';
            s_neg_pipe(0) <= '1';
        else
            s_a_pipe(0) <= i_a;
            s_neg_pipe(0) <= '0';
        end if;
        
        s_b_pipe(0) <= QFormat(C_LEADING_ZEROS & std_logic_vector(i_b)) when 
                                    i_b(C_INPUT_BIT_LEN - 1)='0' else
                                    QFormat(C_LEADING_ONES & std_logic_vector(i_b));
        s_en_pipe(0) <= i_valid;

        s_y_pipe(0) <= (others => '0');
        

        for i in C_INPUT_BIT_LEN-1 downto 1 loop 
            s_b_pipe(i) <= s_b_pipe(i-1) sll 1;
            s_a_pipe(i) <= s_a_pipe(i-1) srl 1;
        end loop;
        
        for i in C_INPUT_BIT_LEN-1 downto 1 loop
            if(s_a_pipe(i-1)(0) = '1') then
                s_y_pipe(i) <= s_y_pipe(i-1) + s_b_pipe(i-1);
            else 
                s_y_pipe(i) <= s_y_pipe(i-1);
            end if;
        end loop;

        for i in C_INPUT_BIT_LEN-1 downto 1 loop
            s_en_pipe(i) <= s_en_pipe(i-1);
            s_neg_pipe(i) <= s_neg_pipe(i-1);
        end loop;

      end if;
    end if;

  end process;

    with s_neg_pipe(C_INPUT_BIT_LEN - 1) select o_y <=
    s_y_pipe(C_INPUT_BIT_LEN - 1) when '0',
    (not s_y_pipe(C_INPUT_BIT_LEN - 1)) + '1' when '1',
    (others => '0') when others; 

    -- o_y <= s_y_pipe(C_INPUT_BIT_LEN - 1);
    o_ready <= s_en_pipe(C_INPUT_BIT_LEN - 1);

end architecture FP_Mul_parallel;