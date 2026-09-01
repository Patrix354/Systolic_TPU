library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.npu_types.all;
use work.npu_config.all;

entity npu_systolic_array_delay_wrapper is
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_en : in std_logic_vector(C_ARRAY_SIZE-1 downto 0);
        i_data : in QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH - 1 downto 0);
        o_data : out QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH - 1 downto 0);
        o_en : out std_logic_vector(C_ARRAY_SIZE-1 downto 0)
    );
end entity npu_systolic_array_delay_wrapper;

architecture npu_systolic_array_delay_wrapper_rtl of npu_systolic_array_delay_wrapper is
begin

    u_npu_delay : entity work.npu_systolic_array_delay
        port map (
            i_clk  => i_clk,
            i_rstn => i_rstn,
            i_en   => i_en,
            i_data => i_data,
            o_data => o_data,
            o_en   => o_en
        );

end architecture npu_systolic_array_delay_wrapper_rtl;