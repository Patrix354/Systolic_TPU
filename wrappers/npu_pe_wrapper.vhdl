library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.npu_types.all;
use work.npu_config.all;

entity npu_pe_wrapper is
    port (
        i_clk   : in std_logic;
        i_rstn  : in std_logic;
        i_en    : in std_logic;
        i_w_en  : in std_logic;

        i_w     : in QFormat(C_DATA_WIDTH - 1 downto 0);
        i_x     : in QFormat(C_DATA_WIDTH - 1 downto 0);
        i_y     : in QFormat(C_DATA_WIDTH - 1 downto 0);

        o_x     : out QFormat(C_DATA_WIDTH - 1 downto 0);
        o_y     : out QFormat(C_DATA_WIDTH - 1 downto 0);
        o_en    : out std_logic
    );
end entity npu_pe_wrapper;

architecture npu_pe_wrapper_rtl of npu_pe_wrapper is
begin

    u_npu_pe : entity work.npu_pe(npu_pe_rtl)
        port map (
            i_clk  => i_clk,
            i_rstn => i_rstn,
            i_en   => i_en,
            i_w_en => i_w_en,
            i_w    => i_w,
            i_x    => i_x,
            i_y    => i_y,
            o_x    => o_x,
            o_y    => o_y,
            o_en   => o_en
        );

end architecture npu_pe_wrapper_rtl;