library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Types.all;

entity FP_Add_Array_serial_wrap is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4;
        INPUT_SIZE      : integer := 16
    );
    port (
        i_clk   : in std_logic;
        i_rstn  : in std_logic;
        i_valid : in std_logic;
        i_data     : in  QFormat_Array(INPUT_SIZE-1 downto 0)(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_data     : out QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_ready : out std_logic
    );
end entity FP_Add_Array_serial_wrap;

architecture wrapper of FP_Add_Array_serial_wrap is
begin

    dut : entity work.FP_Add_Array(FP_Add_Array_serial_arch)
        generic map (
            INTEGER_PART    => INTEGER_PART,
            FRACTIONAL_PART => FRACTIONAL_PART,
            INPUT_SIZE      => INPUT_SIZE
        )
        port map (
            i_clk  => i_clk,
            i_rstn => i_rstn,
            i_valid => i_valid,
            i_data    => i_data,
            o_data    => o_data,
            o_ready => o_ready
        );

end architecture wrapper;
