library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.npu_types.all;
use work.npu_config.all;


entity npu_add_wrapper is
    port (
        i_clk   : in  std_logic;
        i_rstn  : in  std_logic;
        i_valid : in  std_logic;
        i_a     : in  QFormat(C_DATA_WIDTH - 1 downto 0);
        i_b     : in  QFormat(C_DATA_WIDTH - 1 downto 0);
        o_ready : out std_logic;
        o_y     : out QFormat(C_DATA_WIDTH - 1 downto 0)
    );
end entity npu_add_wrapper;


architecture npu_add_wrapper_rtl of npu_add_wrapper is
begin

    u_npu_add : entity work.npu_add(npu_add_rtl)
        port map (
            i_clk   => i_clk,
            i_rstn  => i_rstn,
            i_valid => i_valid,
            i_a     => i_a,
            i_b     => i_b,
            o_ready => o_ready,
            o_y     => o_y
        );

end architecture npu_add_wrapper_rtl;