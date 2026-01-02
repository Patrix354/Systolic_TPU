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
--   i_valid : Data valid signal; enables computation when high.
--   i_zero : Zero input qualifier; when '1' the extended input is replaced by
--            zero for the current accumulation (used to clear or mask input).
--   i_data : Input operand in input QFormat(IN_INTEGER_PART+IN_FRACTIONAL_PART).
--   o_data : Accumulated output in output QFormat(OUT_INTEGER_PART+OUT_FRACTIONAL_PART).
--   o_ready: Ready signal output
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
        i_valid  : in std_logic;
        i_zero : in std_logic;
        i_data : in QFormat((IN_INTEGER_PART+IN_FRACTIONAL_PART-1) downto 0);
        o_data : out QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
        o_ready : out std_logic
    );
end entity FP_Acc;

architecture FP_Acc_arch of FP_Acc is

    signal s_ext_data   : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0) := (others => '0');
    signal s_acc_data   : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0) := (others => '0');
    signal s_a      : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0) := (others => '0');
    signal s_b      : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0) := (others => '0');
    signal s_valid  : std_logic := '0';
    signal s_zero   : std_logic := '0';
    signal s_ext_ready : std_logic := '0';
    signal s_add_valid : std_logic := '0';

    component FP_Add is
        generic (
            INTEGER_PART    : integer := OUT_INTEGER_PART;
            FRACTIONAL_PART : integer := OUT_FRACTIONAL_PART
        );
        port (
            i_clk   : in std_logic;
            i_rstn   : in std_logic;
            i_valid : in std_logic;
            i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
            i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
            o_ready : out std_logic;
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
            i_clk : in std_logic;
            i_rstn : in std_logic;
            i_data : in QFormat((IN_INTEGER_PART+IN_FRACTIONAL_PART-1) downto 0);
            i_valid : in std_logic;
            o_data : out QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
            o_ready : out std_logic
        );
    end component;

begin

    s_valid <= i_valid when i_rstn = '1' else '0';
    s_zero <= i_zero when i_rstn = '1' else '0';
    o_data <= s_acc_data when i_rstn = '1' else (others => '0');
    s_a <= s_ext_data when s_zero = '0' else (others => '0');
    s_b <= s_acc_data when s_zero = '0' else (others => '0');
    s_add_valid <= s_ext_ready when s_zero = '0' else '1';



    process(i_clk) begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                s_acc_data <= (others => '0');
                o_ready <= '0';
            else
                if s_add_valid = '1' then
                    s_acc_data <= resize(s_a, OUT_INTEGER_PART + OUT_FRACTIONAL_PART) + resize(s_b, OUT_INTEGER_PART + OUT_FRACTIONAL_PART);    
                    o_ready <= '1';
                else
                    s_acc_data <= s_acc_data;    
                    o_ready <= '0';
                end if;
                
            end if;
        end if;

    end process;
    -- ACC_SUM_CELL: FP_Add
    --      generic map(
    --          INTEGER_PART => OUT_INTEGER_PART,
    --          FRACTIONAL_PART => OUT_FRACTIONAL_PART
    --      )
    --      port map(
    --          i_clk => i_clk,
    --          i_rstn => i_rstn,
    --          i_valid => s_add_valid,
    --          i_a => s_a,
    --          i_b => s_b,
    --          o_y => s_acc_data,
    --          o_ready => o_ready
    --      );

    SIGNED_EXT: FP_Extender 
        generic map(
            IN_INTEGER_PART    => IN_INTEGER_PART,
            IN_FRACTIONAL_PART => IN_FRACTIONAL_PART,
            OUT_INTEGER_PART    => OUT_INTEGER_PART,
            OUT_FRACTIONAL_PART => OUT_FRACTIONAL_PART
        )
        port map(
            i_clk => i_clk,
            i_rstn => i_rstn,
            i_valid => i_valid,
            i_data => i_data,
            o_data => s_ext_data,
            o_ready => s_ext_ready
        );

end architecture FP_Acc_arch;