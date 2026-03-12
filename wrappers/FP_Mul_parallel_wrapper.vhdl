library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Types.all;

entity FP_Mul_parallel_wrap is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4
    );
    port (
        i_clk   : in std_logic;
        i_rstn  : in std_logic;
        i_valid : in std_logic;
        i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_y     : out QFormat(2 * (INTEGER_PART + FRACTIONAL_PART) - 1 downto 0);
        o_ready : out std_logic
    );
end entity FP_Mul_parallel_wrap;

architecture wrapper of FP_Mul_parallel_wrap is
begin

    dut : entity work.FP_Mul(FP_Mul_parallel)
        generic map (
            INTEGER_PART    => INTEGER_PART,
            FRACTIONAL_PART => FRACTIONAL_PART
        )
        port map (
            i_clk   => i_clk,
            i_rstn  => i_rstn,
            i_valid => i_valid,
            i_a     => i_a,
            i_b     => i_b,
            o_y     => o_y,
            o_ready => o_ready
        );

end architecture wrapper;