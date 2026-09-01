library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.npu_types.all;
use work.npu_config.all;

entity npu_delay_wrapper is
    port (
        i_clk  : in std_logic;
        i_rstn : in std_logic;

        i_en   : in std_logic;
        i_data : in QFormat(C_DATA_WIDTH - 1 downto 0);

        o_data : out QFormat(C_DATA_WIDTH - 1 downto 0);
        o_en   : out std_logic
    );
end entity npu_delay_wrapper;

architecture npu_delay_wrapper_rtl of npu_delay_wrapper is
begin

    u_npu_delay : entity work.npu_delay
        generic map (
            G_DELAY => C_PE_LATENCY
        )
        port map (
            i_clk  => i_clk,
            i_rstn => i_rstn,
            i_en   => i_en,
            i_data => i_data,
            o_data => o_data,
            o_en   => o_en
        );

end architecture npu_delay_wrapper_rtl;